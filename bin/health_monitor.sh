#!/usr/bin/env bash

# Exit on error, treat unset variables as error, and fail pipelines if any command fails
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/config.cfg"
SILENT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --silent)   SILENT=true ;;
    --config)   CONFIG_FILE="$2"; shift ;;
    --help)
      echo "Usage: $(basename "$0") [--silent] [--config PATH]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

#load config and libraries
sorce "$CONFIG_FILE"
source "${SCRIPT_DIR}/../lib/collectors.sh"
source "${SCRIPT_DIR}/../lib/alert.sh"
source "${SCRIPT_DIR}/../lib/report.sh"

mkdir -p "$(dirname "$LOG_FILE")"

declare -A DISK_USAGE
for mount in $DISK_MOUNTS; do
DISK_USAGE["$mount"]=$(collect_disk "$mount")
done

declare -A SERVICE_USAGE
for svc in $SEVICES; do
    SERVICE_STATUS["$svc"]=$(collect_service "$svc")
done

