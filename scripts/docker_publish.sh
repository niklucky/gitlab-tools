#!/usr/bin/env sh

function publish() {
  IMAGE=$1
  echo $IMAGE
  FILE=docker/$IMAGE/version.txt
  echo $FILE
  v=0

  if [ -f "$FILE" ]; then
    v=$(cat $FILE)
  fi

  echo $v
  VERSION=$((v + 1))

  # docker buildx build \
  #   --platform linux/amd64 \
  #   --tag "niklucky/gitlab-base:${VERSION}" \
  #   --tag "niklucky/gitlab-base:latest" \
  #   .

  # docker push niklucky/gitlab-base:$VERSION
  # docker push niklucky/gitlab-base:latest

  echo $VERSION > $FILE

  # git add $FILE
  # git commit -m "Version $VERSION for $IMAGE"
}

"$@"