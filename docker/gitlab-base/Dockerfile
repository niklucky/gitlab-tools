# syntax=docker.io/docker/dockerfile:1

FROM docker:latest

RUN apk update \
    && apk add \
    --no-cache \
    --virtual \
    .docker-compose-deps \
    curl \
    docker-cli \
    gcc \
    libc-dev \
    libffi-dev \
    make \
    openssl-dev \
    openssh-client \
    py-pip \
    py3-pip \
    python3 \
    python3-dev \
    git;

RUN pip install requests;

# Installing gitlab secure file downloader
RUN curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | sh

# List of useful scripts
COPY ./lib/notify_telegram.py /usr/local/bin/notify_telegram.py
COPY ./lib/docker_tools.sh /usr/local/bin/docker_tools.sh