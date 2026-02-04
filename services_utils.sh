#!/bin/bash

# Script de Gerenciamento de Serviços - Ubuntu Server
# Navegação com setas (sem dialog)
# Data: 2026-02-04

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Configurações do terminal
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)

# Função para verificar root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script precisa ser executado como root ou com sudo${NC}"
        exit 1
    fi
}

# Função para limpar tela
clear_screen() {
    clear
    tput cup 0 0
}

# Função para ocultar cursor
hide_cursor() {
    tput civis
}

# Função para mostrar cursor
show_cursor() {
    tput cnorm
}

# Função para ler tecla
read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null
    
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key
        case $key in
            '[A') echo "up" ;;
            '[B') echo "down" ;;
            '') echo "esc" ;;
            *) echo "other" ;;
        esac
    elif [[ $key == "" ]]; then
        echo "enter"
    else
        echo "other"
    fi
}

# Função para desenhar cabeçalho
draw_header() {
    local title=$1
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}$(printf "%-76s" "  $title")${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para desenhar rodapé
draw_footer() {
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}  ↑↓${NC} Navegar  ${YELLOW}ENTER${NC} Selecionar  ${YELLOW}ESC${NC} Voltar"
}

# Função para obter estatísticas
get_statistics() {
    local running=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | wc -l)
    local stopped=$(systemctl list-units --type=service --state=dead --no-pager --no-legend 2>/dev/null | wc -l)
    local enabled=$(systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend 2>/dev/null | wc -l)
    local disabled=$(systemctl list-unit-files --type=service --state=disabled --no-pager --no-legend 2>/dev/null | wc -l)
    local failed=$(systemctl list-units --type=service --state=failed --no-pager --no-legend 2>/dev/null | wc -l)
    
    draw_header "📊 ESTATÍSTICAS DOS SERVIÇOS"
    echo ""
    echo -e "  ${GREEN}●${NC} Serviços Rodando:      ${WHITE}${BOLD}$running${NC}"
    echo -e "  ${YELLOW}○${NC} Serviços Parados:      ${WHITE}$stopped${NC}"
    echo -e "  ${GREEN}⚡${NC} Serviços Ativados:     ${WHITE}$enabled${NC}"
    echo -e "  ${YELLOW}⏹${NC}  Serviços Desativados:  ${WHITE}$disabled${NC}"
    if [ $failed -gt 0 ]; then
        echo -e "  ${RED}✗${NC} Serviços com Falha:    ${RED}${BOLD}$failed${NC}"
    fi
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Pressione qualquer tecla para continuar...${NC}"
    read -rsn1
}

# Função para obter lista de serviços
get_services() {
    local filter=$1
    local search_term=$2
    local services=()
    
    case $filter in
        "search")
            # Buscar em todos os serviços por nome e descrição
            while IFS= read -r line; do
                local service=$(echo "$line" | awk '{print $1}' | sed 's/.service//')
                local description=$(systemctl show "$service" --property=Description --value 2>/dev/null)
                
                # Verificar se o termo está no nome ou descrição (case insensitive)
                if [[ "${service,,}" == *"${search_term,,}"* ]] || [[ "${description,,}" == *"${search_term,,}"* ]]; then
                    services+=("$service")
                fi
            done < <(systemctl list-unit-files --type=service --no-pager --no-legend 2>/dev/null)
            ;;
        "running")
            while IFS= read -r line; do
                local service=$(echo "$line" | awk '{print $1}' | sed 's/.service//')
                services+=("$service")
            done < <(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null)
            ;;
        "stopped")
            while IFS= read -r line; do
                local service=$(echo "$line" | awk '{print $1}' | sed 's/.service//')
                services+=("$service")
            done < <(systemctl list-units --type=service --state=dead --no-pager --no-legend 2>/dev/null | head -200)
            ;;
        "enabled")
            while IFS= read -r line; do
                local service=$(echo "$line" | awk '{print $1}' | sed 's/.service//')
                services+=("$service")
            done < <(systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend 2>/dev/null | head -300)
            ;;
        "disabled")
            while IFS= read -r line; do
                local service=$(echo "$line" | awk '{print $1}' | sed 's/.service//')
                services+=("$service")
            done < <(systemctl list-unit-files --type=service --state=disabled --no-pager --no-legend 2>/dev/null | head -300)
            ;;
    esac
    
    printf '%s\n' "${services[@]}"
}

