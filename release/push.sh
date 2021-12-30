#!/bin/sh

cd "$(dirname "$0")"
set -e

echo "REMEMBER: Login using 'docker login ghcr.io -u USERNAME -p TOKEN'"
docker build -t ghcr.io/fcapovilla/agregat:${1:-latest} -f Dockerfile ..
docker push ghcr.io/fcapovilla/agregat:${1:-latest}
