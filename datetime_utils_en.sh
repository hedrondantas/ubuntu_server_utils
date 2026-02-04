#!/bin/bash

# Date and Time Management Script for Ubuntu Server
# Requires root privileges

# Colors for interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script needs to be run as root!${NC}"
        echo "Use: sudo $0"
        exit 1
    fi
}

# Function to pause and wait for input
pause() {
    echo ""
    read -p "Press ENTER to continue..."
}

# Function to clear screen
clear_screen() {
    clear
}

# Function to display header
show_header() {
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     DATE AND TIME MANAGER - Ubuntu Server                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Display current date and time
    echo -e "${YELLOW}Current Date and Time: $(date)${NC}"
    echo ""
}

# Function to check system status
show_status() {
    show_header
    echo -e "${BLUE}═══ SYSTEM STATUS ═══${NC}"
    echo ""
    
    echo -e "${GREEN}System Date and Time:${NC}"
    date
    echo ""
    
    echo -e "${GREEN}Hardware Clock (RTC):${NC}"
    hwclock --show 2>/dev/null || echo "Not available"
    echo ""
    
    echo -e "${GREEN}Timedatectl Information:${NC}"
    timedatectl status
    echo ""
    
    echo -e "${GREEN}Current Timezone:${NC}"
    timedatectl show --property=Timezone --value
    echo ""
    
    echo -e "${GREEN}NTP Status:${NC}"
    if systemctl is-active --quiet systemd-timesyncd; then
        echo -e "${GREEN}✓ NTP is active${NC}"
    else
        echo -e "${RED}✗ NTP is inactive${NC}"
    fi
    echo ""
    
    pause
}

# Function to set date
set_date() {
    show_header
    echo -e "${BLUE}═══ SET DATE ═══${NC}"
    echo ""
    
    echo -e "${YELLOW}Current date: $(date +%Y-%m-%d)${NC}"
    echo ""
    
    read -p "Enter the date (YYYY-MM-DD): " date_string
    
    # Basic validation
    if [[ ! "$date_string" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}Invalid date! Use the correct format (YYYY-MM-DD).${NC}"
        pause
        return
    fi
    
    # Disable NTP temporarily if it's active
    ntp_was_active=false
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        ntp_was_active=true
        timedatectl set-ntp false
        echo -e "${YELLOW}NTP disabled temporarily...${NC}"
    fi
    
    # Set date
    if timedatectl set-time "$date_string" 2>/dev/null; then
        echo -e "${GREEN}✓ Date successfully set to: $date_string${NC}"
    else
        echo -e "${RED}✗ Error setting date!${NC}"
    fi
    
    # Reactivate NTP if it was active
    if [ "$ntp_was_active" = true ]; then
        timedatectl set-ntp true
        echo -e "${YELLOW}NTP reactivated.${NC}"
    fi
    
    pause
}

# Function to set time
set_time() {
    show_header
    echo -e "${BLUE}═══ SET TIME ═══${NC}"
    echo ""
    
    echo -e "${YELLOW}Current time: $(date +%H:%M:%S)${NC}"
    echo ""
    
    read -p "Enter HOURS (00-23): " hour
    read -p "Enter MINUTES (00-59): " minute
    read -p "Enter SECONDS (00-59): " second
    
    # Basic validation
    if [[ ! "$hour" =~ ^([01][0-9]|2[0-3])$ ]] || [[ ! "$minute" =~ ^[0-5][0-9]$ ]] || [[ ! "$second" =~ ^[0-5][0-9]$ ]]; then
        echo -e "${RED}Invalid time! Use the correct format.${NC}"
        pause
        return
    fi
    
    # Disable NTP temporarily if it's active
    ntp_was_active=false
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        ntp_was_active=true
        timedatectl set-ntp false
        echo -e "${YELLOW}NTP disabled temporarily...${NC}"
    fi
    
    # Set time
    time_string="${hour}:${minute}:${second}"
    if timedatectl set-time "$time_string" 2>/dev/null; then
        echo -e "${GREEN}✓ Time successfully set to: $time_string${NC}"
    else
        echo -e "${RED}✗ Error setting time!${NC}"
    fi
    
    # Reactivate NTP if it was active
    if [ "$ntp_was_active" = true ]; then
        timedatectl set-ntp true
        echo -e "${YELLOW}NTP reactivated.${NC}"
    fi
    
    pause
}

# Function to set RTC to UTC or Local
set_rtc_utc() {
    show_header
    echo -e "${BLUE}═══ SET HARDWARE CLOCK (RTC) ═══${NC}"
    echo ""
    
    echo "Should the hardware clock (RTC) be in UTC or local time?"
    echo ""
    echo "1) UTC (recommended for servers and dual-boot with Linux)"
    echo "2) Local Time (necessary for dual-boot with Windows)"
    echo "3) Back"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            timedatectl set-local-rtc 0
            echo -e "${GREEN}✓ RTC set to UTC${NC}"
            hwclock --systohc --utc
            echo -e "${GREEN}✓ Hardware clock synchronized${NC}"
            ;;
        2)
            timedatectl set-local-rtc 1
            echo -e "${GREEN}✓ RTC set to Local Time${NC}"
            hwclock --systohc --localtime
            echo -e "${GREEN}✓ Hardware clock synchronized${NC}"
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
    
    pause
}

