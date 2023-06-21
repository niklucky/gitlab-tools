# Gitlab CI tools

## `docker/gitlab-base` — Docker container for a builds

In addition to base docker image inside this container will be installed:

* docker-compose
* python 3
* python libs: requests

### Publishing updates

```sh
./scripts/docker_publish.sh publish gitlab-base 
```

## `docker/gitlab-appcenter` - Docker container with Appcenter CLI

For code-push deployment in gitlab pipeline

### Publishing updates

```sh
./scripts/docker_publish.sh publish gitlab-appcenter 
```

## `docker/gitlab-fastlane` - Docker container with Fatslane & plugins

For Android deployment to Firebase App Distribution and Google Play

### Publishing updates

```sh
./scripts/docker_publish.sh publish gitlab-fastlane 
```