FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    coreutils \
    bats

WORKDIR /app

COPY . /app

RUN chmod +x bin/health_monitor.sh

CMD ["bash"]