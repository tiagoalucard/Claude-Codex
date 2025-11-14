# Suporte Multi-OS para install.sh

**Data:** 13 de Novembro de 2025
**Status:** ✅ Implementado

## Sistemas Operacionais Suportados

O script `install.sh` agora suporta oficialmente os seguintes sistemas:

- ✅ **Linux** (Ubuntu, Debian, Fedora, Arch, etc.)
- ✅ **WSL** (Windows Subsystem for Linux)
- ✅ **macOS** (com Homebrew)
- ✅ **Windows** (Git Bash/MSYS) - Com instalação automática via winget/chocolatey

## Detecção Automática de Sistema

### Função `is_wsl()`

Detecta automaticamente se o script está rodando no WSL através de:

1. Verificação do `/proc/version` por palavras-chave "Microsoft" ou "WSL"
2. Verificação da existência de `/proc/sys/fs/binfmt_misc/WSLInterop`

```bash
is_wsl() {
    if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
        return 0
    elif [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        return 0
    else
        return 1
    fi
}
```

### Função `detect_os()`

Retorna o sistema operacional detectado:

- `macos` - macOS
- `linux` - Linux nativo
- `wsl` - Windows Subsystem for Linux
- `windows` - Git Bash/MSYS/Cygwin
- `unknown` - Sistema desconhecido

## Compatibilidade de Comandos

### Comando `sed -i`

O comportamento de `sed -i` difere entre sistemas:

- **macOS**: Requer `sed -i '' "padrão" arquivo`
- **Linux/WSL**: Usa `sed -i "padrão" arquivo`

**Solução implementada:**

```bash
sed_inplace() {
    local pattern=$1
    local file=$2
    local os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        sed -i '' "$pattern" "$file"
    else
        sed -i "$pattern" "$file"
    fi
}
```

Todos os usos de `sed -i` no script foram substituídos por `sed_inplace()`.

## Caminhos de Configuração

### Linux Nativo

```bash
$HOME/.config/claude/claude_desktop_config.json
```

### WSL (Windows Subsystem for Linux)

O script tenta localizar a configuração do Claude em ordem de prioridade:

1. **Primeiro**: Diretório Linux (`$HOME/.config/claude`)
2. **Segundo**: Diretório Windows via WSL (`$APPDATA/Claude`)
3. **Fallback**: Cria em `$HOME/.config/claude`

```bash
"wsl")
    # No WSL, primeiro tentar o diretório Linux
    if [ -d "$HOME/.config/claude" ]; then
        echo "$HOME/.config/claude"
    # Se não existir, tentar o diretório Windows via /mnt/c
    elif [ -n "$USERPROFILE" ]; then
        local win_appdata=$(wslpath "$APPDATA" 2>/dev/null || echo "")
        if [ -n "$win_appdata" ]; then
            echo "$win_appdata/Claude"
        else
            echo "$HOME/.config/claude"
        fi
    else
        echo "$HOME/.config/claude"
    fi
    ;;
```

### macOS

```bash
$HOME/Library/Application Support/Claude/claude_desktop_config.json
```

## Instalação de Dependências

### Linux e WSL

Ambos usam os mesmos gerenciadores de pacotes:

- **apt-get** (Ubuntu, Debian, WSL Ubuntu)
- **yum** (CentOS, RHEL)
- **dnf** (Fedora)
- **pacman** (Arch, Manjaro)

```bash
"linux"|"wsl")
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y nodejs npm
    elif command_exists yum; then
        sudo yum install -y nodejs npm
    # ... outros gerenciadores
    fi
    ;;
```

### macOS

Usa Homebrew para instalação de pacotes:

```bash
"macos")
    if command_exists brew; then
        brew install node
    else
        print_error "Homebrew não encontrado"
        exit 1
    fi
    ;;
```

## Testando no WSL

### Verificar Detecção

```bash
# Ver informação do sistema
cat /proc/version

# Deve mostrar algo como:
# Linux version 6.6.87.2-microsoft-standard-WSL2 ...

# Testar detecção do script
bash -c 'source install.sh && detect_os'
# Saída esperada: wsl
```

### Executar Instalação no WSL

```bash
# Dar permissão de execução
chmod +x install.sh

# Executar
./install.sh

# Saída esperada:
# ================================
#   Assistente de Instalação Claude Code + Codex
# ================================
# [INFO] Sistema detectado: wsl
# [INFO] Executando no Windows Subsystem for Linux (WSL)
# ...
```

## Testando no Linux

```bash
# Testar detecção
bash -c 'source install.sh && detect_os'
# Saída esperada: linux

# Executar instalação
./install.sh
```

## Diferenças entre WSL e Linux Nativo

### WSL

- ✅ Acesso a filesystem do Windows via `/mnt/c/`, `/mnt/d/`, etc.
- ✅ Pode usar ferramentas Windows e Linux simultaneamente
- ✅ `wslpath` disponível para converter caminhos Windows ↔ Linux
- ⚠️ Variáveis de ambiente Windows acessíveis (`$USERPROFILE`, `$APPDATA`)
- ⚠️ Performance de I/O pode ser menor em `/mnt/c/`

### Linux Nativo

- ✅ Performance máxima de I/O
- ✅ Não tem acesso ao filesystem Windows
- ❌ Variáveis Windows não existem
- ❌ `wslpath` não disponível

## Variáveis de Ambiente Expandidas

O script expande automaticamente `$HOME` durante a instalação:

**Template (antes):**
```json
"command": "$HOME/.local/bin/uvx"
```

**Configuração final (depois):**
```json
"command": "/home/tiago/.local/bin/uvx"
```

