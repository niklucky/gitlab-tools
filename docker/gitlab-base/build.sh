#!/usr/bin/env sh

function publish() {
  v=$(cat version.txt)
  VERSION=$((v + 1))

  docker buildx build \
    --platform linux/amd64 \
    --tag "niklucky/gitlab-base:${VERSION}" \
    --tag "niklucky/gitlab-base:latest" \
    .

  docker push niklucky/gitlab-base:$VERSION
  docker push niklucky/gitlab-base:latest

  echo $VERSION > version.txt
}

"$@"