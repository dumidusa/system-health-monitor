# System Health Monitor

A bash script that monitors CPU, memory, disk, and services on a Linux system. Sends alerts via Slack or email when thresholds are breached.

## Features

- CPU, memory, and disk usage monitoring
- Systemd service status checking
- Colour-coded terminal report
- Slack and email alerts
- Auto log rotation
- Configurable thresholds

## Requirements

- RHEL 9 / CentOS / Ubuntu
- bash 4+
- curl (for Slack alerts)
- Docker (optional, for containerised run)
- bats (for tests)

## Installation

```bash
git clone https://github.com/dumidusa/system-health-monitor.git
cd system-health-monitor
chmod +x bin/health_monitor.sh
```

## Configuration

Edit `config/config.cfg`:

```bash
CPU_THRESHOLD=80        # alert when CPU exceeds this %
MEM_THRESHOLD=85        # alert when memory exceeds this %
DISK_THRESHOLD=90       # alert when disk exceeds this %
SERVICES="nginx mysql ssh cron"   # services to monitor
ALERT_METHOD="none"     # slack, email, both, or none
SLACK_WEBHOOK_URL=""    # your Slack webhook URL
```

## Usage

### Option 1 — Run directly on your machine

```bash
# normal run with terminal report
bash bin/health_monitor.sh

# silent mode — no terminal output, just logs and alerts
bash bin/health_monitor.sh --silent

# use a custom config file
bash bin/health_monitor.sh --config /path/to/config.cfg
```

### Option 2 — Run with Docker

Docker runs your script inside a clean Linux environment without installing anything on your machine.

```bash
# Step 1 — build the image (only needed once or when code changes)
docker build -t system-health-monitor .

# Step 2 — run the app inside Linux container
docker run --rm system-health-monitor
```

To go inside the container and explore:

```bash
docker run --rm -it system-health-monitor bash
```

To pass Slack webhook without hardcoding secrets:

```bash
docker run --rm \
  -e SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  system-health-monitor
```

## Cron Setup

Run every 5 minutes on a Linux host:

```bash
*/5 * * * * /path/to/system-health-monitor/bin/health_monitor.sh --silent
```

Daily report at 8 AM:

```bash
0 8 * * * /path/to/system-health-monitor/bin/health_monitor.sh
```

## Alert Methods

| Method | Requirements    | Works in Docker |
| ------ | --------------- | --------------- |
| none   | nothing         | yes             |
| slack  | webhook URL     | yes             |
| email  | mailx on host   | no              |
| both   | webhook + mailx | partial         |

> Email alerts require mailx installed on the host machine.
> For containerised environments use Slack alerts instead.

## Project Structure

system-health-monitor/
├── bin/health_monitor.sh # main entry point
├── lib/
│ ├── collectors.sh # metric collection
│ ├── alerts.sh # Slack and email alerts
│ └── report.sh # terminal output
├── config/config.cfg # thresholds and settings
├── logs/ # auto-created log files
├── Dockerfile # containerised run
└── tests/ # bats test suite

## Author

Dumidu Sahan — [github.com/dumidusa](https://github.com/dumidusa)
