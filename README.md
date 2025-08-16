# envspec

> Automatize o setup do seu ambiente de desenvolvimento com etapas declarativas, modulares e reversíveis.

Com envspec, você define etapas de configuração (como instalação de `git`, `node`, `docker` etc.) em um
arquivo `.ini` declarativo e legível.
Cada etapa pode ser aplicada, verificada, revertida e organizada com dependências
— similar ao conceito de `turbo.json`, mas voltado a ambientes.

---

## ⚙️ Funcionalidades

- ✅ Verificação idempotente via `check`
- 🔁 Reversão de etapas com `--revert`
- 🪝 Execução condicional via `--only-missing`
- ⛓️ Encadeamento de etapas com `dependsOn`
- 💻 Interface interativa
(via [`gum`](https://github.com/charmbracelet/gum), opcional)
- 🧪 Suporte multiplataforma (Linux, macOS, Git bash no Windows)

---

## 🧩 Formato do `requirements.ini`

O `.ini` define etapas com comandos que podem ser aplicados, revertidos
ou validados com `check`.

```ini
[git]
check = command -v git
apply[] = sudo apt-get update
apply[] = sudo apt-get install -y git
revert[] = sudo apt-get remove -y git

[node]
check = command -v node
dependsOn[] = git
apply[] = curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apply[] = sudo apt-get install -y nodejs
revert[] = sudo apt-get remove -y nodejs

[docker]
check = docker --version
dependsOn[] = git
apply[] = curl -fsSL https://get.docker.com | sh
apply[] = sudo usermod -aG docker "$USER"
revert[] = sudo apt-get remove -y docker-ce docker-ce-cli containerd.io
```

- **`check`**: comando para verificar se a etapa já está aplicada.
- **`apply[]`**: comandos para aplicar a etapa.
- **`revert[]`**: comandos para desfazer a etapa.
- **`dependsOn[]`**: executa outras etapas antes.

## 🛡️ Dicas e melhores práticas

1. Priorize um `check` confiável para evitar execução desnecessária.
2. Use `dependsOn[]` para encadear etapas lógicas.
3. Se uma etapa não permite reversão (`revert[]` vazia ou ausente),
ainda pode ser aplicada, mas reversão será ignorada.
4. Rodar com `--preview` é ideal antes de rodar em CI ou em ambiente sensível.

## 🚀 Argumentos da CLI

```bash
envspec [opções] <etapas>
```

| Opção            | Descrição                                                                   |
|------------------|-----------------------------------------------------------------------------|
| `--all`          | Executa todas as etapas definidas no arquivo `.ini`                         |
| `--only-missing` | Executa apenas etapas que ainda não estão aplicadas (`check` retorna erro)  |
| `--preview`      | Mostra os comandos antes de executá-los                                     |
| `--strict`       | Interrompe imediatamente ao encontrar uma falha                             |
| `--revert`       | Reverte etapas aplicadas anteriormente (quando `revert[]` estiver definido) |

## Instalação

Homebrew

- Fórmulas: [https://formulae.brew.sh/formula/envspec][brew-formulas]

[brew-formulas]: https://formulae.brew.sh/formula/envspec

Comando de instalação:

```bash
brew install envspec
```

## Uso

```bash
REQUIREMENTS_CONFIG=/caminho/para/requirements.ini envspec git
```

### 🧰 Como Usar no Projeto Principal

#### a) Clonando via Submódulo

No projeto principal:

```bash
git submodule add http://github.com/adriancmiranda/envspec scripts/tools/requirements
```

Ou, se preferir subtree:

```bash
git subtree add --prefix=scripts/tools/requirements http://github.com/adriancmiranda/envspec main --squash
```

#### b) Adicione um requirements.ini local

```bash
touch requirements.ini
```

E configure suas dependências por projeto lá.

### 🏃 Chamada no Projeto

Você pode criar um `Makefile` ou script wrapper para facilitar:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly
readonly REQUIREMENTS_DIR="$SCRIPT_DIR/requirements"

readonly \
  REQUIREMENTS_CONFIG="$SCRIPT_DIR/requirements.ini" \
  "$REQUIREMENTS_DIR/bin/requirements.sh" "$@"
```

> scripts/envsetup.sh

Torne executável com `chmod +x scripts/envsetup.sh`.

#### Uso no projeto

```bash
./scripts/envsetup.sh git
./scripts/envsetup.sh --all --only-missing
./scripts/envsetup.sh --revert docker
```
