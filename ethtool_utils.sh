#!/usr/bin/env bash

# ==============================
# ethtool-manager.sh
# Gerenciador interativo de ethtool
# ==============================

# ---------- Dependências ----------
command -v ethtool >/dev/null 2>&1 || {
  echo "Erro: ethtool não encontrado."
  exit 1
}

# ---------- Variáveis globais ----------
INTERFACES=()
SELECTED_IF=""
CURSOR=0

# ---------- Estilos ----------
BOLD=$(tput bold)
RESET=$(tput sgr0)
REV=$(tput rev)
CLEAR=$(tput clear)

# ---------- Teclas ----------
KEY_UP=$'\x1b[A'
KEY_DOWN=$'\x1b[B'
KEY_ESC=$'\x1b'
KEY_F5=$'\x1b[15~'
KEY_ENTER=""

# ---------- Utilidades ----------
pause() {
  echo
  read -rp "Pressione ENTER para continuar..."
}

get_interfaces() {
  mapfile -t INTERFACES < <(ls /sys/class/net | grep -v lo)
}

draw_header() {
  echo "${BOLD}Gerenciador ethtool${RESET}"
  echo "Use ↑ ↓ Enter | ESC para voltar | F5 para atualizar"
  echo "--------------------------------------------------"
}

read_key() {
  IFS= read -rsn1 key
  [[ $key == $'\x1b' ]] && read -rsn2 key2 && key+="$key2"
  echo "$key"
}