# Função para obter informações do serviço
get_service_info() {
    local service=$1
    local status=$(systemctl is-active "$service" 2>/dev/null)
    local enabled=$(systemctl is-enabled "$service" 2>/dev/null)
    
    echo "$status|$enabled"
}

# Função para buscar serviços
search_services() {
    show_cursor
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}  🔍 BUSCAR SERVIÇOS                                                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}Digite o termo de busca (nome ou descrição):${NC}"
    echo ""
    echo -n "  > "
    
    local search_term
    read search_term
    
    # Remover espaços extras
    search_term=$(echo "$search_term" | xargs)
    
    if [ -z "$search_term" ]; then
        echo ""
        echo -e "  ${YELLOW}Busca cancelada (termo vazio)${NC}"
        sleep 2
        hide_cursor
        return
    fi
    
    hide_cursor
    
    # Mostrar mensagem de busca
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}  🔍 BUSCANDO...                                                            ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}Procurando por: ${WHITE}${BOLD}$search_term${NC}"
    echo -e "  ${CYAN}Aguarde...${NC}"
    
    # Executar busca
    select_service_menu "search" "🔍 RESULTADOS DA BUSCA: \"$search_term\"" "$search_term"
}

# Função para menu de seleção de serviços
select_service_menu() {
    local filter=$1
    local title=$2
    local search_term=$3
    local selected=0
    local scroll_offset=0
    local max_display=24
    
    # Obter serviços
    if [ "$filter" == "search" ]; then
        readarray -t services < <(get_services "$filter" "$search_term")
    else
        readarray -t services < <(get_services "$filter")
    fi
    
    local total=${#services[@]}
    
    if [ $total -eq 0 ]; then
        draw_header "$title"
        if [ "$filter" == "search" ]; then
            echo -e "${YELLOW}  Nenhum serviço encontrado com o termo: ${WHITE}${BOLD}$search_term${NC}"
        else
            echo -e "${YELLOW}  Nenhum serviço encontrado!${NC}"
        fi
        echo ""
        echo -e "${YELLOW}Pressione qualquer tecla para continuar...${NC}"
        read -rsn1
        return
    fi
    
    hide_cursor
    
    while true; do
        draw_header "$title"
        if [ "$filter" == "search" ]; then
            echo -e "  ${CYAN}Termo buscado: ${WHITE}${BOLD}$search_term${NC}"
        fi
        echo -e "  ${CYAN}Total de serviços: ${WHITE}$total${NC}"
        echo ""
        
        # Calcular janela de visualização
        if [ $selected -ge $((scroll_offset + max_display)) ]; then
            scroll_offset=$((selected - max_display + 1))
        elif [ $selected -lt $scroll_offset ]; then
            scroll_offset=$selected
        fi
        
        local end=$((scroll_offset + max_display))
        [ $end -gt $total ] && end=$total
        
        # Exibir serviços
        for ((i=scroll_offset; i<end; i++)); do
            local service="${services[$i]}"
            local info=$(get_service_info "$service")
            local status=$(echo "$info" | cut -d'|' -f1)
            local enabled=$(echo "$info" | cut -d'|' -f2)
            
            # Ícone de status
            if [ "$status" == "active" ]; then
                local status_icon="${GREEN}●${NC}"
                local status_text="${GREEN}running${NC}"
            else
                local status_icon="${YELLOW}○${NC}"
                local status_text="${YELLOW}stopped${NC}"
            fi
            
            # Ícone de enabled
            if [ "$enabled" == "enabled" ]; then
                local enabled_icon="${GREEN}⚡${NC}"
            else
                local enabled_icon="${YELLOW}⏹${NC}"
            fi
            
            # Highlight do termo buscado no nome
            local service_display="$service"
            if [ "$filter" == "search" ] && [ -n "$search_term" ]; then
                # Destacar o termo encontrado (case insensitive)
                service_display=$(echo "$service" | sed -E "s/($search_term)/${YELLOW}${BOLD}\1${NC}/gi")
            fi
            
            # Highlight da linha selecionada
            if [ $i -eq $selected ]; then
                echo -e "  ${WHITE}${BOLD}▶${NC} $status_icon $enabled_icon ${WHITE}${BOLD}$(printf "%-45s" "$service")${NC} $status_text"
            else
                echo -e "    $status_icon $enabled_icon $(printf "%-45s" "$service") $status_text"
            fi
        done
        
        # Indicador de scroll
        if [ $scroll_offset -gt 0 ]; then
            echo -e "\n  ${CYAN}↑ Mais serviços acima... (${scroll_offset} ocultos)${NC}"
        fi
        if [ $end -lt $total ]; then
            echo -e "  ${CYAN}↓ Mais serviços abaixo... ($((total - end)) restantes)${NC}"
        fi
        
        draw_footer
        
        # Ler tecla
        local key=$(read_key)
        
        case $key in
            "up")
                [ $selected -gt 0 ] && ((selected--))
                ;;
            "down")
                [ $selected -lt $((total - 1)) ] && ((selected++))
                ;;
            "enter")
                show_cursor
                service_control_menu "${services[$selected]}"
                hide_cursor
                ;;
            "esc")
                show_cursor
                return
                ;;
        esac
    done
}

