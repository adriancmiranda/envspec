#!/usr/bin/env bash
set -euo pipefail

EXPECTED_VERSION="0.0.1"

if ! command -v envspec &>/dev/null; then
	echo "❌ Comando 'envspec' não encontrado no PATH."
	exit 1
fi

echo "✅ Comando 'envspec' encontrado."

ENVSPEC_PATH="$(command -v envspec)"
echo "Localização do envspec: $ENVSPEC_PATH"

type envspec

if [[ "$ENVSPEC_PATH" == *"homebrew"* ]]; then
	echo "⚠️ Detectado comando instalado via Homebrew."
elif [[ "$ENVSPEC_PATH" == *"/usr/local/bin"* ]]; then
	echo "⚠️ Detectado comando instalado via pacote .pkg."
else
	echo "⚠️ Origem do comando envspec não identificada."
fi

echo
echo "⏳ Testando execução de 'envspec --help'..."
OUTPUT=""
if ! OUTPUT="$(envspec --help 2>&1)"; then
	echo "❌ Falha ao executar 'envspec --help'."
	echo "📄 Saída:"
	echo "$OUTPUT"
	echo

	if echo "$OUTPUT" | grep -q "Arquivo de configuração"; then
		echo "💡 Dica: o envspec pode estar esperando um arquivo 'requirements.ini'."
		echo "→ Você pode definir REQUIREMENTS_CONFIG ou criar o arquivo esperado."
	fi

	exit 1
else
	echo "✅ Execução de 'envspec --help' concluída com sucesso."
	echo "$OUTPUT"
fi

echo
echo "⏳ Verificando versão esperada ($EXPECTED_VERSION)..."
VERSION_OUTPUT="$(envspec --version 2>&1 || true)"
echo "Versão reportada: $VERSION_OUTPUT"

if [[ "$VERSION_OUTPUT" == *"$EXPECTED_VERSION"* ]]; then
	echo "✅ Versão está correta."
else
	echo "⚠️ Versão não bate com a esperada: $EXPECTED_VERSION"
fi
