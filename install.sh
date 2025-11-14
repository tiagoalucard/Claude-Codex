#!/bin/bash

# Script de instalação automática do Claude Code + Codex
# Suporta macOS, Linux, Windows (Git Bash)

# Não usar set -e para permitir que algumas falhas sejam tratadas com ||
# set -e

# Definições de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Assistente de Instalação Claude Code + Codex  ${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Detectar se está rodando no WSL
is_wsl() {
    if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
        return 0
    elif [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        return 0
    else
        return 1
    fi
}

# Detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if is_wsl; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função sed compatível multi-OS
# No macOS, sed -i precisa de '', no Linux não
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

# Verificar se winget está disponível (Windows)
has_winget() {
    powershell.exe -Command "Get-Command winget -ErrorAction SilentlyContinue" >/dev/null 2>&1
}

# Verificar se chocolatey está disponível (Windows)
has_chocolatey() {
    powershell.exe -Command "Get-Command choco -ErrorAction SilentlyContinue" >/dev/null 2>&1
}

# Executar comando PowerShell com elevação (admin)
run_powershell_admin() {
    local command=$1
    print_warning "Esta operação requer privilégios de administrador"
    print_message "Uma janela de UAC pode aparecer - clique em 'Sim' para continuar"

    powershell.exe -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$command\"' -Wait" 2>/dev/null
    return $?
}

# Instalar pacote via winget
install_via_winget() {
    local package_id=$1
    print_message "Instalando via winget: $package_id"

    # winget pode precisar de interação, então rodamos normalmente
    powershell.exe -Command "winget install --id $package_id --silent --accept-package-agreements --accept-source-agreements" 2>/dev/null
    return $?
}

# Instalar pacote via chocolatey
install_via_chocolatey() {
    local package_name=$1
    print_message "Instalando via chocolatey: $package_name"

    # Chocolatey precisa de privilégios de admin
    run_powershell_admin "choco install $package_name -y"
    return $?
}

# Verificar versão do Node.js
check_node_version() {
    if ! command_exists node; then
        return 1
    fi

    local node_version=$(node -v | sed 's/v//' | cut -d'.' -f1)
    if [ "$node_version" -lt 20 ]; then
        return 1
    fi
    return 0
}

# Instalar pacote npm com tratamento de permissões
npm_install_global() {
    local package=$1

    # Tentar instalar sem sudo primeiro
    if npm install -g "$package" 2>/dev/null; then
        return 0
    fi

    # Se falhou, tentar com sudo
    print_warning "Permissões insuficientes, tentando com sudo..."
    if sudo npm install -g "$package"; then
        return 0
    fi

    return 1
}

# Instalar Node.js
install_nodejs() {
    local os=$(detect_os)
    print_message "Instalando Node.js..."

    case $os in
        "macos")
            if command_exists brew; then
                brew install node
            else
                print_error "Homebrew não encontrado. Instale Node.js manualmente de: https://nodejs.org/"
                exit 1
            fi
            ;;
        "linux"|"wsl")
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y nodejs npm
            elif command_exists yum; then
                sudo yum install -y nodejs npm
            elif command_exists dnf; then
                sudo dnf install -y nodejs npm
            elif command_exists pacman; then
                sudo pacman -S --noconfirm nodejs npm
            else
                print_error "Gerenciador de pacotes não suportado. Instale Node.js manualmente de: https://nodejs.org/"
                exit 1
            fi
            ;;
        "windows")
            print_message "Detectado Windows - tentando instalação automática..."

            # Tentar winget primeiro (mais comum no Windows 10/11)
            if has_winget; then
                print_message "winget detectado ✓"
                if install_via_winget "OpenJS.NodeJS"; then
                    print_message "Node.js instalado com sucesso via winget ✓"
                    print_warning "IMPORTANTE: Feche e reabra o terminal para o Node.js estar disponível"
                    return 0
                else
                    print_warning "Falha ao instalar via winget, tentando chocolatey..."
                fi
            fi

            # Tentar chocolatey como fallback
            if has_chocolatey; then
                print_message "chocolatey detectado ✓"
                if install_via_chocolatey "nodejs"; then
                    print_message "Node.js instalado com sucesso via chocolatey ✓"
                    print_warning "IMPORTANTE: Feche e reabra o terminal para o Node.js estar disponível"
                    return 0
                fi
            fi

            # Se nenhum gerenciador está disponível, instrução manual
            print_error "Nenhum gerenciador de pacotes encontrado (winget/chocolatey)"
            echo ""
            print_message "Opção 1 - Instalar manualmente:"
            echo "  1. Baixe Node.js de: https://nodejs.org/"
            echo "  2. Execute o instalador"
            echo "  3. Reinicie o terminal"
            echo "  4. Execute este script novamente"
            echo ""
            print_message "Opção 2 - Instalar Chocolatey (gerenciador de pacotes):"
            echo "  1. Abra PowerShell como Administrador"
            echo "  2. Execute: Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            echo "  3. Depois execute este script novamente"
            echo ""
            exit 1
            ;;
    esac
}