# Função para menu de controle do serviço
service_control_menu() {
    local service=$1
    local selected=0
    
    hide_cursor
    
    while true; do
        # Obter informações atualizadas
        local status=$(systemctl is-active "$service" 2>/dev/null)
        local enabled=$(systemctl is-enabled "$service" 2>/dev/null)
        local main_pid=$(systemctl show "$service" --property=MainPID --value 2>/dev/null)
        local memory=$(systemctl show "$service" --property=MemoryCurrent --value 2>/dev/null)
        local description=$(systemctl show "$service" --property=Description --value 2>/dev/null)
        
        # Formatar memória
        if [ "$memory" != "[not set]" ] && [ "$memory" != "0" ] && [ -n "$memory" ]; then
            memory_mb=$((memory / 1024 / 1024))
            memory_display="${memory_mb} MB"
        else
            memory_display="N/A"
        fi
        
        # Montar opções do menu
        local options=()
        
        if [ "$status" == "active" ]; then
            options+=("Parar Serviço")
            options+=("Reiniciar Serviço")
            options+=("Recarregar Configuração")
        else
            options+=("Iniciar Serviço")
        fi
        
        if [ "$enabled" == "enabled" ]; then
            options+=("Desativar (boot)")
        else
            options+=("Ativar (boot)")
        fi
        
        options+=("Ver Logs")
        options+=("Atualizar Status")
        options+=("Voltar")
        
        # Desenhar tela
        draw_header "🔍 DETALHES DO SERVIÇO: $service"
        
        echo -e "  ${CYAN}Descrição:${NC} $description"
        echo ""
        
        # Status
        if [ "$status" == "active" ]; then
            echo -e "  ${CYAN}Status:${NC}    ${GREEN}●${NC} ${GREEN}${BOLD}RODANDO${NC}"
        else
            echo -e "  ${CYAN}Status:${NC}    ${YELLOW}○${NC} ${YELLOW}PARADO${NC}"
        fi
        
        # Enabled
        if [ "$enabled" == "enabled" ]; then
            echo -e "  ${CYAN}Boot:${NC}      ${GREEN}⚡ ATIVADO${NC}"
        else
            echo -e "  ${CYAN}Boot:${NC}      ${YELLOW}⏹ DESATIVADO${NC}"
        fi
        
        echo -e "  ${CYAN}PID:${NC}       $main_pid"
        echo -e "  ${CYAN}Memória:${NC}   $memory_display"
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${WHITE}${BOLD}AÇÕES DISPONÍVEIS:${NC}"
        echo ""
        
        # Exibir opções
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${WHITE}${BOLD}▶ ${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done
        
        draw_footer
        
        # Ler tecla
        local key=$(read_key)
        
        case $key in
            "up")
                [ $selected -gt 0 ] && ((selected--))
                ;;
            "down")
                [ $selected -lt $((${#options[@]} - 1)) ] && ((selected++))
                ;;
            "enter")
                local action="${options[$selected]}"
                
                # Se a ação for "Voltar", sair do menu
                if [ "$action" == "Voltar" ]; then
                    show_cursor
                    return
                fi
                
                show_cursor
                execute_action "$service" "$action"
                hide_cursor
                
                # Resetar seleção após executar ação (exceto atualizar)
                if [ "$action" != "Atualizar Status" ]; then
                    selected=0
                fi
                ;;
            "esc")
                show_cursor
                return
                ;;
        esac
    done
}

# Função para executar ação
execute_action() {
    local service=$1
    local action=$2
    
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}  Executando Ação...                                                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    case $action in
        "Iniciar Serviço")
            echo -e "  ${YELLOW}Iniciando $service...${NC}"
            systemctl start "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Serviço iniciado com sucesso!${NC}"
            else
                echo -e "  ${RED}✗ Erro ao iniciar serviço!${NC}"
            fi
            ;;
        "Parar Serviço")
            echo -e "  ${YELLOW}Parando $service...${NC}"
            systemctl stop "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Serviço parado com sucesso!${NC}"
            else
                echo -e "  ${RED}✗ Erro ao parar serviço!${NC}"
            fi
            ;;
        "Reiniciar Serviço")
            echo -e "  ${YELLOW}Reiniciando $service...${NC}"
            systemctl restart "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Serviço reiniciado com sucesso!${NC}"
            else
                echo -e "  ${RED}✗ Erro ao reiniciar serviço!${NC}"
            fi
            ;;
        "Recarregar Configuração")
            echo -e "  ${YELLOW}Recarregando $service...${NC}"
            systemctl reload "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Configuração recarregada com sucesso!${NC}"
            else
                echo -e "  ${RED}✗ Erro ao recarregar (tente reiniciar)${NC}"
            fi
            ;;
        "Ativar (boot)")
            echo -e "  ${YELLOW}Ativando $service para iniciar no boot...${NC}"
            systemctl enable "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Serviço ativado para iniciar no boot!${NC}"
            else
                echo -e "  ${RED}✗ Erro ao ativar serviço!${NC}"
            fi
            ;;
        "Desativar (boot)")
            echo -e "  ${YELLOW}Desativando $service...${NC}"
            systemctl disable "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Serviço desativado!${NC}"
            else
                echo -e "  ${RED}✗ Erro ao desativar serviço!${NC}"
            fi
            ;;
        "Ver Logs")
            clear_screen
            echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${WHITE}${BOLD}  LOGS: $service${NC}$(printf "%$((75 - ${#service}))s")${CYAN}║${NC}"
            echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            journalctl -u "$service" -n 30 --no-pager 2>/dev/null
            echo ""
            echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────${NC}"
            echo -e "${YELLOW}Pressione qualquer tecla para continuar...${NC}"
            read -rsn1
            return
            ;;
        "Atualizar Status")
            return
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Pressione qualquer tecla para continuar...${NC}"
    read -rsn1
}

