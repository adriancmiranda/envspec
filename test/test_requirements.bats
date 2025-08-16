#!/usr/bin/env bats

# Helper para adicionar seções no arquivo .ini temporário
add_stage() {
	local section="$1"
	shift
	echo "[$section]" >>"$TMP_CONFIG"
	for line in "$@"; do
		echo "$line" >>"$TMP_CONFIG"
	done
	echo >>"$TMP_CONFIG" # linha em branco para separar
}

run_req() {
	run bash requirements "$@"
}

setup() {
	TMP_CONFIG="$(mktemp)"
	export REQUIREMENTS_CONFIG="$TMP_CONFIG"

	add_stage hello \
		"check=command -v echo" \
		"apply[]=echo Installing hello"

	add_stage fail \
		"check=command -v nao-existe" \
		"apply[]=exit 1"
}

teardown() {
	rm -f "$TMP_CONFIG"
}

@test "instala uma etapa com sucesso" {
	run_req hello

	if [ "$status" -ne 0 ]; then
		echo "Erro! Saída do comando:"
		echo "$output"
	fi

	[ "$status" -eq 0 ]
	[[ "$output" =~ "hello" ]]
	[[ "$output" =~ "✅" ]]
}

@test "retorna erro se etapa falhar em modo estrito" {
	run_req --strict fail

	if [ "$status" -ne 1 ]; then
		echo "Erro! Saída do comando:"
		echo "$output"
	fi

	[ "$status" -eq 1 ]
	[[ "$output" =~ "❌" ]]
}

@test "ignora erro se modo não estrito" {
	run_req fail

	if [ "$status" -ne 0 ]; then
		echo "Erro! Saída do comando:"
		echo "$output"
	fi

	[ "$status" -eq 0 ]
	[[ "$output" =~ "⚠️ Falha ignorada" ]]
}

@test "detecta dependências e instala em ordem" {
	add_stage world \
		"dependsOn=hello" \
		"check=command -v echo" \
		"apply[]=echo World"

	run_req world

	if [ "$status" -ne 0 ]; then
		echo "Erro! Saída do comando:"
		echo "$output"
	fi

	[ "$status" -eq 0 ]
	[[ "$output" =~ "hello" ]]
	[[ "$output" =~ "world" ]]
}

@test "executa comandos de desinstalação se etapa estiver presente" {
	add_stage removable \
		"check=command -v echo" \
		"revert[]=echo Removing removable"

	run_req --revert removable
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Removing removable" ]]
	[[ "$output" =~ "desinstalado com sucesso" ]]
}

@test "detecta etapa já desinstalada" {
	add_stage ghost \
		"check=false" \
		"revert[]=echo NUNCA DEVE SER EXECUTADO"

	run_req --revert ghost
	[ "$status" -eq 0 ]
	[[ "$output" =~ "já desinstalado" ]]
	[[ ! "$output" =~ "NUNCA DEVE SER EXECUTADO" ]]
}

@test "falha ao executar comando de desinstalação inválido" {
	add_stage bad_revert \
		"check=command -v echo" \
		"revert[]=exit 1"

	run_req --revert bad_revert
	[ "$status" -eq 1 ]
	[[ "$output" =~ "Falha ao desinstalar" ]]
}

@test "--only-missing instala apenas etapas faltantes" {
	add_stage already_installed \
		"check=command -v echo" \
		"apply[]=echo Installing already_installed"

	run_req --only-missing already_installed
	[ "$status" -eq 0 ]
	[[ "$output" =~ "já está instalado" ]]
	[[ ! "$output" =~ "Installing already_installed" ]]
}

@test "executa todas as etapas com --all no modo padrão (não estrito)" {
	add_stage step1 \
		"check=false" \
		"apply[]=echo ok1"

	add_stage step2 \
		"check=false" \
		"apply[]=exit 1"

	run_req --all
	[ "$status" -eq 0 ]
	[[ "$output" =~ "ok1" ]]
	[[ "$output" =~ "⚠️ Falha ignorada" ]]
}

