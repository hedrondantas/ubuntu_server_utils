#!/bin/bash

# Script de Gerenciamento de Data e Hora para Ubuntu Server
# Requer privilégios de root

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para verificar se é root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script precisa ser executado como root!${NC}"
        echo "Use: sudo $0"
        exit 1
    fi
}

# Função para pausar e aguardar input
pause() {
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# Função para limpar tela
clear_screen() {
    clear
}

# Função para exibir cabeçalho
show_header() {
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     GERENCIADOR DE DATA E HORA - Ubuntu Server            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para verificar status do sistema
show_status() {
    show_header
    echo -e "${BLUE}═══ STATUS DO SISTEMA ═══${NC}"
    echo ""
    
    echo -e "${GREEN}Data e Hora do Sistema:${NC}"
    date
    echo ""
    
    echo -e "${GREEN}Data e Hora do Hardware (RTC):${NC}"
    hwclock --show 2>/dev/null || echo "Não disponível"
    echo ""
    
    echo -e "${GREEN}Informações do Timedatectl:${NC}"
    timedatectl status
    echo ""
    
    echo -e "${GREEN}Fuso Horário Atual:${NC}"
    timedatectl show --property=Timezone --value
    echo ""
    
    echo -e "${GREEN}Status do NTP:${NC}"
    if systemctl is-active --quiet systemd-timesyncd; then
        echo -e "${GREEN}✓ NTP está ativo${NC}"
    else
        echo -e "${RED}✗ NTP está inativo${NC}"
    fi
    echo ""
    
    pause
}

# Função para ajustar data
set_date() {
    show_header
    echo -e "${BLUE}═══ AJUSTAR DATA ═══${NC}"
    echo ""
    
    echo -e "${YELLOW}Data atual: $(date +%Y-%m-%d)${NC}"
    echo ""
    
    read -p "Digite o ANO (ex: 2024): " year
    read -p "Digite o MÊS (01-12): " month
    read -p "Digite o DIA (01-31): " day
    
    # Validação básica
    if [[ ! "$year" =~ ^[0-9]{4}$ ]] || [[ ! "$month" =~ ^(0[1-9]|1[0-2])$ ]] || [[ ! "$day" =~ ^(0[1-9]|[12][0-9]|3[01])$ ]]; then
        echo -e "${RED}Data inválida! Use o formato correto.${NC}"
        pause
        return
    fi
    
    # Desativar NTP temporariamente se estiver ativo
    ntp_was_active=false
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        ntp_was_active=true
        timedatectl set-ntp false
        echo -e "${YELLOW}NTP desativado temporariamente...${NC}"
    fi
    
    # Ajustar data
    date_string="${year}-${month}-${day}"
    if timedatectl set-time "$date_string" 2>/dev/null; then
        echo -e "${GREEN}✓ Data ajustada com sucesso para: $date_string${NC}"
    else
        echo -e "${RED}✗ Erro ao ajustar data!${NC}"
    fi
    
    # Reativar NTP se estava ativo
    if [ "$ntp_was_active" = true ]; then
        timedatectl set-ntp true
        echo -e "${YELLOW}NTP reativado.${NC}"
    fi
    
    pause
}

# Função para ajustar hora
set_time() {
    show_header
    echo -e "${BLUE}═══ AJUSTAR HORA ═══${NC}"
    echo ""
    
    echo -e "${YELLOW}Hora atual: $(date +%H:%M:%S)${NC}"
    echo ""
    
    read -p "Digite a HORA (00-23): " hour
    read -p "Digite os MINUTOS (00-59): " minute
    read -p "Digite os SEGUNDOS (00-59): " second
    
    # Validação básica
    if [[ ! "$hour" =~ ^([01][0-9]|2[0-3])$ ]] || [[ ! "$minute" =~ ^[0-5][0-9]$ ]] || [[ ! "$second" =~ ^[0-5][0-9]$ ]]; then
        echo -e "${RED}Hora inválida! Use o formato correto.${NC}"
        pause
        return
    fi
    
    # Desativar NTP temporariamente se estiver ativo
    ntp_was_active=false
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        ntp_was_active=true
        timedatectl set-ntp false
        echo -e "${YELLOW}NTP desativado temporariamente...${NC}"
    fi
    
    # Ajustar hora
    time_string="${hour}:${minute}:${second}"
    if timedatectl set-time "$time_string" 2>/dev/null; then
        echo -e "${GREEN}✓ Hora ajustada com sucesso para: $time_string${NC}"
    else
        echo -e "${RED}✗ Erro ao ajustar hora!${NC}"
    fi
    
    # Reativar NTP se estava ativo
    if [ "$ntp_was_active" = true ]; then
        timedatectl set-ntp true
        echo -e "${YELLOW}NTP reativado.${NC}"
    fi
    
    pause
}

# Função para ajustar UTC
set_rtc_utc() {
    show_header
    echo -e "${BLUE}═══ AJUSTAR RELÓGIO DE HARDWARE (RTC) ═══${NC}"
    echo ""
    
    echo "O relógio de hardware (RTC) deve estar em UTC ou hora local?"
    echo ""
    echo "1) UTC (recomendado para servidores e dual-boot com Linux)"
    echo "2) Hora Local (necessário para dual-boot com Windows)"
    echo "3) Voltar"
    echo ""
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            timedatectl set-local-rtc 0
            echo -e "${GREEN}✓ RTC configurado para UTC${NC}"
            hwclock --systohc --utc
            echo -e "${GREEN}✓ Relógio de hardware sincronizado${NC}"
            ;;
        2)
            timedatectl set-local-rtc 1
            echo -e "${GREEN}✓ RTC configurado para Hora Local${NC}"
            hwclock --systohc --localtime
            echo -e "${GREEN}✓ Relógio de hardware sincronizado${NC}"
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    pause
}

# Função para listar fusos horários
list_timezones() {
    show_header
    echo -e "${BLUE}═══ FUSOS HORÁRIOS DISPONÍVEIS ═══${NC}"
    echo ""
    
    echo "Digite uma região para filtrar (ou deixe em branco para ver todos):"
    echo "Exemplos: America, Europe, Asia, Africa, Atlantic, Pacific"
    echo ""
    read -p "Região: " region
    
    echo ""
    if [ -z "$region" ]; then
        timedatectl list-timezones | less
    else
        timedatectl list-timezones | grep -i "$region" | less
    fi
    
    pause
}

# Função para definir fuso horário
set_timezone() {
    show_header
    echo -e "${BLUE}═══ AJUSTAR FUSO HORÁRIO ═══${NC}"
    echo ""
    
    echo -e "${YELLOW}Fuso horário atual: $(timedatectl show --property=Timezone --value)${NC}"
    echo ""
    
    echo "Selecione o método:"
    echo "1) Escolher da lista de fusos horários do Brasil"
    echo "2) Digitar fuso horário manualmente"
    echo "3) Buscar por região"
    echo "4) Voltar"
    echo ""
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            # Lista de fusos horários do Brasil
            echo ""
            echo -e "${GREEN}Fusos Horários do Brasil:${NC}"
            echo "1) America/Noronha (UTC-2) - Fernando de Noronha"
            echo "2) America/Belem (UTC-3) - Pará, Amapá"
            echo "3) America/Fortaleza (UTC-3) - Nordeste"
            echo "4) America/Recife (UTC-3) - Pernambuco"
            echo "5) America/Araguaina (UTC-3) - Tocantins"
            echo "6) America/Maceio (UTC-3) - Alagoas, Sergipe"
            echo "7) America/Bahia (UTC-3) - Bahia"
            echo "8) America/Sao_Paulo (UTC-3) - São Paulo, Rio, Sul, Sudeste"
            echo "9) America/Campo_Grande (UTC-4) - Mato Grosso do Sul"
            echo "10) America/Cuiaba (UTC-4) - Mato Grosso"
            echo "11) America/Santarem (UTC-3) - Oeste do Pará"
            echo "12) America/Porto_Velho (UTC-4) - Rondônia"
            echo "13) America/Boa_Vista (UTC-4) - Roraima"
            echo "14) America/Manaus (UTC-4) - Amazonas"
            echo "15) America/Eirunepe (UTC-5) - Oeste do Amazonas"
            echo "16) America/Rio_Branco (UTC-5) - Acre"
            echo ""
            
            read -p "Escolha um fuso horário (1-16): " tz_choice
            
            case $tz_choice in
                1) timezone="America/Noronha" ;;
                2) timezone="America/Belem" ;;
                3) timezone="America/Fortaleza" ;;
                4) timezone="America/Recife" ;;
                5) timezone="America/Araguaina" ;;
                6) timezone="America/Maceio" ;;
                7) timezone="America/Bahia" ;;
                8) timezone="America/Sao_Paulo" ;;
                9) timezone="America/Campo_Grande" ;;
                10) timezone="America/Cuiaba" ;;
                11) timezone="America/Santarem" ;;
                12) timezone="America/Porto_Velho" ;;
                13) timezone="America/Boa_Vista" ;;
                14) timezone="America/Manaus" ;;
                15) timezone="America/Eirunepe" ;;
                16) timezone="America/Rio_Branco" ;;
                *)
                    echo -e "${RED}Opção inválida!${NC}"
                    pause
                    return
                    ;;
            esac
            ;;
        2)
            read -p "Digite o fuso horário (ex: America/Sao_Paulo): " timezone
            ;;
        3)
            read -p "Digite a região para buscar (ex: America): " region
            echo ""
            echo -e "${GREEN}Fusos horários disponíveis:${NC}"
            timedatectl list-timezones | grep -i "$region" | nl
            echo ""
            read -p "Digite o fuso horário completo: " timezone
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            pause
            return
            ;;
    esac
    
    # Aplicar fuso horário
    if timedatectl set-timezone "$timezone" 2>/dev/null; then
        echo ""
        echo -e "${GREEN}✓ Fuso horário ajustado com sucesso para: $timezone${NC}"
        echo -e "${GREEN}✓ Data/Hora atual: $(date)${NC}"
    else
        echo ""
        echo -e "${RED}✗ Erro ao ajustar fuso horário! Verifique se o nome está correto.${NC}"
    fi
    
    pause
}

