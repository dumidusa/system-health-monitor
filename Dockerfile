FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    coreutils \
    procps \
    bats \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app

RUN chmod +x bin/health_monitor.sh

CMD ["bash", "bin/health_monitor.sh"]