Isso garante que os caminhos funcionem corretamente mesmo quando variáveis de ambiente não são expandidas pelo Claude Desktop.

## Solução de Problemas

### Problema: Script não detecta WSL

**Sintoma:**
```bash
./install.sh
# Mostra: Sistema detectado: linux
```

**Solução:**
```bash
# Verificar se está realmente no WSL
cat /proc/version | grep -i microsoft

# Se não mostrar nada, você está em Linux nativo
# Se mostrar "Microsoft", verifique a função is_wsl()
```

### Problema: Claude Desktop não encontrado no WSL

**Causa:** Claude Desktop instalado no Windows, não no Linux

**Solução:**
```bash
# Verificar onde está o Claude Desktop
ls "$HOME/.config/claude" 2>/dev/null || echo "Não existe no Linux"
ls "/mnt/c/Users/$USER/AppData/Roaming/Claude" 2>/dev/null || echo "Não existe no Windows"

# O script tentará ambos os locais automaticamente
```

### Problema: sed -i não funciona no macOS

**Erro:**
```bash
sed: -i: No such file or directory
```

**Solução:** O script já usa `sed_inplace()` que corrige isso automaticamente

### Problema: Permissão negada ao instalar pacotes

**Erro:**
```bash
E: Could not open lock file /var/lib/dpkg/lock-frontend
```

**Solução:**
```bash
# O script usa sudo automaticamente para apt-get
# Se não funcionar, execute:
sudo ./install.sh
```

## Comandos Úteis

### Verificar Sistema Operacional

```bash
# Ver OSTYPE
echo $OSTYPE

# Ver se é WSL
cat /proc/version

# Testar detecção do script
bash -c 'source install.sh && detect_os'
```

### Converter Caminhos no WSL

```bash
# Windows → WSL
wslpath "C:\Users\tiago\AppData\Roaming\Claude"
# Saída: /mnt/c/Users/tiago/AppData/Roaming/Claude

# WSL → Windows
wslpath -w /home/tiago/.config/claude
# Saída: \\wsl.localhost\Ubuntu\home\tiago\.config\claude
```

### Verificar Instalação

```bash
# Verificar Node.js
node -v
npm -v

# Verificar Python
python3 --version
pip3 --version

# Verificar uvx
which uvx
uvx --version

# Verificar Claude Code
claude --version
```

## Instalação Automática no Windows via PowerShell

### Gerenciadores de Pacotes Suportados

O script agora detecta e usa automaticamente gerenciadores de pacotes no Windows:

#### 1. **winget** (Windows Package Manager)

Vem instalado por padrão no **Windows 10 (versão 1809+)** e **Windows 11**.

**Verificar se está instalado:**
```powershell
winget --version
```

**O que o script instala via winget:**
- Node.js: `OpenJS.NodeJS`
- Python: `Python.Python.3.12`

#### 2. **Chocolatey**

Gerenciador de pacotes popular para Windows.

**Instalar Chocolatey:**
```powershell
# Abra PowerShell como Administrador e execute:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**O que o script instala via chocolatey:**
- Node.js: `nodejs`
- Python: `python`

### Ordem de Prioridade no Windows

Quando o script detecta que está rodando no Windows (Git Bash/MSYS), ele tenta instalar dependências na seguinte ordem:

1. **✅ winget** (mais rápido, vem pré-instalado)
2. **⚠️ chocolatey** (fallback se winget não funcionar)
3. **❌ Manual** (instruções se nenhum gerenciador estiver disponível)

### Fluxo de Instalação no Windows

```bash
$ ./install.sh

[INFO] Sistema detectado: windows
[INFO] Verificando dependências do sistema...

# Se Node.js não estiver instalado:
[INFO] Detectado Windows - tentando instalação automática...
[INFO] winget detectado ✓
[INFO] Instalando via winget: OpenJS.NodeJS
[INFO] Node.js instalado com sucesso via winget ✓
[AVISO] IMPORTANTE: Feche e reabra o terminal para o Node.js estar disponível

# Repetir para Python...
[INFO] Instalando via winget: Python.Python.3.12
[INFO] Python instalado com sucesso via winget ✓
[AVISO] IMPORTANTE: Feche e reabra o terminal para o Python estar disponível
```

### Tabela de Compatibilidade Completa

| Sistema | Status | Gerenciadores | Instalação Automática |
|---------|--------|---------------|-----------------------|
| Linux | ✅ Total | apt-get, yum, dnf, pacman | ✅ Sim |
| WSL | ✅ Total | apt-get, yum, dnf, pacman | ✅ Sim |
| macOS | ✅ Total | homebrew | ✅ Sim |
| Windows | ✅ Total | winget, chocolatey | ✅ Sim |

### Comandos PowerShell Usados

O script executa PowerShell a partir do Git Bash para:

**Verificar winget:**
```bash
powershell.exe -Command "Get-Command winget -ErrorAction SilentlyContinue"
```

**Instalar via winget:**
```bash
powershell.exe -Command "winget install --id OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements"
```

**Instalar via chocolatey (com admin):**
```bash
powershell.exe -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"choco install nodejs -y\"' -Wait"
```

## Referências

- **WSL Documentation:** https://docs.microsoft.com/windows/wsl/
- **WSL Path Conversion:** https://docs.microsoft.com/windows/wsl/filesystems
- **winget Documentation:** https://docs.microsoft.com/windows/package-manager/
- **Chocolatey:** https://chocolatey.org/
- **Bash Scripting Guide:** https://www.gnu.org/software/bash/manual/
- **sed Manual:** https://www.gnu.org/software/sed/manual/

---

**Última atualização:** 13 de Novembro de 2025