# Função para sincronizar relógio
sync_clock() {
    show_header
    echo -e "${BLUE}═══ SINCRONIZAR RELÓGIO ═══${NC}"
    echo ""
    
    echo "1) Sincronizar relógio do sistema com o hardware (RTC)"
    echo "2) Sincronizar relógio do hardware (RTC) com o sistema"
    echo "3) Forçar sincronização NTP"
    echo "4) Voltar"
    echo ""
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            hwclock --hctosys
            echo -e "${GREEN}✓ Sistema sincronizado com o relógio de hardware${NC}"
            ;;
        2)
            hwclock --systohc
            echo -e "${GREEN}✓ Relógio de hardware sincronizado com o sistema${NC}"
            ;;
        3)
            if systemctl is-active --quiet systemd-timesyncd; then
                systemctl restart systemd-timesyncd
                sleep 2
                timedatectl timesync-status 2>/dev/null
                echo -e "${GREEN}✓ Sincronização NTP forçada${NC}"
            else
                echo -e "${YELLOW}NTP está desativado. Deseja ativar? (s/n)${NC}"
                read -p "> " activate
                if [[ "$activate" == "s" || "$activate" == "S" ]]; then
                    timedatectl set-ntp true
                    sleep 2
                    echo -e "${GREEN}✓ NTP ativado e sincronizado${NC}"
                fi
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    pause
}

