#!/usr/bin/env sh

DOCKER_CONTEXT_NAME=${PROJECT_NAME}_${CI_PIPELINE_IID}
DIR="./"
if [ "$PROJECT_DIR" ]; then
  DIR="${PROJECT_DIR}/"
fi

echo "Working directory: ${DIR}"

#
## Login to gitlab docker registry
#
function login() {
  echo "Login to docker registry: ${CI_REGISTRY} with $CI_REGISTRY_USER";

  echo -n $CI_REGISTRY_PASSWORD | \
  docker login \
      -u $CI_REGISTRY_USER \
      --password-stdin $CI_REGISTRY;
}

#
## Building docker image
function build() {
  login;

  echo "Docker build image: ${DOCKER_IMAGE}:${CI_PIPELINE_IID}";

  docker buildx build \
    --pull \
    --platform linux/amd64 \
    --build-arg "CHANNEL=$CI_ENVIRONMENT_NAME" \
    --build-arg "CI_COMMIT_BRANCH=$CI_COMMIT_BRANCH" \
    --build-arg "CI_COMMIT_SHA=$CI_COMMIT_SHA" \
    --file "${DIR}infrastructure/build/Dockerfile" \
    --cache-from "${DOCKER_IMAGE}:latest" \
    --tag "${DOCKER_IMAGE}:${CI_PIPELINE_IID}" \
    --tag "${DOCKER_IMAGE}:latest" \
    "${DIR}"
}

#
## Pushing built image to Docker registry
function push() {

  login;

  echo "Pushing image: ${DOCKER_IMAGE}:${CI_PIPELINE_IID}";

  docker push \
    "${DOCKER_IMAGE}:${CI_PIPELINE_IID}";

  docker push \
    "${DOCKER_IMAGE}:latest";
}

#
## Removing image on runner
function clean() {
  echo "Cleaning image: ${DOCKER_IMAGE}:${CI_PIPELINE_IID}";

  docker image rm \
    "${DOCKER_IMAGE}:${CI_PIPELINE_IID}" || true;  
}


function createSSHContext() {
  echo "Create SSH context: ${DOCKER_CONTEXT_NAME} (${REMOTE_SSH_HOST})";
  docker context create ${DOCKER_CONTEXT_NAME} --docker "host=ssh://${REMOTE_SSH_HOST}";
  docker context use ${DOCKER_CONTEXT_NAME};
}

function createTCPContext() {
  echo "Create TCP context: ${DOCKER_CONTEXT_NAME} (${DOCKER_SWARM_HOST})";

  docker context create ${DOCKER_CONTEXT_NAME} --description "Remote swarm" \
    --docker "host=${DOCKER_SWARM_HOST},ca=${DOCKER_SWARM_CACERT},cert=${DOCKER_SWARM_CERT},key=${DOCKER_SWARM_KEY}";

  docker context use ${DOCKER_CONTEXT_NAME};
}
function removeContext() {
  echo "Remove context: ${DOCKER_CONTEXT_NAME}";

  docker context use default;
  docker context rm ${DOCKER_CONTEXT_NAME};
}

function createNetwork() {
  docker \
    --context ${DOCKER_CONTEXT_NAME} \
    network \
    create \
    ${CI_PROJECT_NAMESPACE} \
    --driver overlay \
    --attachable \
    --internal \
    || true;

  docker \
    --context ${DOCKER_CONTEXT_NAME} \
    network \
    create \
    ${CI_PROJECT_NAMESPACE}_ext \
    --driver overlay \
    --attachable \
    || true;
}

function renderDockerCompose() {
  /usr/bin/docker-compose \
    -f "${DIR}infrastructure/deploy/docker-compose.yml" \
    -f "${DIR}infrastructure/deploy/${CI_ENVIRONMENT_NAME}.docker-compose.yml" \
    -p $PROJECT_NAME \
    config \
    | sed -E "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" \
          > "./compose.yml";
  }

function stackDeploy() {
  login;

  /usr/bin/docker-compose --file compose.yml pull

  docker \
    --context ${DOCKER_CONTEXT_NAME} \
    stack \
    deploy \
    --prune \
    --compose-file ./compose.yml \
    --with-registry-auth \
    ${PROJECT_NAME};
}

"$@"