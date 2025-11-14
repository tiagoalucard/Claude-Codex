# Correção do MCP Server code-index

**Data:** 13 de Novembro de 2025
**Status:** ✅ Resolvido

## Problema Identificado

O servidor MCP `code-index` estava falhando ao conectar, enquanto outros servidores MCP estavam funcionando corretamente:

```bash
$ claude mcp list
sequential-thinking: ✓ Connected
shrimp-task-manager: ✓ Connected
codex: ✓ Connected
code-index: ✗ Failed to connect    # ❌ FALHA
chrome-devtools: ✓ Connected
```

## Causa Raiz

O problema tinha **duas causas principais**:

### 1. Comando `uvx` Não Encontrado no PATH

O arquivo de configuração usava apenas `uvx` como comando, mas o executável estava localizado em `$HOME/.local/bin/uvx`, que não estava no PATH do processo do Claude Desktop.

**Configuração problemática:**
```json
"code-index": {
  "command": "uvx",  // ❌ Comando não encontrado
  "args": ["code-index-mcp"]
}
```

### 2. Falta do Campo `type: "stdio"`

Alguns servidores MCP estavam configurados sem o campo `type`, que especifica o protocolo de comunicação. O Claude Code usa comunicação via `stdio` (standard input/output) para se comunicar com os servidores MCP.

**Configuração incompleta:**
```json
"code-index": {
  "command": "$HOME/.local/bin/uvx",
  "args": ["code-index-mcp"]
  // ❌ Faltando "type": "stdio"
}
```

## Solução Implementada

### Passo 1: Correção do Caminho do Executável

Substituído o comando `uvx` pelo caminho absoluto usando a variável `$HOME`:

```json
"code-index": {
  "type": "stdio",
  "command": "$HOME/.local/bin/uvx",  // ✅ Caminho absoluto com $HOME
  "args": ["code-index-mcp"],
  "env": {
    "WORKING_DIR": ".claude"
  }
}
```

**Nota:** O script `install.sh` expande automaticamente `$HOME` para o caminho real do diretório home do usuário durante a instalação.

### Passo 2: Adição do Campo `type: "stdio"`

Adicionado o campo `type: "stdio"` em todos os servidores MCP que estavam sem ele:

- ✅ `code-index`
- ✅ `chrome-devtools`
- ✅ `exa`
- ✅ `shrimp-task-manager`

### Passo 3: Validação da Solução

Antes de aplicar a correção, validamos que o servidor MCP funcionava corretamente:

```bash
# Teste de execução do comando
$ $HOME/.local/bin/uvx code-index-mcp --help
✅ Funcionou corretamente

# Teste de comunicação via stdio
$ echo '{"jsonrpc":"2.0","id":1,"method":"initialize",...}' | \
  $HOME/.local/bin/uvx code-index-mcp
✅ Servidor respondeu corretamente com protocolVersion "2024-11-05"
```

## Configuração Final

**Arquivo:** `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "env": {
        "WORKING_DIR": ".claude",
        "OPENAI_API_KEY": "your-openai-api-key-here"
      }
    },
    "shrimp-task-manager": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "mcp-shrimp-task-manager"],
      "env": {
        "DATA_DIR": ".claude/shrimp",
        "TEMPLATES_USE": "zh",
        "ENABLE_GUI": "false"
      }
    },
    "codex": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@openai/codex", "mcp-server"],
      "env": {
        "WORKING_DIR": ".claude"
      }
    },
    "code-index": {
      "type": "stdio",
      "command": "$HOME/.local/bin/uvx",
      "args": ["code-index-mcp"],
      "env": {
        "WORKING_DIR": ".claude"
      }
    },
    "chrome-devtools": {
      "type": "stdio",
      "command": "npx",
      "args": ["chrome-devtools-mcp@latest"],
      "env": {
        "WORKING_DIR": ".claude"
      }
    },
    "exa": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "exa-mcp-server"],
      "env": {
        "EXA_API_KEY": "your-exa-api-key-here",
        "WORKING_DIR": ".claude"
      }
    }
  }
}
```

