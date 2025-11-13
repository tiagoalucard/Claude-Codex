# Guia de Solução de Problemas

## 🔧 Resolução de Problemas Comuns

### ❌ Não Consigo Ver as Ferramentas do Codex

**Problema**: Ao digitar `/available-tools` no Claude Code não consigo ver as ferramentas relacionadas ao codex

**Possíveis Causas**:
1. Arquivo de configuração não instalado corretamente
2. Claude Code não reiniciado
3. Servidor MCP não iniciado

**Soluções**:
```bash
# 1. Verificar arquivo de configuração
./verify-config.sh

# 2. Verificar localização do arquivo de configuração
ls -la ~/Library/Application\ Support/Claude/claude_desktop_config.json  # macOS
ls -la ~/.config/claude/claude_desktop_config.json  # Linux
ls -la %APPDATA%/Claude/claude_desktop_config.json  # Windows

# 3. Reinstalar configuração
./install.sh
```

### 🔑 Problemas com Chave API

**Problema**: Falha na chamada da API com erro de autenticação

**Possíveis Causas**:
1. Formato incorreto da chave API
2. Chave API expirada
3. Saldo insuficiente na conta

**Soluções**:
```bash
# 1. Verificar formato da chave API
grep "OPENAI_API_KEY" ~/.config/claude/claude_desktop_config.json

# 2. Testar chave API
curl -H "Authorization: Bearer YOUR_API_KEY" https://api.openai.com/v1/models

# 3. Atualizar chave API
# Edite o arquivo de configuração e substitua a chave API
```

**Requisitos do Formato da Chave API**:
- Deve começar com `sk-`
- Comprimento total de 51 caracteres
- Contém letras e números

### 🌐 Problemas de Conexão de Rede

**Problema**: Não é possível conectar à API OpenAI

**Possíveis Causas**:
1. Firewall de rede bloqueando
2. Problemas nas configurações de proxy
3. Problemas de resolução DNS

**Soluções**:
```bash
# 1. Testar conexão de rede
curl -I https://api.openai.com/v1/models

# 2. Verificar configurações de proxy
echo $HTTP_PROXY
echo $HTTPS_PROXY

# 3. Usar proxy (se necessário)
export HTTPS_PROXY=http://your-proxy:port
```

### 📦 Falha na Instalação de Dependências

**Problema**: Falha na instalação de pacotes npm ou pip

**Possíveis Causas**:
1. Permissões insuficientes
2. Problemas de rede
3. Conflitos de versão

**Soluções**:
```bash
# 1. Usar sudo para instalar (Linux/macOS)
sudo npm install -g @modelcontextprotocol/server-sequential-thinking

# 2. Limpar cache do npm
npm cache clean --force

# 3. Usar mirror nacional
npm config set registry https://registry.npmmirror.com

# 4. Instalar pacote Python manualmente
pip3 install --user uv
```

### 🚀 Falha ao Iniciar Servidor MCP

**Problema**: Servidor MCP não inicia normalmente

**Possíveis Causas**:
1. Versão incompatível do Node.js
2. Problemas com ambiente Python
3. Porta ocupada

**Soluções**:
```bash
# 1. Verificar versão do Node.js
node --version  # Requer >= 16.0.0

# 2. Verificar versão do Python
python3 --version  # Requer >= 3.8

# 3. Testar servidor MCP manualmente
npx @modelcontextprotocol/server-sequential-thinking --version
codex --version

# 4. Ver logs de erro
tail -f ~/.claude/logs/*.log
```

## 🔍 Ferramentas de Diagnóstico

### Script de Verificação de Configuração
```bash
# Executar verificação completa de configuração
./verify-config.sh
```

### Etapas de Verificação Manual
```bash
# 1. Verificar sintaxe do arquivo de configuração
python3 -m json.tool ~/.config/claude/claude_desktop_config.json

# 2. Testar servidor MCP
npx -y @modelcontextprotocol/server-sequential-thinking --help
codex mcp-server --help

# 3. Verificar versão do Claude Code
# Digite no Claude Code: /version
```

## 📋 Requisitos do Sistema

### Requisitos Mínimos
- **Sistema Operacional**: Windows 10+, macOS 10.15+, Ubuntu 18.04+
- **Node.js**: 16.0.0+
- **Python**: 3.8+
- **Memória**: 4GB RAM
- **Armazenamento**: 1GB de espaço disponível

### Configuração Recomendada
- **Sistema Operacional**: Versão mais recente do Windows/macOS/Linux
- **Node.js**: 18.0.0+
- **Python**: 3.10+
- **Memória**: 8GB+ RAM
- **Armazenamento**: 2GB+ de espaço disponível
- **Rede**: Conexão estável com a internet

## 🔄 Redefinir Configuração

### Redefinição Completa
```bash
# 1. Fazer backup da configuração existente
cp ~/.config/claude/claude_desktop_config.json ~/.config/claude/claude_desktop_config.json.backup

# 2. Excluir arquivo de configuração
rm ~/.config/claude/claude_desktop_config.json

# 3. Reinstalar
./install.sh
```

### Limpar Dependências
```bash
# Desinstalar pacotes npm
npm uninstall -g @modelcontextprotocol/server-sequential-thinking
npm uninstall -g mcp-shrimp-task-manager
npm uninstall -g chrome-devtools-mcp
npm uninstall -g exa-mcp-server

# Desinstalar pacotes Python
pip uninstall uv
```

## 📞 Obter Ajuda

### Suporte da Comunidade
- **GitHub Issues**: https://github.com/Pluviobyte/Claude-Codex/issues
- **Área de Discussão**: https://github.com/Pluviobyte/Claude-Codex/discussions

### Coleta de Logs
```bash
# Coletar informações do sistema
./collect-logs.sh

# Coletar logs manualmente
echo "=== Informações do Sistema ===" > debug.log
uname -a >> debug.log
node --version >> debug.log
python3 --version >> debug.log
echo "" >> debug.log

echo "=== Arquivo de Configuração ===" >> debug.log
cat ~/.config/claude/claude_desktop_config.json >> debug.log
echo "" >> debug.log

echo "=== Teste de Rede ===" >> debug.log
curl -I https://api.openai.com/v1/models >> debug.log
```

## 🎯 Otimização de Desempenho

### Otimização de Chamadas API
- Usar modelo apropriado (gpt-4 é mais caro mas mais preciso que gpt-3.5)
- Definir limites de chamada razoáveis
- Fazer cache de resultados frequentemente usados

### Otimização Local
- Garantir memória suficiente
- Usar armazenamento SSD
- Fechar aplicativos desnecessários em segundo plano

### Otimização de Rede
- Usar conexão de rede estável
- Considerar usar aceleração CDN
- Definir tempo limite razoável

---

Se nenhuma das soluções acima resolver seu problema, por favor crie uma Issue no GitHub fornecendo informações detalhadas do erro e ambiente do sistema.