@test "executa todas as etapas com --all em modo estrito" {
	add_stage step3 \
		"check=false" \
		"apply[]=echo ok3"

	add_stage step4 \
		"check=false" \
		"apply[]=exit 1"

	run_req --strict --all
	[ "$status" -eq 1 ]
	[[ "$output" =~ "ok3" ]]
	[[ "$output" =~ "❌" ]]
}

@test "executa múltiplos comandos de instalação em ordem" {
	add_stage multi \
		"check=false" \
		"apply[]=echo One" \
		"apply[]=echo Two"

	run_req multi
	[ "$status" -eq 0 ]
	[[ "$output" =~ "One" ]]
	[[ "$output" =~ "Two" ]]
}

@test "executa dependências encadeadas em ordem" {
	add_stage A \
		"check=command -v comando-inexistente-a" \
		"apply[]=echo Instala A"

	add_stage B \
		"dependsOn=A" \
		"check=command -v comando-inexistente-b" \
		"apply[]=echo Instala B"

	add_stage C \
		"dependsOn=B" \
		"check=command -v comando-inexistente-c" \
		"apply[]=echo Instala C"

	run_req C

	[ "$status" -eq 0 ]
	[[ "$output" =~ "Instala A" ]]
	[[ "$output" =~ "Instala B" ]]
	[[ "$output" =~ "Instala C" ]]
}

@test "detecta ciclo de dependência e falha" {
	add_stage a \
		"dependsOn=b" \
		"check=false" \
		"apply[]=echo A"

	add_stage b \
		"dependsOn=a" \
		"check=false" \
		"apply[]=echo B"

	run_req a
	[ "$status" -eq 1 ]
	[[ "$output" =~ "ciclo de dependência" ]] || [[ "$output" =~ "dependência cíclica" ]]
}

@test "falha ao instalar etapa com dependência inexistente" {
	add_stage "stage_with_missing_dep" "dependsOn=nonexistent" "check=false" "apply[]=echo Installing"

	run_req stage_with_missing_dep

	[ "$status" -eq 1 ]
	[[ "$output" =~ "dependência" ]]
}

@test "falha ou pula etapa sem comandos de instalação" {
	add_stage "empty_install" "check=false"

	run_req empty_install

	# Aceita qualquer saída
	[ -n "$output" ]

	# Aceita status 0 ou 1
	[ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "detecta ambiente Git Bash no Windows" {
	run bash -c 'uname -s && uname -o'
	[ "$status" -eq 0 ]
	[[ "$output" =~ "MINGW" ]] || [[ "$output" =~ "MSYS" ]] || skip "Não é Git Bash no Windows"
}

@test "comando echo funciona no Git Bash e Unix" {
	run bash -c 'echo HelloWorld'
	[ "$status" -eq 0 ]
	[[ "$output" == "HelloWorld" ]]
}

@test "comando inexistente falha corretamente em qualquer OS" {
	run bash -c 'command -v comando_que_nao_existe'
	[ "$status" -ne 0 ]
}

@test "instala em ambiente MINGW (Git Bash)" {
	case "$(uname -s)" in
	MINGW* | MSYS*)
		add_stage windows_test \
			"check=command -v echo" \
			"apply[]=echo Instalando no Windows"

		run_req windows_test
		[ "$status" -eq 0 ]
		[[ "$output" =~ "Instalando no Windows" ]]
		;;
	*)
		skip "Não é Git Bash no Windows"
		;;
	esac
}

@test "múltiplos comandos em Git Bash" {
	case "$(uname -s)" in
	MINGW* | MSYS*)
		add_stage multi_windows \
			"check=false" \
			"apply[]=echo Linha1" \
			"apply[]=echo Linha2"

		run_req multi_windows
		[ "$status" -eq 0 ]
		[[ "$output" =~ "Linha1" ]]
		[[ "$output" =~ "Linha2" ]]
		;;
	*)
		skip "Não é Git Bash no Windows"
		;;
	esac
}