# Instalar Python
install_python() {
    local os=$(detect_os)
    print_message "Instalando Python 3..."

    case $os in
        "macos")
            if command_exists brew; then
                brew install python3
            else
                print_error "Homebrew não encontrado. Instale Python manualmente de: https://www.python.org/"
                exit 1
            fi
            ;;
        "linux"|"wsl")
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip
            elif command_exists yum; then
                sudo yum install -y python3 python3-pip
            elif command_exists dnf; then
                sudo dnf install -y python3 python3-pip
            elif command_exists pacman; then
                sudo pacman -S --noconfirm python python-pip
            else
                print_error "Gerenciador de pacotes não suportado. Instale Python manualmente de: https://www.python.org/"
                exit 1
            fi
            ;;
        "windows")
            print_message "Detectado Windows - tentando instalação automática..."

            # Tentar winget primeiro (mais comum no Windows 10/11)
            if has_winget; then
                print_message "winget detectado ✓"
                if install_via_winget "Python.Python.3.12"; then
                    print_message "Python instalado com sucesso via winget ✓"
                    print_warning "IMPORTANTE: Feche e reabra o terminal para o Python estar disponível"
                    return 0
                else
                    print_warning "Falha ao instalar via winget, tentando chocolatey..."
                fi
            fi

            # Tentar chocolatey como fallback
            if has_chocolatey; then
                print_message "chocolatey detectado ✓"
                if install_via_chocolatey "python"; then
                    print_message "Python instalado com sucesso via chocolatey ✓"
                    print_warning "IMPORTANTE: Feche e reabra o terminal para o Python estar disponível"
                    return 0
                fi
            fi

            # Se nenhum gerenciador está disponível, instrução manual
            print_error "Nenhum gerenciador de pacotes encontrado (winget/chocolatey)"
            echo ""
            print_message "Opção 1 - Instalar manualmente:"
            echo "  1. Baixe Python de: https://www.python.org/"
            echo "  2. Execute o instalador (marque 'Add Python to PATH')"
            echo "  3. Reinicie o terminal"
            echo "  4. Execute este script novamente"
            echo ""
            print_message "Opção 2 - Instalar Chocolatey (gerenciador de pacotes):"
            echo "  1. Abra PowerShell como Administrador"
            echo "  2. Execute: Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            echo "  3. Depois execute este script novamente"
            echo ""
            exit 1
            ;;
    esac
}

