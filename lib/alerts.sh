#!/usr/bin/env bash
# Alert dispatchers — called only when a threshold is breached

send_slack_alert() {
  local message="$1"
  local severity="${2:-WARNING}"   # WARNING or CRITICAL

  [[ -z "$SLACK_WEBHOOK_URL" ]] && {
    echo "[alerts] SLACK_WEBHOOK_URL not set — skipping Slack alert" >&2
    return 1
  }

  local color
  [[ "$severity" == "CRITICAL" ]] && color="#E24B4A" || color="#EF9F27"

  local hostname
  hostname=$(hostname -f)
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

  local payload
  payload=$(cat <<EOF
{
  "attachments": [{
    "color": "${color}",
    "title": "[${severity}] Health alert — ${hostname}",
    "text": "${message}",
    "footer": "system-health-monitor • ${timestamp}",
    "mrkdwn_in": ["text"]
  }]
}
EOF
)

  curl -s -X POST \
    -H 'Content-type: application/json' \
    --data "$payload" \
    "$SLACK_WEBHOOK_URL" > /dev/null
}

send_email_alert() {
  local message="$1"
  local severity="${2:-WARNING}"
  local hostname
  hostname=$(hostname -f)

  command -v mail &>/dev/null || {
    echo "[alerts] 'mail' not available — skipping email alert" >&2
    return 1
  }

  echo "$message" | mail \
    -s "[${severity}] Health alert on ${hostname}" \
    "$ALERT_EMAIL"
}

dispatch_alert() {
  # Central dispatcher — reads ALERT_METHOD from config
  local message="$1"
  local severity="${2:-WARNING}"

  case "$ALERT_METHOD" in
    slack)  send_slack_alert "$message" "$severity" ;;
    email)  send_email_alert "$message" "$severity" ;;
    both)
      send_slack_alert "$message" "$severity"
      send_email_alert "$message" "$severity"
      ;;
    none)   : ;;  # silent — useful for testing
    *)      echo "[alerts] Unknown ALERT_METHOD: $ALERT_METHOD" >&2 ;;
  esac
}