# Claude Code + Codex Explicação do Arquivo de Configuração

## 📁 Seleção do Arquivo de Configuração

### 1. Configuração Simples (Recomendado para Iniciantes)
- **Arquivo**: `config-simple.json`
- **Funcionalidade**: Colaboração básica Claude Code + Codex
- **Inclui**: Sequential-thinking (pensamento profundo)
- **Adequado para**: Experiência rápida e desenvolvimento básico

### 2. Configuração Padrão (Recomendado para Uso Diário)
- **Arquivo**: `claude-desktop-config.json`
- **Funcionalidade**: Ambiente de desenvolvimento colaborativo completo
- **Inclui**: Gerenciamento de tarefas + Indexação de código
- **Adequado para**: Trabalho de desenvolvimento diário

### 3. Configuração Avançada (Recomendado para Usuários Avançados)
- **Arquivo**: `config-advanced.json`
- **Funcionalidade**: Ambiente de desenvolvimento de nível empresarial
- **Inclui**: Depuração de navegador + Busca na web
- **Adequado para**: Projetos complexos e desenvolvimento avançado

## 🔧 Passos de Configuração

### Primeiro Passo: Escolha o Arquivo de Configuração
Escolha o arquivo de configuração apropriado de acordo com suas necessidades.

### Segundo Passo: Configure a Chave API
Edite o arquivo de configuração e substitua o seguinte conteúdo:
```json
"OPENAI_API_KEY": "your-openai-api-key-here"
```
Substitua pela sua chave API OpenAI real.

Configuração opcional:
```json
"EXA_API_KEY": "your-exa-api-key-here"
```
Se estiver usando a configuração avançada, você pode adicionar a chave API de busca Exa.

### Terceiro Passo: Copie para o Local Correto
**macOS**:
```bash
cp claude-desktop-config.json ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Windows**:
```cmd
copy claude-desktop-config.json %APPDATA%\Claude\claude_desktop_config.json
```

**Linux**:
```bash
cp claude-desktop-config.json ~/.config/claude/claude_desktop_config.json
```

### Quarto Passo: Reinicie o Claude Code
Reinicie o aplicativo Claude Code e a configuração será aplicada automaticamente.

## ✅ Verificar Configuração

Após reiniciar, digite no Claude Code:
```
/available-tools
```

Se você conseguir ver as ferramentas relacionadas ao codex, a configuração foi bem-sucedida!