# ---------- Menu genérico ----------
menu_select() {
  local title="$1"
  local -n options=$2
  CURSOR=0

  while true; do
    $CLEAR
    draw_header
    echo "${BOLD}$title${RESET}"
    echo

    for i in "${!options[@]}"; do
      if [[ $i -eq $CURSOR ]]; then
        echo "${REV}> ${options[$i]}${RESET}"
      else
        echo "  ${options[$i]}"
      fi
    done

    key=$(read_key)

    case "$key" in
      "$KEY_UP")
        ((CURSOR--))
        [[ $CURSOR -lt 0 ]] && CURSOR=$((${#options[@]} - 1))
        ;;
      "$KEY_DOWN")
        ((CURSOR++))
        [[ $CURSOR -ge ${#options[@]} ]] && CURSOR=0
        ;;
      "$KEY_F5")
        return 99
        ;;
      "")
        return $CURSOR
        ;;
      "$KEY_ESC")
        return 255
        ;;
    esac
  done
}

# ---------- Detalhes da interface ----------
show_interface_details() {
  echo "${BOLD}Interface:${RESET} $SELECTED_IF"
  ethtool "$SELECTED_IF" 2>/dev/null | sed 's/^/  /'
  echo "--------------------------------------------------"
}

# ---------- Submenus ----------
show_stats() {
  $CLEAR
  echo "${BOLD}Estatísticas da interface${RESET}"
  echo "Mostra contadores RX/TX, erros e drops."
  echo
  ethtool -S "$SELECTED_IF"
  pause
}

autoneg_menu() {
  $CLEAR
  echo "${BOLD}Auto-negociação${RESET}"
  echo "Controla negociação automática de velocidade e duplex."
  echo
  ethtool "$SELECTED_IF" | grep -E "Auto-negotiation|Speed|Duplex"
  echo
  read -rp "Ativar autonegociação? (s/n): " r
  [[ $r == "s" ]] && ethtool -s "$SELECTED_IF" autoneg on
  [[ $r == "n" ]] && ethtool -s "$SELECTED_IF" autoneg off
  pause
}

blink_led() {
  $CLEAR
  echo "${BOLD}Piscar LED${RESET}"
  echo "Ajuda a identificar fisicamente a interface."
  echo
  read -rp "Tempo em segundos (ex: 10): " t
  ethtool -p "$SELECTED_IF" "$t"
  pause
}

detect_link() {
  while true; do
    $CLEAR
    echo "${BOLD}Detecção de link físico${RESET}"
    echo "Atualiza com F5."
    echo
    ethtool "$SELECTED_IF" | grep "Link detected"
    key=$(read_key)
    [[ $key == "$KEY_ESC" ]] && break
  done
}

offloads_menu() {
  $CLEAR
  echo "${BOLD}Offloads${RESET}"
  echo "Acelera ou reduz carga da CPU (TSO, GRO, LRO)."
  echo
  ethtool -k "$SELECTED_IF"
  echo
  read -rp "Digite (ex: gro off): " opt val
  ethtool -K "$SELECTED_IF" "$opt" "$val"
  pause
}

ring_buffer() {
  $CLEAR
  echo "${BOLD}Ring Buffer${RESET}"
  echo "Buffers RX/TX maiores reduzem perda de pacotes."
  echo
  ethtool -g "$SELECTED_IF"
  echo
  read -rp "RX: " rx
  read -rp "TX: " tx
  ethtool -G "$SELECTED_IF" rx "$rx" tx "$tx"
  pause
}

channels_menu() {
  $CLEAR
  echo "${BOLD}Filas RX/TX${RESET}"
  echo "Multiqueue melhora throughput em CPUs multi-core."
  echo
  ethtool -l "$SELECTED_IF"
  echo
  read -rp "Combined: " c
  ethtool -L "$SELECTED_IF" combined "$c"
  pause
}

irq_tuning() {
  $CLEAR
  echo "${BOLD}Coalescência de IRQ${RESET}"
  echo "Reduz interrupções, pode aumentar latência."
  echo
  ethtool -c "$SELECTED_IF"
  echo
  read -rp "rx-usecs: " v
  ethtool -C "$SELECTED_IF" rx-usecs "$v"
  pause
}

rss_menu() {
  $CLEAR
  echo "${BOLD}RSS / Hashing${RESET}"
  echo "Distribui tráfego entre filas RX."
  echo
  ethtool -x "$SELECTED_IF"
  pause
}

self_test() {
  $CLEAR
  echo "${BOLD}Testes da placa${RESET}"
  echo "Executa autotestes (online)."
  echo
  ethtool -t "$SELECTED_IF" online
  pause
}

eeprom_menu() {
  $CLEAR
  echo "${BOLD}EEPROM${RESET}"
  echo "⚠ RISCO: leitura direta da EEPROM."
  echo
  read -rp "Deseja prosseguir? (s/n): " r
  [[ $r == "s" ]] && ethtool -e "$SELECTED_IF"
  pause
}

driver_info() {
  $CLEAR
  echo "${BOLD}Driver e Firmware${RESET}"
  echo
  ethtool -i "$SELECTED_IF"
  pause
}

wol_menu() {
  $CLEAR
  echo "${BOLD}Wake-on-LAN${RESET}"
  echo
  ethtool "$SELECTED_IF" | grep Wake-on
  echo
  read -rp "Ativar WoL? (s/n): " r
  [[ $r == "s" ]] && ethtool -s "$SELECTED_IF" wol g
  [[ $r == "n" ]] && ethtool -s "$SELECTED_IF" wol d
  pause
}

eee_menu() {
  $CLEAR
  echo "${BOLD}Energy Efficient Ethernet${RESET}"
  echo
  ethtool --show-eee "$SELECTED_IF"
  echo
  read -rp "Desativar EEE? (s/n): " r
  [[ $r == "s" ]] && ethtool --set-eee "$SELECTED_IF" eee off
  pause
}

pause_frames() {
  $CLEAR
  echo "${BOLD}Pause Frames${RESET}"
  echo
  ethtool -a "$SELECTED_IF"
  pause
}

# ---------- Menu da interface ----------
interface_menu() {
  local options=(
    "Estatísticas"
    "Auto-negociação"
    "Piscar LED"
    "Detectar link físico"
    "Offloads"
    "Ring buffer"
    "Filas RX/TX"
    "Coalescência IRQ"
    "RSS / Hashing"
    "Testes da placa"
    "EEPROM"
    "Driver e firmware"
    "Wake-on-LAN"
    "EEE"
    "Pause Frames"
  )

  while true; do
    $CLEAR
    show_interface_details

    menu_select "Menu da interface" options
    r=$?

    [[ $r -eq 255 ]] && break

    case $r in
      0) show_stats ;;
      1) autoneg_menu ;;
      2) blink_led ;;
      3) detect_link ;;
      4) offloads_menu ;;
      5) ring_buffer ;;
      6) channels_menu ;;
      7) irq_tuning ;;
      8) rss_menu ;;
      9) self_test ;;
      10) eeprom_menu ;;
      11) driver_info ;;
      12) wol_menu ;;
      13) eee_menu ;;
      14) pause_frames ;;
    esac
  done
}

# ---------- Menu principal ----------
while true; do
  get_interfaces
  menu_select "Selecione a interface" INTERFACES
  r=$?

  [[ $r -eq 255 ]] && exit 0
  [[ $r -eq 99 ]] && continue

  SELECTED_IF="${INTERFACES[$r]}"
  interface_menu
done
