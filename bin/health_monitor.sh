#!/usr/bin/env bash

set -euo pipefail

# -------------------------
# Paths
# -------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${BASE_DIR}/config/config.cfg"

# -------------------------
# Flags (parse BEFORE sourcing config)
# -------------------------
SILENT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --silent)
      SILENT=true
      ;;
    --config)
      CONFIG_FILE="$2"
      shift
      ;;
    --help)
      echo "Usage: $(basename "$0") [--silent] [--config PATH]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# -------------------------
# Load config + modules
# -------------------------
source "$CONFIG_FILE"
source "$BASE_DIR/lib/collectors.sh"
source "$BASE_DIR/lib/alerts.sh"
source "$BASE_DIR/lib/report.sh"

# Safe defaults for metrics
# -------------------------
CPU_USAGE="${CPU_USAGE:-0}"
MEM_USAGE="${MEM_USAGE:-0}"
LOAD_AVG="${LOAD_AVG:-0}"
CPU_THRESHOLD="${CPU_THRESHOLD:-90}"
MEM_THRESHOLD="${MEM_THRESHOLD:-90}"
DISK_THRESHOLD="${DISK_THRESHOLD:-90}"

# -------------------------
# Prepare logs
# -------------------------
mkdir -p "$(dirname "$LOG_FILE")"

# -------------------------
# Collect metrics
# -------------------------
declare -A DISK_USAGE
for mount in $DISK_MOUNTS; do
  DISK_USAGE["$mount"]=$(collect_disk "$mount")
done

declare -A SERVICE_STATUS
for svc in $SERVICES; do
  SERVICE_STATUS["$svc"]=$(collect_service "$svc")
done

# -------------------------
# Evaluate alerts
# -------------------------
ALERTS=()

if (( CPU_USAGE >= CPU_THRESHOLD )); then
  ALERTS+=("CPU usage ${CPU_USAGE}% exceeds threshold ${CPU_THRESHOLD}%")
fi

if (( MEM_USAGE >= MEM_THRESHOLD )); then
  ALERTS+=("Memory usage ${MEM_USAGE}% exceeds threshold ${MEM_THRESHOLD}%")
fi

for mount in "${!DISK_USAGE[@]}"; do
  disk_val="${DISK_USAGE[$mount]}"
  if (( disk_val >= DISK_THRESHOLD )); then
    ALERTS+=("Disk ${mount} at ${disk_val}% exceeds threshold ${DISK_THRESHOLD}%")
  fi
done

for svc in "${!SERVICE_STATUS[@]}"; do
  if [[ "${SERVICE_STATUS[$svc]}" == "DOWN" ]]; then
    ALERTS+=("Service '${svc}' is DOWN")
  fi
done

# -------------------------
# Report
# -------------------------
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

if [[ "$SILENT" == false ]]; then
  print_header

  print_section "CPU"
  print_metric "CPU usage" "$CPU_USAGE" "%" "$CPU_THRESHOLD"
  echo "Load average: $LOAD_AVG"

  print_section "Memory"
  print_metric "Memory usage" "$MEM_USAGE" "%" "$MEM_THRESHOLD"

  print_section "Disk"
  for mount in "${!DISK_USAGE[@]}"; do
    print_metric "$mount" "${DISK_USAGE[$mount]}" "%" "$DISK_THRESHOLD"
  done

  print_section "Services"
  for svc in "${!SERVICE_STATUS[@]}"; do
    print_service_status "$svc" "${SERVICE_STATUS[$svc]}"
  done

  if (( ${#ALERTS[@]} == 0 )); then
    echo -e "\n✓ All systems nominal\n"
  else
    echo -e "\n✗ ${#ALERTS[@]} alert(s) fired\n"
  fi
fi

# -------------------------
# Logging
# -------------------------
LOG_LINE="${TIMESTAMP} host=${HOSTNAME} cpu=${CPU_USAGE} mem=${MEM_USAGE} load=${LOAD_AVG}"

for mount in "${!DISK_USAGE[@]}"; do
  LOG_LINE+=" disk_${mount//\//_}=${DISK_USAGE[$mount]}"
done

for svc in "${!SERVICE_STATUS[@]}"; do
  LOG_LINE+=" svc_${svc}=${SERVICE_STATUS[$svc]}"
done

if (( ${#ALERTS[@]} > 0 )); then
  LOG_LINE+=" ALERT=\"${ALERTS[*]}\""
fi

echo "$LOG_LINE" >> "$LOG_FILE"

# -------------------------
# Log rotation (safe with flock)
# -------------------------
(
  flock -x 200
  tail -n "${LOG_MAX_LINES:-1000}" "$LOG_FILE" > "${LOG_FILE}.tmp" \
    && mv "${LOG_FILE}.tmp" "$LOG_FILE"
) 200>"${LOG_FILE}.lock"

# -------------------------
# Alerts
# -------------------------
if (( ${#ALERTS[@]} > 0 )); then
  ALERT_BODY="Host: ${HOSTNAME}\nTime: ${TIMESTAMP}\n\nIssues:\n"

  for alert in "${ALERTS[@]}"; do
    ALERT_BODY+=" - ${alert}\n"
  done

  SEVERITY="WARNING"

  for svc in "${!SERVICE_STATUS[@]}"; do
    if [[ "${SERVICE_STATUS[$svc]}" == "DOWN" ]]; then
      SEVERITY="CRITICAL"
    fi
  done

  if (( CPU_USAGE >= 95 || MEM_USAGE >= 95 )); then
    SEVERITY="CRITICAL"
  fi

  dispatch_alert "$ALERT_BODY" "$SEVERITY"
fi