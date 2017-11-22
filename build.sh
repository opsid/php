#!/bin/bash
IMAGE="opsimages/php:nginx"
docker build --tag ${IMAGE} .
docker push $IMAGE