# Function to list timezones
list_timezones() {
    show_header
    echo -e "${BLUE}═══ AVAILABLE TIMEZONES ═══${NC}"
    echo ""
    
    echo "Enter a region to filter (or leave blank to see all):"
    echo "Examples: America, Europe, Asia, Africa, Atlantic, Pacific"
    echo ""
    read -p "Region: " region
    
    echo ""
    if [ -z "$region" ]; then
        timedatectl list-timezones | less
    else
        timedatectl list-timezones | grep -i "$region" | less
    fi
    
    pause
}

# Function to set timezone
set_timezone() {
    show_header
    echo -e "${BLUE}═══ SET TIMEZONE ═══${NC}"
    echo ""
    
    echo -e "${YELLOW}Current timezone: $(timedatectl show --property=Timezone --value)${NC}"
    echo ""
    
    echo "Select the method:"
    echo "1) Enter timezone manually"
    echo "2) Search by region"
    echo "3) Back"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            read -p "Enter the timezone (ex: America/New_York): " timezone
            ;;
        2)
            read -p "Enter the region to search (ex: America): " region
            echo ""
            echo -e "${GREEN}Available timezones:${NC}"
            timedatectl list-timezones | grep -i "$region" | nl
            echo ""
            read -p "Enter the complete timezone: " timezone
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            pause
            return
            ;;
    esac
    
    # Apply timezone
    if timedatectl set-timezone "$timezone" 2>/dev/null; then
        echo ""
        echo -e "${GREEN}✓ Timezone successfully set to: $timezone${NC}"
        echo -e "${GREEN}✓ Current date/time: $(date)${NC}"
    else
        echo ""
        echo -e "${RED}✗ Error setting timezone! Check if the name is correct.${NC}"
    fi
    
    pause
}

# Function to synchronize clock
sync_clock() {
    show_header
    echo -e "${BLUE}═══ SYNCHRONIZE CLOCK ═══${NC}"
    echo ""
    
    echo "1) Synchronize system clock with hardware (RTC)"
    echo "2) Synchronize hardware clock (RTC) with system"
    echo "3) Force NTP synchronization"
    echo "4) Back"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            hwclock --hctosys
            echo -e "${GREEN}✓ System synchronized with hardware clock${NC}"
            ;;
        2)
            hwclock --systohc
            echo -e "${GREEN}✓ Hardware clock synchronized with system${NC}"
            ;;
        3)
            if systemctl is-active --quiet systemd-timesyncd; then
                systemctl restart systemd-timesyncd
                sleep 2
                timedatectl timesync-status 2>/dev/null
                echo -e "${GREEN}✓ NTP synchronization forced${NC}"
            else
                echo -e "${YELLOW}NTP is disabled. Do you want to enable it? (y/n)${NC}"
                read -p "> " activate
                if [[ "$activate" == "y" || "$activate" == "Y" ]]; then
                    timedatectl set-ntp true
                    sleep 2
                    echo -e "${GREEN}✓ NTP enabled and synchronized${NC}"
                fi
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
    
    pause
}

# Function to toggle NTP
toggle_ntp() {
    show_header
    echo -e "${BLUE}═══ CONFIGURE NTP ═══${NC}"
    echo ""
    
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        echo -e "${GREEN}Current status: NTP is ACTIVE${NC}"
        echo ""
        echo "1) Disable NTP"
        echo "2) Restart NTP service"
        echo "3) View detailed NTP status"
        echo "4) Back"
    else
        echo -e "${RED}Current status: NTP is INACTIVE${NC}"
        echo ""
        echo "1) Enable NTP"
        echo "2) View detailed NTP status"
        echo "3) Back"
    fi
    
    echo ""
    read -p "Choose an option: " choice
    
    if timedatectl show --property=NTP --value | grep -q "yes"; then
        case $choice in
            1)
                timedatectl set-ntp false
                echo -e "${YELLOW}✓ NTP disabled${NC}"
                ;;
            2)
                systemctl restart systemd-timesyncd
                echo -e "${GREEN}✓ NTP service restarted${NC}"
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
                echo -e "${RED}Invalid option!${NC}"
                ;;
        esac
    else
        case $choice in
            1)
                timedatectl set-ntp true
                echo -e "${GREEN}✓ NTP enabled${NC}"
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
                echo -e "${RED}Invalid option!${NC}"
                ;;
        esac
    fi
    
    pause
}

# Main menu
main_menu() {
    while true; do
        show_header
        echo -e "${GREEN}MAIN MENU${NC}"
        echo ""
        echo " 1) Check date and time status"
        echo " 2) Set date (year, month, day)"
        echo " 3) Set time (hour, minute, second)"
        echo " 4) Set hardware clock (UTC/Local)"
        echo " 5) List available timezones"
        echo " 6) Set timezone"
        echo " 7) Synchronize clock"
        echo " 8) Configure NTP (enable/disable)"
        echo " 9) Exit"
        echo ""
        
        read -p "Choose an option: " option
        
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
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                pause
                ;;
        esac
    done
}

# Check root privileges and start
check_root
main_menu