# Função para ativar/desativar NTP
toggle_ntp() {
    show_header
    echo -e "${BLUE}═══ CONFIGURAR NTP ═══${NC}"
    echo ""
    
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        echo -e "${GREEN}Status atual: NTP está ATIVO${NC}"
        echo ""
        echo "1) Desativar NTP"
        echo "2) Reiniciar serviço NTP"
        echo "3) Ver status detalhado do NTP"
        echo "4) Voltar"
    else
        echo -e "${RED}Status atual: NTP está INATIVO${NC}"
        echo ""
        echo "1) Ativar NTP"
        echo "2) Ver status detalhado do NTP"
        echo "3) Voltar"
    fi
    
    echo ""
    read -p "Escolha uma opção: " choice
    
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        case $choice in
            1)
                timedatectl set-ntp false
                echo -e "${YELLOW}✓ NTP desativado${NC}"
                ;;
            2)
                systemctl restart systemd-timesyncd
                echo -e "${GREEN}✓ Serviço NTP reiniciado${NC}"
                ;;
            3)
                echo ""
                timedatectl timesync-status 2>/dev/null
                echo ""
                systemctl status systemd-timesyncd --no-pager
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                ;;
        esac
    else
        case $choice in
            1)
                timedatectl set-ntp true
                echo -e "${GREEN}✓ NTP ativado${NC}"
                sleep 2
                timedatectl timesync-status 2>/dev/null
                ;;
            2)
                echo ""
                systemctl status systemd-timesyncd --no-pager
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                ;;
        esac
    fi
    
    pause
}

# Menu principal
main_menu() {
    while true; do
        show_header
        echo -e "${GREEN}MENU PRINCIPAL${NC}"
        echo ""
        echo " 1) Verificar status de data e hora"
        echo " 2) Ajustar data (ano, mês, dia)"
        echo " 3) Ajustar hora (hora, minuto, segundo)"
        echo " 4) Configurar relógio de hardware (UTC/Local)"
        echo " 5) Listar fusos horários disponíveis"
        echo " 6) Ajustar fuso horário"
        echo " 7) Sincronizar relógio"
        echo " 8) Configurar NTP (ativar/desativar)"
        echo " 9) Sair"
        echo ""
        
        read -p "Escolha uma opção: " option
        
        case $option in
            1) show_status ;;
            2) set_date ;;
            3) set_time ;;
            4) set_rtc_utc ;;
            5) list_timezones ;;
            6) set_timezone ;;
            7) sync_clock ;;
            8) toggle_ntp ;;
            9)
                clear_screen
                echo -e "${GREEN}Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                pause
                ;;
        esac
    done
}

# Verificar privilégios de root e iniciar
check_root
main_menu