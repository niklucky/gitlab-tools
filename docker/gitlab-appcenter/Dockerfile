FROM node:20-alpine

RUN npm install -g appcenter-cli

RUN apk update && \
    apk add --no-cache --virtual \
    curl \
    py-pip \
    py3-pip \
    python3 \
    python3-dev \
    git

RUN pip install requests;

COPY ./lib/notify_telegram_codepush.js /usr/local/bin/notify_telegram_codepush.js