# Verificar dependências
check_dependencies() {
    print_message "Verificando dependências do sistema..."

    local missing_deps=()
    local warnings=()

    # Verificar Node.js
    if ! command_exists node; then
        missing_deps+=("Node.js")
    elif ! check_node_version; then
        warnings+=("Node.js v20+ recomendado (atual: $(node -v))")
    fi

    # Verificar npm
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi

    # Verificar Python
    if ! command_exists python3; then
        missing_deps+=("Python 3")
    fi

    # Verificar pip ou pipx
    if ! command_exists pipx && ! command_exists pip && ! command_exists pip3; then
        missing_deps+=("pipx ou pip")
    fi

    # Mostrar avisos
    for warning in "${warnings[@]}"; do
        print_warning "$warning"
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_warning "Faltam as seguintes dependências: ${missing_deps[*]}"
        echo ""

        # Perguntar se deseja instalar automaticamente
        read -p "Deseja instalar as dependências automaticamente? (y/N): " auto_install

        if [[ "$auto_install" =~ ^[Yy]$ ]]; then
            # Instalar Node.js e npm se necessário
            if ! command_exists node || ! command_exists npm; then
                install_nodejs
            fi

            # Instalar Python e pip se necessário
            if ! command_exists python3 || { ! command_exists pipx && ! command_exists pip && ! command_exists pip3; }; then
                install_python
            fi

            # Verificar novamente
            if ! command_exists node || ! command_exists npm || ! command_exists python3; then
                print_error "Algumas dependências ainda estão faltando após a instalação"
                exit 1
            fi

            print_message "Todas as dependências instaladas com sucesso ✓"
        else
            print_error "Instalação cancelada. Por favor, instale as dependências manualmente:"
            echo ""
            echo "  Node.js v20+: https://nodejs.org/"
            echo "  Python: https://www.python.org/"
            exit 1
        fi
    else
        print_message "Todas as dependências verificadas ✓"
    fi
}

# Obter diretório de configuração do Claude
get_claude_config_dir() {
    local os=$(detect_os)
    case $os in
        "macos")
            echo "$HOME/Library/Application Support/Claude"
            ;;
        "linux")
            echo "$HOME/.config/claude"
            ;;
        "wsl")
            # No WSL, primeiro tentar o diretório Linux
            if [ -d "$HOME/.config/claude" ]; then
                echo "$HOME/.config/claude"
            # Se não existir, tentar o diretório Windows via /mnt/c
            elif [ -n "$USERPROFILE" ]; then
                # Converter caminho Windows para WSL
                local win_appdata=$(wslpath "$APPDATA" 2>/dev/null || echo "")
                if [ -n "$win_appdata" ]; then
                    echo "$win_appdata/Claude"
                else
                    # Fallback: usar diretório Linux
                    echo "$HOME/.config/claude"
                fi
            else
                # Fallback padrão
                echo "$HOME/.config/claude"
            fi
            ;;
        "windows")
            echo "$APPDATA/Claude"
            ;;
        *)
            print_error "Sistema operacional não suportado: $os"
            exit 1
            ;;
    esac
}

# Criar diretório de configuração
create_config_dir() {
    local config_dir=$(get_claude_config_dir)

    if [ ! -d "$config_dir" ]; then
        print_message "Criando diretório de configuração do Claude: $config_dir"
        mkdir -p "$config_dir"
    fi

    echo "$config_dir"
}

# Escolher template de configuração
choose_config() {
    echo "" >&2
    print_message "Por favor, escolha o template de configuração:" >&2
    echo "1) Configuração Simples (Recomendado para iniciantes)" >&2
    echo "   - Sequential-thinking, Codex" >&2
    echo "" >&2
    echo "2) Configuração Padrão (Recomendado para uso diário)" >&2
    echo "   - Sequential-thinking, Shrimp Tasks, Codex, Code Index" >&2
    echo "" >&2
    echo "3) Configuração Avançada (Para usuários experientes)" >&2
    echo "   - Padrão + Chrome DevTools, Exa Search" >&2
    echo "" >&2

    while true; do
        read -p "Por favor, insira sua escolha (1-3): " choice
        case $choice in
            1)
                echo "config-simple.json|simple"
                break
                ;;
            2)
                echo "claude-desktop-config.json|standard"
                break
                ;;
            3)
                echo "config-advanced.json|advanced"
                break
                ;;
            *)
                print_warning "Por favor, insira uma escolha válida (1-3)" >&2
                ;;
        esac
    done
}

