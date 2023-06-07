#!/usr/bin/env sh

docker buildx build \
  --platform linux/amd64 \
  --tag "niklucky/gitlab-docker:${1}" \
  --tag "niklucky/gitlab-docker:latest" \
  .

docker push niklucky/gitlab-docker:$1
docker push niklucky/gitlab-docker:latest