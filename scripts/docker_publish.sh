#!/usr/bin/env sh


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

docker buildx build \
  --platform linux/amd64 \
  --tag "niklucky/$IMAGE:${VERSION}" \
  --tag "niklucky/$IMAGE:latest" \
  --file docker/$IMAGE/Dockerfile \
  .

docker push niklucky/$IMAGE:$VERSION
docker push niklucky/$IMAGE:latest

echo $VERSION > $FILE

git add $FILE
git commit -m "Version $VERSION for $IMAGE"