# Menu principal
main_menu() {
    local selected=0
    local options=(
        "📊 Estatísticas dos Serviços"
        "🔍 Buscar Serviços"
        "● Serviços Rodando"
        "○ Serviços Parados"
        "⚡ Serviços Ativados (enabled)"
        "⏹ Serviços Desativados (disabled)"
        "🚪 Sair"
    )
    
    hide_cursor
    
    while true; do
        draw_header "🎮 GERENCIADOR DE SERVIÇOS - SYSTEMD"
        echo ""
        
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${WHITE}${BOLD}▶ ${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done
        
        draw_footer
        
        local key=$(read_key)
        
        case $key in
            "up")
                [ $selected -gt 0 ] && ((selected--))
                ;;
            "down")
                [ $selected -lt $((${#options[@]} - 1)) ] && ((selected++))
                ;;
            "enter")
                case $selected in
                    0)
                        show_cursor
                        get_statistics
                        hide_cursor
                        ;;
                    1)
                        search_services
                        ;;
                    2)
                        select_service_menu "running" "● SERVIÇOS RODANDO"
                        ;;
                    3)
                        select_service_menu "stopped" "○ SERVIÇOS PARADOS"
                        ;;
                    4)
                        select_service_menu "enabled" "⚡ SERVIÇOS ATIVADOS"
                        ;;
                    5)
                        select_service_menu "disabled" "⏹ SERVIÇOS DESATIVADOS"
                        ;;
                    6)
                        show_cursor
                        clear
                        echo -e "${GREEN}Até logo!${NC}"
                        exit 0
                        ;;
                esac
                ;;
            "esc")
                show_cursor
                clear
                echo -e "${GREEN}Até logo!${NC}"
                exit 0
                ;;
        esac
    done
}

# Trap para restaurar cursor ao sair
trap show_cursor EXIT INT TERM

# Iniciar
check_root
main_menu