# Gerar arquivo de configuração
generate_config() {
    local template_file=$1
    local openai_api_key=$2
    local exa_api_key=$3
    local output_file=$4

    # Verificar se o arquivo de template existe
    if [ ! -f "$template_file" ]; then
        print_error "Arquivo de template não encontrado: $template_file"
        exit 1
    fi

    print_message "Gerando arquivo de configuração: $output_file"

    # Copiar template para arquivo temporário
    local temp_file=$(mktemp)
    cp "$template_file" "$temp_file"

    # Substituir chave API OpenAI se fornecida
    if [ -n "$openai_api_key" ]; then
        sed_inplace "s/your-openai-api-key-here/$openai_api_key/g" "$temp_file"
        print_message "Chave API OpenAI configurada ✓"
    fi

    # Substituir chave API Exa se fornecida
    if [ -n "$exa_api_key" ]; then
        sed_inplace "s/your-exa-api-key-here/$exa_api_key/g" "$temp_file"
        print_message "Chave API Exa configurada ✓"
    fi

    # Expandir variável $HOME no caminho do uvx
    # Se o arquivo contém $HOME, expande para o valor real
    if grep -q "\$HOME" "$temp_file"; then
        # Escapar o HOME para sed (substituir / por \/)
        local escaped_home=$(echo "$HOME" | sed 's/\//\\\//g')
        sed_inplace "s/\\\$HOME/$escaped_home/g" "$temp_file"
        print_message "Variável \$HOME expandida: $HOME ✓"
    fi

    # Se ainda usa "uvx" genérico, substituir pelo caminho detectado
    if grep -q "\"command\": \"uvx\"" "$temp_file"; then
        local uvx_path=$(command -v uvx || echo "$HOME/.local/bin/uvx")
        if [ -x "$uvx_path" ]; then
            local escaped_path=$(echo "$uvx_path" | sed 's/\//\\\//g')
            sed_inplace "s/\"command\": \"uvx\"/\"command\": \"$escaped_path\"/g" "$temp_file"
            print_message "Caminho uvx configurado: $uvx_path ✓"
        fi
    fi

    # Mover arquivo temporário para destino final
    mv "$temp_file" "$output_file"

    # Se nenhuma chave foi configurada, avisar
    if [ -z "$openai_api_key" ] && [ -z "$exa_api_key" ]; then
        print_message "Configuração copiada (chaves API podem ser adicionadas depois)"
    fi

    print_message "Arquivo de configuração gerado ✓"
}

# Instalar pacotes de acordo com o nível de configuração
install_packages_by_config() {
    local config_level=$1
    print_message "Instalando pacotes para configuração $config_level..."

    case $config_level in
        "simple")
            install_basic_packages
            ;;
        "standard")
            install_standard_packages
            ;;
        "advanced")
            install_all_packages
            ;;
        *)
            print_error "Nível de configuração desconhecido: $config_level"
            return 1
            ;;
    esac
}

# Instalar pacotes básicos (configuração simples)
install_basic_packages() {
    print_message "Instalando pacotes básicos (configuração simples)..."

    local packages=(
        "@modelcontextprotocol/server-sequential-thinking"
    )

    for package in "${packages[@]}"; do
        print_message "Instalando $package..."
        npm_install_global "$package" || print_warning "Falha ao instalar $package, pode ser instalado manualmente depois"
    done

    # Codex será usado via npx (não precisa estar instalado globalmente)
    print_message "Codex será usado via npx @openai/codex ✓"
}