## Como Verificar se Está Funcionando

Após reiniciar o Claude Code, execute:

```bash
$ claude mcp list

Checking MCP server health...

sequential-thinking: ✓ Connected
shrimp-task-manager: ✓ Connected
codex: ✓ Connected
code-index: ✓ Connected          # ✅ SUCESSO!
chrome-devtools: ✓ Connected
exa: ✓ Connected
```

## Lições Aprendidas

### 1. Sempre Use Caminhos Absolutos para Executáveis

Quando configurar servidores MCP que não estejam em diretórios padrão do PATH, sempre use caminhos absolutos com variáveis de ambiente:

```json
// ❌ Ruim
"command": "uvx"

// ✅ Bom - usa variável $HOME (mais portável)
"command": "$HOME/.local/bin/uvx"

// ✅ Também funciona - caminho absoluto direto
"command": "/home/seu_usuario/.local/bin/uvx"
```

**Recomendação:** Use `$HOME` ao invés de caminhos absolutos com nomes de usuário específicos, pois funciona em qualquer sistema. O script `install.sh` expande automaticamente `$HOME` durante a instalação.

### 2. Especifique Explicitamente o Tipo de Comunicação

Sempre inclua o campo `type: "stdio"` para deixar claro o protocolo de comunicação:

```json
{
  "type": "stdio",  // ✅ Explícito e claro
  "command": "...",
  "args": [...]
}
```

### 3. Teste Servidores MCP Isoladamente

Antes de configurar um servidor MCP no Claude, teste se ele funciona corretamente via linha de comando:

```bash
# Teste básico
$ $HOME/.local/bin/uvx code-index-mcp --help

# Teste de comunicação stdio
$ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{...}}' | \
  $HOME/.local/bin/uvx code-index-mcp
```

### 4. Use o Script de Instalação Automática

O script `install.sh` foi atualizado para:
- ✅ Detectar automaticamente o caminho do `uvx`
- ✅ Expandir a variável `$HOME` para o valor real
- ✅ Adicionar `type: "stdio"` automaticamente em todos os servidores
- ✅ Validar a configuração antes de finalizar

Sempre prefira usar o script de instalação:

```bash
./install.sh
```

## Referências

- **MCP Protocol:** https://modelcontextprotocol.io
- **Claude Code MCP Docs:** https://docs.claude.com/claude-code/mcp-servers
- **code-index-mcp:** https://github.com/modelcontextprotocol/servers/tree/main/src/code-index

## Comandos Úteis

```bash
# Encontrar o caminho do uvx
which uvx
command -v uvx

# Listar servidores MCP e status
claude mcp list

# Ver configuração atual
cat ~/.config/claude/claude_desktop_config.json | python3 -m json.tool

# Testar code-index-mcp diretamente
$HOME/.local/bin/uvx code-index-mcp --help

# Reiniciar Claude Code (dentro de uma sessão)
# Ctrl+C ou digite 'exit', depois inicie novamente com 'claude'

# Limpar cache (se necessário)
rm -rf ~/.claude/cache/*
```

## Solução de Problemas

### Problema: uvx não encontrado

Se o comando `uvx` não for encontrado, instale o `uv`:

```bash
# Opção 1: Via pip3 (recomendado)
pip3 install --user uv

# Opção 2: Via pipx
pipx install uv

# Adicionar ao PATH (adicione ao ~/.bashrc ou ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"

# Recarregar o shell
source ~/.bashrc  # ou source ~/.zshrc
```

### Problema: Permissão negada

Se encontrar erros de permissão:

```bash
# Verificar se uvx tem permissão de execução
ls -l $HOME/.local/bin/uvx

# Adicionar permissão de execução se necessário
chmod +x $HOME/.local/bin/uvx
```

### Problema: code-index ainda falha após correções

1. Verifique se o diretório `.claude` existe:
```bash
mkdir -p .claude
```

2. Teste o comando diretamente:
```bash
$HOME/.local/bin/uvx code-index-mcp --help
```

3. Verifique os logs do Claude Code para mais detalhes do erro

---

**Última atualização:** 13 de Novembro de 2025
