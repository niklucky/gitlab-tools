#!/usr/bin/env sh

docker buildx build \
  --platform linux/amd64 \
  --tag "niklucky/docker-appcenter:${1}" \
  --tag "niklucky/docker-appcenter:latest" \
  .

docker push niklucky/docker-appcenter:$1
docker push niklucky/docker-appcenter:latest