# Instalar pacotes padrão (configuração padrão)
install_standard_packages() {
    print_message "Instalando pacotes padrão (configuração padrão)..."

    local packages=(
        "@modelcontextprotocol/server-sequential-thinking"
        "mcp-shrimp-task-manager"
    )

    for package in "${packages[@]}"; do
        print_message "Instalando $package..."
        npm_install_global "$package" || print_warning "Falha ao instalar $package, pode ser instalado manualmente depois"
    done

    # Codex será usado via npx (não precisa estar instalado globalmente)
    print_message "Codex será usado via npx @openai/codex ✓"

    # Instalar code-index-mcp
    install_code_index
}

# Instalar todos os pacotes (configuração avançada)
install_all_packages() {
    print_message "Instalando todos os pacotes (configuração avançada)..."

    local packages=(
        "@modelcontextprotocol/server-sequential-thinking"
        "mcp-shrimp-task-manager"
        "exa-mcp-server"
    )

    # Pacotes que precisam de Node v20+
    local node20_packages=(
        "chrome-devtools-mcp@latest"
    )

    for package in "${packages[@]}"; do
        print_message "Instalando $package..."
        npm_install_global "$package" || print_warning "Falha ao instalar $package, pode ser instalado manualmente depois"
    done

    # Instalar pacotes que precisam de Node v20+ apenas se a versão for adequada
    if check_node_version; then
        for package in "${node20_packages[@]}"; do
            print_message "Instalando $package..."
            npm_install_global "$package" || print_warning "Falha ao instalar $package, pode ser instalado manualmente depois"
        done
    else
        print_warning "chrome-devtools-mcp requer Node.js v20+. Pulando instalação."
        print_message "Para instalar, atualize o Node.js: https://nodejs.org/"
    fi

    # Codex será usado via npx (não precisa estar instalado globalmente)
    print_message "Codex será usado via npx @openai/codex ✓"

    # Instalar code-index-mcp
    install_code_index
}

# Instalar code-index-mcp
install_code_index() {
    print_message "Instalando code-index-mcp..."

    # Verificar se uvx está disponível
    if ! command_exists uvx; then
        print_message "Instalando uv (que fornece uvx)..."

        # Verificar se pipx está disponível
        if command_exists pipx; then
            pipx install uv || print_warning "Falha ao instalar uv via pipx"
        elif command_exists pip3; then
            # Tentar com --user primeiro
            pip3 install --user uv 2>/dev/null || \
            # Se falhar, tentar com --break-system-packages como último recurso
            pip3 install --break-system-packages uv 2>/dev/null || \
            print_warning "Falha ao instalar uv. Considere instalar pipx primeiro: 'sudo apt install pipx' ou 'python3 -m pip install --user pipx'"
        elif command_exists pip; then
            pip install --user uv 2>/dev/null || \
            pip install --break-system-packages uv 2>/dev/null || \
            print_warning "Falha ao instalar uv. Considere instalar pipx primeiro"
        else
            print_warning "pip/pip3 não encontrado. Não é possível instalar uv."
            return 1
        fi

        # Adicionar ~/.local/bin ao PATH se necessário
        if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            print_message "Adicionando ~/.local/bin ao PATH..."
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi

    # Testar code-index-mcp
    if command_exists uvx; then
        print_message "Testando code-index-mcp..."
        uvx code-index-mcp --help >/dev/null 2>&1 && print_message "code-index-mcp instalado ✓" || \
        print_warning "code-index-mcp disponível, mas falhou no teste (isso é normal na primeira execução)"
    else
        print_warning "uvx não encontrado após instalação. Você pode instalar manualmente: https://docs.astral.sh/uv/"
    fi
}

# Verificar instalação
verify_installation() {
    print_message "Verificando instalação..."

    local config_dir=$(get_claude_config_dir)
    local config_file="$config_dir/claude_desktop_config.json"

    if [ -f "$config_file" ]; then
        print_message "Arquivo de configuração instalado corretamente ✓"
    else
        print_error "Falha ao instalar arquivo de configuração"
        return 1
    fi

    print_message "Verificação de instalação concluída ✓"
}

