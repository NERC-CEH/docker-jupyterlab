#!/bin/bash
set -e

# echo "Fetching recent git history"
# git fetch --shallow-exclude 0.30.0
# git repack -d
# git fetch --deepen=1
IMAGE="jupyterlab"
GIT_DESCRIBE=`git describe --tags --always`
echo "git describe $GIT_DESCRIBE"

docker build -f build/Dockerfile -t nerc/$IMAGE:latest .
docker tag nerc/$IMAGE:latest nerc/$IMAGE:$GIT_DESCRIBE

echo "Attempting to push image..."
docker push nerc/$IMAGE --all-tags
