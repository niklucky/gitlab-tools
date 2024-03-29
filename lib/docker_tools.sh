#!/usr/bin/env sh

pn=${PROJECT_NAME}
if [ "$DOCKER_STACK_NAME" ]; then
  pn="${DOCKER_STACK_NAME}"
fi

PROJECT_NAME=${pn//\//_}

DOCKER_CONTEXT_NAME=${PROJECT_NAME}_${CI_PIPELINE_IID}

DIR="./"
CONTEXT_DIR="."
NETWORK="${CI_PROJECT_NAMESPACE}"

if [ "$PROJECT_DIR" ]; then
  DIR="${PROJECT_DIR}/"
fi

if [ "$DOCKER_CONTEXT_DIR" ]; then
  CONTEXT_DIR="${DOCKER_CONTEXT_DIR}/"
fi

if [ "$DOCKER_NETWORK" ]; then
  NETWORK="${DOCKER_NETWORK}"
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
    "${CONTEXT_DIR}"
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

function createRemoteContext() {
  echo "Creating context: ${REMOTE_SSH_HOST}"
  if [ "$REMOTE_SSH_HOST" ]; then
    createSSHContext
  else
    createTCPContext
  fi
}
function createSSHContext() {
  echo "Setting up SSH-keys";
  mkdir -p ~/.ssh;
  chmod 700 ~/.ssh;

  eval $(ssh-agent -s);

  cat $SSH_PRIVATE_KEY > ~/.ssh/id_rsa;
  chmod 400 ~/.ssh/id_rsa;
  ssh-add ~/.ssh/id_rsa;

echo "
Host *
  IdentitiesOnly yes
  PreferredAuthentications publickey
  ForwardAgent yes
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa
  UserKnownHostsFile /dev/null
" > ~/.ssh/config;

  chmod 600 ~/.ssh/config;


  echo "SSH config:"
  cat ~/.ssh/config

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
  echo "Creating network: ${NETWORK}"

  docker \
    --context ${DOCKER_CONTEXT_NAME} \
    network \
    create \
    ${NETWORK} \
    --driver overlay \
    --attachable \
    --internal \
    || true;
}

function copyDockerCompose() {
  cp "${DIR}infrastructure/deploy/docker-compose.yml" \
     "./compose.yml";
  }

function stackDeploy() {
  login;

  docker compose --file compose.yml pull

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