# Adicionar MCPs ao Claude Code
add_mcps_to_claude_code() {
    print_message "Configurando servidores MCP no Claude Code..."

    # Verificar se Claude Code está instalado
    if ! command_exists claude; then
        print_warning "Claude Code não encontrado. Pulando configuração de MCP."
        print_message "Instale Claude Code de: https://github.com/anthropics/claude-code"
        return 0
    fi

    # Importar servidores MCP do Claude Desktop
    print_message "Importando servidores MCP do Claude Desktop para Claude Code..."

    # Tentar importar com scope user (configuração do usuário)
    local import_output=$(claude mcp add-from-claude-desktop --scope user 2>&1)

    if echo "$import_output" | grep -qi "success\|imported\|added"; then
        print_message "Servidores MCP importados com sucesso para Claude Code ✓"
    else
        print_warning "Importação automática falhou. Saída: $import_output"
        print_message "Tentando importação manual dos servidores..."

        # Método alternativo: adicionar servidores manualmente
        add_mcps_manually
    fi

    # Listar servidores configurados
    print_message "Servidores MCP configurados:"
    claude mcp list 2>/dev/null || print_warning "Não foi possível listar servidores MCP"
}

# Adicionar MCPs manualmente ao Claude Code
add_mcps_manually() {
    local config_file="$HOME/.config/claude/claude_desktop_config.json"

    if [ ! -f "$config_file" ]; then
        print_error "Arquivo de configuração não encontrado: $config_file"
        return 1
    fi

    print_message "Adicionando servidores MCP manualmente..."

    # Adicionar sequential-thinking
    if grep -q "sequential-thinking" "$config_file"; then
        print_message "Adicionando sequential-thinking..."
        claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking 2>/dev/null && \
            print_message "✓ sequential-thinking adicionado" || \
            print_warning "✗ Falha ao adicionar sequential-thinking"
    fi

    # Adicionar shrimp-task-manager se existir
    if grep -q "shrimp-task-manager" "$config_file"; then
        print_message "Adicionando shrimp-task-manager..."
        claude mcp add --scope user --transport stdio shrimp-task-manager -- npx -y mcp-shrimp-task-manager 2>/dev/null && \
            print_message "✓ shrimp-task-manager adicionado" || \
            print_warning "✗ Falha ao adicionar shrimp-task-manager"
    fi

    # Adicionar codex se existir
    if grep -q "\"codex\"" "$config_file"; then
        print_message "Adicionando codex..."
        claude mcp add --scope user --transport stdio codex -- npx -y @openai/codex mcp-server 2>/dev/null && \
            print_message "✓ codex adicionado" || \
            print_warning "✗ Falha ao adicionar codex"
    fi

    # Adicionar code-index se existir
    if grep -q "code-index" "$config_file"; then
        print_message "Adicionando code-index..."
        # Usar caminho absoluto do uvx
        local uvx_path=$(command -v uvx || echo "$HOME/.local/bin/uvx")
        claude mcp add --scope user --transport stdio code-index -- "$uvx_path" code-index-mcp 2>/dev/null && \
            print_message "✓ code-index adicionado" || \
            print_warning "✗ Falha ao adicionar code-index"
    fi

    # Adicionar exa se existir
    if grep -q "\"exa\"" "$config_file"; then
        print_message "Adicionando exa..."
        local exa_key=$(grep -A5 "\"exa\"" "$config_file" | grep "EXA_API_KEY" | sed 's/.*": "//;s/".*//')
        if [ -n "$exa_key" ] && [ "$exa_key" != "your-exa-api-key-here" ]; then
            claude mcp add --scope user --transport stdio --env EXA_API_KEY="$exa_key" exa -- npx -y exa-mcp-server 2>/dev/null && \
                print_message "✓ exa adicionado" || \
                print_warning "✗ Falha ao adicionar exa"
        else
            print_warning "Chave API Exa não configurada, pulando exa"
        fi
    fi

    # Adicionar chrome-devtools se existir e Node >= 20
    if grep -q "chrome-devtools" "$config_file" && check_node_version; then
        print_message "Adicionando chrome-devtools..."
        claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest 2>/dev/null && \
            print_message "✓ chrome-devtools adicionado" || \
            print_warning "✗ Falha ao adicionar chrome-devtools"
    fi
}

