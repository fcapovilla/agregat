#!/bin/sh

cd "$(dirname "$0")"
set -e

cd ..
echo "REMEMBER: Login using 'docker login docker.pkg.github.com -u USERNAME -p TOKEN'"
docker build -t docker.pkg.github.com/fcapovilla/agregat/agregat:${1:-latest} -f release/Dockerfile .
docker push docker.pkg.github.com/fcapovilla/agregat/agregat:${1:-latest}