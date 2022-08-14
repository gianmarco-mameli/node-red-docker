#!/bin/bash
export VERSION=$(grep -oE "\"node-red\": \"(\w*.\w*.\w*.\w*.\w*.)" package.json | cut -d\" -f4)
export IMAGE=nodered
export REGISTRY=registry.docker.local:5000
export PLATFORMS=linux/arm/v7 #,linux/arm/v6,linux/arm64

echo "#########################################################################"
echo "${IMAGE} version: ${VERSION}"
echo "#########################################################################"

docker run --privileged --rm tonistiigi/binfmt --install all

docker buildx create --use --name ${IMAGE}_builder --config=../buildkitd.toml

docker buildx build --builder ${IMAGE}_builder --push --progress plain \
    --file Dockerfile \
    --build-arg VERSION=${VERSION} \
    --build-arg BUILD_DATE="$(date +"%Y-%m-%dT%H:%M:%SZ")" \
    --platform ${PLATFORMS} \
    --tag ${REGISTRY}/${IMAGE}:${VERSION} \
    --tag ${REGISTRY}/${IMAGE}:latest .