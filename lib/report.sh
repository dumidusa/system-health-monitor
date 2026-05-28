#!/usr/bin/env bash
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

status_color(){
    local value="$1"
    local threshold="$2"
    local warn_at=$(( threshold - 10 ))

    if (( value >= threshold )); then
    echo -e "${RED}"
    elif (( value >= warn_at )); then
        echo -e "${YELLOW}"
    else 
    echo -e "${GREEN}"
    fi
}

print_header() {
    echo -e "\n${BOLD}${CYAN}******************************************"
    echo -e " SYSTEM HEALTH MONITOR - $(date '+%H:%M:%S')\n"
    echo -e "******************************************${RETEST}\n"

}

print_matric(){
    local label="$1"
    local value="$2"
    local unit="$3"
    local threshold="$4"
    local color
    color=$(status_color "$value" "$threshold")
    printf "  %-18s ${color}%3d%s${RESET}  (threshold: %d%s)\n" \
    "$label" "$value" "$unit" "$threshold" "$unit"
}


print_service_status(){
    local service="$1"
    local status="$2"
    if [[ "$status" == "up" ]]; then
        printf " %-20s ${GREEN}%-6s{RESET}\n" "$service" "UP"
    else
        printf " %-20s ${RED}%-6s{RESET}\n" "$service" "DOWN"
    fi
}

print_section(){
    echo -e "\n${BOLD}-- $1 --${RESET}"
}
 ####remove this aafter full code 
print_header
print_section "CPU"
print_matric "CPU Usage" 75 "%" 80
print_service_status "nginx" "up"