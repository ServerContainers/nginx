#!/bin/sh -x

[ -z "$DOCKER_REGISTRY" ] && echo "error please specify docker-registry DOCKER_REGISTRY" && exit 1
IMG="$DOCKER_REGISTRY/nginx"

sed -i.bak 's/image: /image: '"$DOCKER_REGISTRY"'\//g' docker-compose.yml; rm docker-compose.yml.bak

PLATFORM="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

if [ -z ${DEBIAN_VERSION+x} ] || [ -z ${NGINX_VERSION+x} ]; then
  docker-compose build -q --pull --no-cache
  export DEBIAN_VERSION=$(docker run --rm -ti "$IMG" cat /etc/debian_version | tail -n1 | tr -d '\r')
  export NGINX_VERSION=$(docker run --rm -ti "$IMG" dpkg --list nginx-extras | grep '^ii' | sed 's/^[^0-9]*//g' | cut -d ' ' -f1 | sed 's/[+=]/_/g' | tr -d '\r')
fi

if echo "$@" | grep -v "force" 2>/dev/null >/dev/null; then
  echo "check if image was already build and pushed - skip check on release version"
  echo "$@" | grep -v "release" && docker pull "$IMG:d$DEBIAN_VERSION-ne$NGINX_VERSION" 2>/dev/null >/dev/null && echo "image already build" && exit 1
fi

docker buildx build -q --pull --no-cache --platform "$PLATFORM" -t "$IMG:d$DEBIAN_VERSION-ne$NGINX_VERSION" --push .

echo "$@" | grep "release" 2>/dev/null >/dev/null && echo ">> releasing new latest" && docker buildx build -q --pull --platform "$PLATFORM" -t "$IMG:latest" --push .

git checkout docker-compose.yml