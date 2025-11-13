#!/bin/bash

# Script de verificação de configuração do Claude Code + Codex
# Verifica se a configuração está instalada corretamente e funcionando

set -e

# Definições de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Imprimir mensagens coloridas
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_CHECKS++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_CHECKS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Funções de verificação
check_command() {
    local cmd=$1
    local description=$2
    ((TOTAL_CHECKS++))

    print_info "Verificando $description..."
    if command -v "$cmd" >/dev/null 2>&1; then
        print_success "$description instalado"
        return 0
    else
        print_error "$description não encontrado"
        return 1
    fi
}

check_file() {
    local file=$1
    local description=$2
    ((TOTAL_CHECKS++))

    print_info "Verificando $description..."
    if [ -f "$file" ]; then
        print_success "$description existe"
        return 0
    else
        print_error "$description não existe"
        return 1
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    ((TOTAL_CHECKS++))

    print_info "Verificando $description..."
    if [ -d "$dir" ]; then
        print_success "$description existe"
        return 0
    else
        print_error "$description não existe"
        return 1
    fi
}

validate_json() {
    local file=$1
    ((TOTAL_CHECKS++))

    print_info "Validando formato JSON..."
    if python3 -m json.tool "$file" >/dev/null 2>&1; then
        print_success "Formato JSON correto"
        return 0
    else
        print_error "Formato JSON incorreto"
        return 1
    fi
}

# Obter diretório de configuração do Claude
get_claude_config_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/Claude"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "$HOME/.config/claude"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "$APPDATA/Claude"
    else
        echo "$HOME/.config/claude"  # Caminho padrão Linux
    fi
}

# Verificar formato da chave API
check_api_key() {
    local api_key=$1
    ((TOTAL_CHECKS++))

    print_info "Verificando formato da chave API..."
    if [[ "$api_key" =~ ^sk-[a-zA-Z0-9]{48}$ ]]; then
        print_success "Formato da chave API correto"
        return 0
    elif [[ "$api_key" == "your-openai-api-key-here" ]]; then
        print_error "Chave API não configurada"
        return 1
    elif [[ -z "$api_key" ]]; then
        print_error "Chave API vazia"
        return 1
    else
        print_warning "Formato da chave API pode estar incorreto"
        return 1
    fi
}

# Testar conexão de rede
test_network() {
    ((TOTAL_CHECKS++))

    print_info "Testando conexão de rede..."
    if curl -s --connect-timeout 5 https://api.openai.com/v1/models >/dev/null 2>&1; then
        print_success "Conexão de rede normal"
        return 0
    else
        print_error "Falha na conexão de rede"
        return 1
    fi
}

# Verificar servidor MCP
check_mcp_server() {
    local server_name=$1
    local command=$2
    ((TOTAL_CHECKS++))

    print_info "Verificando servidor MCP: $server_name..."
    if eval "$command" >/dev/null 2>&1; then
        print_success "Servidor MCP $server_name disponível"
        return 0
    else
        print_warning "Servidor MCP $server_name não disponível"
        return 1
    fi
}

# Função principal de verificação
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Verificação de Configuração Claude Code + Codex  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""

    # Verificar dependências básicas
    print_info "Verificando dependências do sistema..."
    check_command "node" "Node.js"
    check_command "npm" "npm"
    check_command "python3" "Python 3"
    check_command "pip" "pip"
    echo ""

    # Verificar diretório e arquivos de configuração
    print_info "Verificando arquivos de configuração..."
    local config_dir=$(get_claude_config_dir)
    check_directory "$config_dir" "Diretório de configuração Claude"

    local config_file="$config_dir/claude_desktop_config.json"
    check_file "$config_file" "Arquivo de configuração Claude"
    echo ""

    # Validar formato do arquivo de configuração
    if [ -f "$config_file" ]; then
        validate_json "$config_file"

        # Verificar chave API
        print_info "Verificando configuração API..."
        local api_key=$(grep -o '"OPENAI_API_KEY": "[^"]*"' "$config_file" | cut -d'"' -f4)
        check_api_key "$api_key"
        echo ""
    fi

    # Verificar conexão de rede
    print_info "Verificando conexão de rede..."
    test_network
    echo ""

    # Verificar servidores MCP
    print_info "Verificando servidores MCP..."
    check_mcp_server "sequential-thinking" "npx -y @modelcontextprotocol/server-sequential-thinking --version"
    check_mcp_server "codex" "codex --version"
    check_mcp_server "shrimp-task-manager" "npx -y mcp-shrimp-task-manager --version"
    echo ""

    # Exibir resultados da verificação
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}        Resumo dos Resultados da Verificação            ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo -e "Total de verificações: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "Verificações aprovadas: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Verificações com falha: ${RED}$FAILED_CHECKS${NC}"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        print_success "🎉 Todas as verificações passaram! Configuração completamente correta"
        echo ""
        print_info "Próximos passos:"
        echo "1. Reinicie o aplicativo Claude Code"
        echo "2. Digite no chat: /available-tools"
        echo "3. Confirme que consegue ver as ferramentas relacionadas ao codex"
        exit 0
    else
        print_error "Encontrados $FAILED_CHECKS problemas que precisam ser corrigidos"
        echo ""
        print_info "Sugestões de correção:"
        echo "1. Execute novamente o script de instalação: ./install.sh"
        echo "2. Consulte o guia de solução de problemas: troubleshooting.md"
        echo "3. Verifique se a chave API está correta"
        exit 1
    fi
}

# Executar função principal
main "$@"