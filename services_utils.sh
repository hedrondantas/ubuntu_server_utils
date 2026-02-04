#!/bin/bash

# Script de Gerenciamento de Serviços - Ubuntu Server
# Autor: Script gerado para gerenciamento systemd
# Data: 2026-02-04

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem cor

# Função para verificar privilégios root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script precisa ser executado como root ou com sudo${NC}"
        exit 1
    fi
}

# Função para limpar tela
clear_screen() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   GERENCIADOR DE SERVIÇOS - SYSTEMD${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Função para exibir estatísticas de serviços
show_statistics() {
    clear_screen
    echo -e "${BLUE}📊 ESTATÍSTICAS DOS SERVIÇOS${NC}"
    echo ""
    
    local running=$(systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l)
    local stopped=$(systemctl list-units --type=service --state=dead --no-pager --no-legend | wc -l)
    local enabled=$(systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend | wc -l)
    local disabled=$(systemctl list-unit-files --type=service --state=disabled --no-pager --no-legend | wc -l)
    local failed=$(systemctl list-units --type=service --state=failed --no-pager --no-legend | wc -l)
    
    echo -e "${GREEN}✓ Serviços Rodando:${NC}    $running"
    echo -e "${YELLOW}⏸ Serviços Parados:${NC}     $stopped"
    echo -e "${GREEN}⚡ Serviços Ativados:${NC}   $enabled"
    echo -e "${YELLOW}⏹ Serviços Desativados:${NC} $disabled"
    
    if [ $failed -gt 0 ]; then
        echo -e "${RED}✗ Serviços com Falha:${NC}  $failed"
    fi
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para listar serviços
list_services() {
    clear_screen
    echo -e "${BLUE}📋 LISTAR SERVIÇOS${NC}"
    echo ""
    echo "1. Serviços Ativos (rodando)"
    echo "2. Serviços Inativos (parados)"
    echo "3. Serviços Habilitados (enabled)"
    echo "4. Serviços Desabilitados (disabled)"
    echo "5. Todos os serviços"
    echo "6. Serviços com falha"
    echo "0. Voltar"
    echo ""
    read -p "Escolha uma opção: " option
    
    case $option in
        1)
            clear_screen
            echo -e "${GREEN}Serviços Rodando:${NC}"
            echo ""
            systemctl list-units --type=service --state=running --no-pager
            ;;
        2)
            clear_screen
            echo -e "${YELLOW}Serviços Parados:${NC}"
            echo ""
            systemctl list-units --type=service --state=dead --no-pager
            ;;
        3)
            clear_screen
            echo -e "${GREEN}Serviços Habilitados:${NC}"
            echo ""
            systemctl list-unit-files --type=service --state=enabled --no-pager
            ;;
        4)
            clear_screen
            echo -e "${YELLOW}Serviços Desabilitados:${NC}"
            echo ""
            systemctl list-unit-files --type=service --state=disabled --no-pager
            ;;
        5)
            clear_screen
            echo -e "${BLUE}Todos os Serviços:${NC}"
            echo ""
            systemctl list-units --type=service --all --no-pager
            ;;
        6)
            clear_screen
            echo -e "${RED}Serviços com Falha:${NC}"
            echo ""
            systemctl list-units --type=service --state=failed --no-pager
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para ver detalhes de um serviço
service_details() {
    clear_screen
    echo -e "${BLUE}🔍 DETALHES DO SERVIÇO${NC}"
    echo ""
    read -p "Digite o nome do serviço (ex: ssh, apache2): " service_name
    
    if systemctl list-unit-files | grep -q "^${service_name}.service"; then
        clear_screen
        echo -e "${CYAN}Detalhes de: ${service_name}${NC}"
        echo ""
        systemctl status ${service_name}
        echo ""
        echo -e "${CYAN}Informações adicionais:${NC}"
        echo ""
        systemctl show ${service_name} --no-pager | grep -E "^(Description|LoadState|ActiveState|SubState|UnitFileState)"
    else
        echo -e "${RED}Serviço '${service_name}' não encontrado!${NC}"
    fi
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para ativar/desativar serviço
toggle_service() {
    clear_screen
    echo -e "${BLUE}⚙️  ATIVAR/DESATIVAR SERVIÇO${NC}"
    echo ""
    echo "1. Ativar serviço (enable)"
    echo "2. Desativar serviço (disable)"
    echo "0. Voltar"
    echo ""
    read -p "Escolha uma opção: " option
    
    case $option in
        1)
            read -p "Digite o nome do serviço para ATIVAR: " service_name
            systemctl enable ${service_name} 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Serviço '${service_name}' ativado com sucesso!${NC}"
            else
                echo -e "${RED}✗ Erro ao ativar serviço '${service_name}'${NC}"
            fi
            ;;
        2)
            read -p "Digite o nome do serviço para DESATIVAR: " service_name
            systemctl disable ${service_name} 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Serviço '${service_name}' desativado com sucesso!${NC}"
            else
                echo -e "${RED}✗ Erro ao desativar serviço '${service_name}'${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para controlar serviço
control_service() {
    clear_screen
    echo -e "${BLUE}🎮 CONTROLAR SERVIÇO${NC}"
    echo ""
    echo "1. Iniciar serviço (start)"
    echo "2. Parar serviço (stop)"
    echo "3. Reiniciar serviço (restart)"
    echo "4. Recarregar configuração (reload)"
    echo "5. Ver status do serviço"
    echo "0. Voltar"
    echo ""
    read -p "Escolha uma opção: " option
    
    if [ "$option" == "0" ]; then
        return
    fi
    
    read -p "Digite o nome do serviço: " service_name
    
    case $option in
        1)
            systemctl start ${service_name} 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Serviço '${service_name}' iniciado com sucesso!${NC}"
            else
                echo -e "${RED}✗ Erro ao iniciar serviço '${service_name}'${NC}"
            fi
            ;;
        2)
            systemctl stop ${service_name} 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Serviço '${service_name}' parado com sucesso!${NC}"
            else
                echo -e "${RED}✗ Erro ao parar serviço '${service_name}'${NC}"
            fi
            ;;
        3)
            systemctl restart ${service_name} 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Serviço '${service_name}' reiniciado com sucesso!${NC}"
            else
                echo -e "${RED}✗ Erro ao reiniciar serviço '${service_name}'${NC}"
            fi
            ;;
        4)
            systemctl reload ${service_name} 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Configuração do serviço '${service_name}' recarregada com sucesso!${NC}"
            else
                echo -e "${RED}✗ Erro ao recarregar serviço '${service_name}'${NC}"
            fi
            ;;
        5)
            clear_screen
            systemctl status ${service_name}
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Menu principal
main_menu() {
    while true; do
        clear_screen
        echo "1. 📊 Exibir estatísticas de serviços"
        echo "2. 📋 Listar serviços"
        echo "3. 🔍 Ver detalhes de um serviço"
        echo "4. ⚙️  Ativar/Desativar serviço"
        echo "5. 🎮 Controlar serviço (start/stop/restart/status)"
        echo "0. 🚪 Sair"
        echo ""
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1) show_statistics ;;
            2) list_services ;;
            3) service_details ;;
            4) toggle_service ;;
            5) control_service ;;
            0)
                clear_screen
                echo -e "${GREEN}Até logo!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Verificar privilégios e iniciar
check_root
main_menu