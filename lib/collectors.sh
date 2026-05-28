#!/usr/bin/env bash
collect_cpu(){
    if [[ -f /proc/stat ]]; then
        local cpu1 cpu2
        read -ra cpu1 < <(grep '^cpu' /proc/stat)
        sleep 1
        read -ra cpu2 < <(grep '^cpu' /proc/stat)

        local idle1=$(( cpu1[4] + cpu1[5] ))
        local total1=0
        for val in "${cpu1[@]:1}"; do (( total1 += val )); done

        local idle2=$(( cpu2[4] + cpu2[5] ))
        local total2=0
        for val in "${cpu2[@]:1}"; do (( total2 += val )); done

        local diff_idle=$(( idle2 -idle1 ))
        local diff_total=$(( total2 - total1 ))
        local diff_used=$(( diff_total - diff_idle ))

        echo $(( diff_used * 100 / diff_total ))

    else
        #macOs / fallback
        top -l 1 | grep "CPU usage" | awk '{print int($3)}'  
    fi
}
#for collect cpu func i use proc/stat for probability and return int cpu usage %

collect_memory() {
    free -m | awk '/^Mem:/ {
        total = $2
        available = $7
        used = total - available

        printf "%d", (used / total) * 100
    }'
}

collect_disk() {
    local mount="${1:-/}"
    df -P "$mount" 2>/dev/null \
        | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}
#accept a mount point , return int usage %

collect_service() {
    local service="$1"
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "UP"
    else 
        echo "down"
    fi   
}   #Accept a service name , reuturn "up" or "down"

collect_load_average(){
    #return 1min load avg
    awk '{print $1}' /proc/loadavg
}