# Criar estrutura de diretórios de trabalho
create_working_directories() {
    local config_dir=$1
    local project_dir=$(dirname "$config_dir")
    local claude_dir="$project_dir/.claude"

    print_message "Criando estrutura de diretórios de trabalho..."

    # Criar estrutura de diretórios .claude
    mkdir -p "$claude_dir"/{shrimp,codex,context,logs,cache}

    print_message "Estrutura de diretórios de trabalho criada ✓"
}

# Obter chave API OpenAI
get_openai_api_key() {
    echo "" >&2
    print_message "Por favor, insira sua chave API OpenAI (opcional):" >&2
    print_warning "Necessária para funcionalidades que usam modelos OpenAI" >&2
    print_message "Obtenha sua chave em: https://platform.openai.com/api-keys" >&2
    echo "" >&2

    read -s -p "Chave API OpenAI (opcional, pressione Enter para pular): " openai_key
    echo "" >&2

    if [ -z "$openai_key" ]; then
        print_message "Configuração da chave API OpenAI pulada" >&2
    fi

    echo "$openai_key"
}

# Obter chave API Exa
get_exa_api_key() {
    echo "" >&2
    print_message "Por favor, insira sua chave API Exa (opcional):" >&2
    print_warning "Necessária para pesquisa avançada na web" >&2
    print_message "Obtenha sua chave em: https://exa.ai/" >&2
    echo "" >&2

    read -s -p "Chave API Exa (opcional, pressione Enter para pular): " exa_key
    echo "" >&2

    if [ -z "$exa_key" ]; then
        print_message "Configuração da chave API Exa pulada" >&2
    fi

    echo "$exa_key"
}

# Testar servidores MCP
test_mcp_servers() {
    print_message "Testando servidores MCP instalados..."
    echo ""

    print_message "Verificando MCPs via Claude Code..."

    # Usar o comando do Claude Code para verificar os MCPs
    if command_exists claude; then
        claude mcp list 2>/dev/null | grep -E "✓|✗|Connected|Failed" || print_warning "Não foi possível verificar o status dos MCPs"
    else
        print_warning "Claude Code não está instalado, pulando verificação de MCPs"
        return 0
    fi

    echo ""
    print_message "Dica: Execute 'claude mcp list' para ver o status detalhado dos servidores MCP"
}

