#!/usr/bin/env sh

function publish() {
  v=$(cat version.txt)
  VERSION=$((v + 1))

  docker buildx build \
    --platform linux/amd64 \
    --tag "niklucky/gitlab-fastlane:${VERSION}" \
    --tag "niklucky/gitlab-fastlane:latest" \
    .

  docker push niklucky/gitlab-fastlane:$VERSION
  docker push niklucky/gitlab-fastlane:latest

  echo $VERSION > version.txt
}

"$@"