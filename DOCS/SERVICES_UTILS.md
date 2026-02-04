# SERVICES UTILS

## Português

### Sobre

`services_utils.sh` é um gerenciador interativo de serviços systemd para Ubuntu Server (24.04 e superior). O script fornece uma interface de linha de comando amigável com navegação por setas, permitindo gerenciar serviços do sistema sem executar comandos manualmente.

### Funcionalidades Principais

- **Estatísticas dos Serviços**: Visualiza o total de serviços rodando, parados, ativados e desativados no sistema
- **Busca de Serviços**: Procura serviços por nome ou descrição com highlighting do termo encontrado
- **Listar Serviços**: Exibe listas separadas por estado:
  - Serviços em execução (running)
  - Serviços parados (stopped)
  - Serviços ativados para boot (enabled)
  - Serviços desativados (disabled)
  
- **Controle de Serviços**: Para cada serviço, é possível:
  - Iniciar, parar e reiniciar
  - Recarregar configurações (reload)
  - Ativar/desativar para inicialização automática (boot)
  - Visualizar 30 últimas linhas de logs via journalctl
  - Ver informações: descrição, status, PID, uso de memória

### Interface

- Interface colorida com formatação em caixas usando caracteres Unicode
- Navegação intuitiva com setas (↑↓), ENTER para selecionar e ESC para voltar
- Menu principal com 7 opções de navegação
- Indicadores visuais: ● (rodando), ○ (parado), ⚡ (ativado), ⏹ (desativado)
- Scroll automático em listas grandes (até 24 itens visíveis por tela)

### Requisitos

- Ubuntu Server 24.04+
- Acesso root (execução com `sudo`)
- systemd instalado (padrão no Ubuntu moderno)

---

## English

### About

`services_utils.sh` is an interactive systemd service manager for Ubuntu Server (24.04 and later). The script provides a user-friendly command-line interface with arrow key navigation, allowing you to manage system services without running manual commands.

### Main Features

- **Service Statistics**: View the total number of running, stopped, enabled, and disabled services on the system
- **Service Search**: Search services by name or description with highlighting of found terms
- **List Services**: Display separate lists by state:
  - Services in execution (running)
  - Stopped services (stopped)
  - Services enabled for boot (enabled)
  - Services disabled (disabled)

- **Service Control**: For each service, you can:
  - Start, stop, and restart services
  - Reload configurations (reload)
  - Enable/disable for automatic startup (boot)
  - View the last 30 lines of logs via journalctl
  - View information: description, status, PID, memory usage

### Interface

- Colorful interface with box formatting using Unicode characters
- Intuitive navigation with arrow keys (↑↓), ENTER to select, and ESC to go back
- Main menu with 7 navigation options
- Visual indicators: ● (running), ○ (stopped), ⚡ (enabled), ⏹ (disabled)
- Automatic scroll in large lists (up to 24 items visible per screen)

### Requirements

- Ubuntu Server 24.04+
- Root access (execution with `sudo`)
- systemd installed (default on modern Ubuntu)