# Exibir informações de conclusão
show_completion() {
    local config_level=$1
    echo ""
    print_header
    print_message "🎉 Instalação do Claude Code + Codex concluída!"
    echo ""
    print_message "Nível de configuração instalado: $config_level"
    echo ""

    case $config_level in
        "simple")
            print_message "Funcionalidades instaladas:"
            echo "✓ Sequential-thinking (raciocínio profundo)"
            echo "✓ Codex (análise de código)"
            echo "✓ Fluxo de trabalho colaborativo básico"
            ;;
        "standard")
            print_message "Funcionalidades instaladas:"
            echo "✓ Sequential-thinking (raciocínio profundo)"
            echo "✓ Shrimp Task Manager (gerenciamento de tarefas)"
            echo "✓ Codex (análise de código)"
            echo "✓ Code Index (indexação de código)"
            echo "✓ Fluxo de trabalho colaborativo padrão"
            ;;
        "advanced")
            print_message "Funcionalidades instaladas:"
            echo "✓ Sequential-thinking (raciocínio profundo)"
            echo "✓ Shrimp Task Manager (gerenciamento de tarefas)"
            echo "✓ Codex (análise de código)"
            echo "✓ Code Index (indexação de código)"
            echo "✓ Chrome DevTools (depuração de navegador)"
            echo "✓ Exa Search (pesquisa na web)"
            echo "✓ Fluxo de trabalho colaborativo completo"
            ;;
    esac

    echo ""
    print_message "Próximos passos para usar:"
    echo "1. Para usar no Claude Code CLI, execute:"
    echo "   cd seu-projeto"
    echo "   claude"
    echo ""
    echo "2. No Claude Code, os servidores MCP estarão disponíveis automaticamente"
    echo ""
    echo "3. Verifique os servidores MCP configurados:"
    echo "   claude mcp list"
    echo ""
    echo "4. Para testar uma funcionalidade, tente:"
    echo "   claude \"Liste os arquivos deste projeto usando code-index\""
    echo ""
    print_message "Localização do arquivo de configuração:"
    echo "$(get_claude_config_dir)/claude_desktop_config.json"
    echo ""
    print_message "Estrutura do diretório de trabalho:"
    echo "$(dirname $(get_claude_config_dir))/.claude/"
    echo ""
    print_message "Comandos úteis:"
    echo "  claude mcp list          # Listar servidores MCP"
    echo "  claude mcp get <nome>    # Ver detalhes de um servidor"
    echo "  claude --help            # Ajuda do Claude Code"
    echo ""
    print_message "Se encontrar problemas, consulte o guia de solução de problemas:"
    echo "https://github.com/claude-codex/setup/troubleshooting"
    echo ""
}

# Função principal
main() {
    print_header

    # Detectar e mostrar sistema operacional
    local detected_os=$(detect_os)
    print_message "Sistema detectado: $detected_os"
    if [[ "$detected_os" == "wsl" ]]; then
        print_message "Executando no Windows Subsystem for Linux (WSL)"
    fi
    echo ""

    # Verificar dependências
    check_dependencies

    # Obter diretório de configuração
    local config_dir=$(create_config_dir)

    # Obter diretório do script para localizar os templates
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Selecionar template de configuração (retorna nome do arquivo e nível de configuração)
    local config_choice=$(choose_config)
    local template_filename=$(echo "$config_choice" | cut -d'|' -f1)
    local config_level=$(echo "$config_choice" | cut -d'|' -f2)

    # Caminho completo do template
    local template_file="$script_dir/$template_filename"

    # Coletar chaves API
    local openai_key=""
    local exa_key=""

    # Perguntar sobre chave OpenAI (todas as configurações)
    print_message "Configuração de chaves API"
    read -p "Deseja configurar a chave API OpenAI? (y/N): " setup_openai
    if [[ "$setup_openai" =~ ^[Yy]$ ]]; then
        openai_key=$(get_openai_api_key)
    fi

    # Perguntar sobre chave Exa (somente configuração avançada)
    if [ "$config_level" = "advanced" ]; then
        read -p "Deseja configurar a chave API Exa? (y/N): " setup_exa
        if [[ "$setup_exa" =~ ^[Yy]$ ]]; then
            exa_key=$(get_exa_api_key)
        fi
    fi

    # Gerar arquivo de configuração
    local config_file="$config_dir/claude_desktop_config.json"
    generate_config "$template_file" "$openai_key" "$exa_key" "$config_file"

    # Verificar se o arquivo foi criado com sucesso
    if [ ! -f "$config_file" ]; then
        print_error "Falha ao criar arquivo de configuração"
        exit 1
    fi

    # Criar estrutura de diretórios de trabalho
    create_working_directories "$config_dir"

    # Instalar pacotes de acordo com o nível de configuração
    install_packages_by_config "$config_level"

    # Verificar instalação
    verify_installation

    # Adicionar MCPs ao Claude Code
    add_mcps_to_claude_code

    # Testar servidores MCP
    test_mcp_servers

    # Exibir informações de conclusão
    show_completion "$config_level"
}

# Executar função principal
main "$@"