#!/bin/bash
REPO=git@git.zhlh6.cn:yangxiongj/portainer.git
BRANCH=develop #TAG=v291-patch
test -z "$PRV_REPO"   || REPO=$PRV_REPO
test -z "$PRV_BRANCH" || BRANCH=$PRV_BRANCH

barge=/mnt/data # /mnt/mnt/data/dbox_ext
repimg=registry.cn-shenzhen.aliyuncs.com/infrastlabs/lang-replacement:replace
docker run -it --rm \
  -e REPO=$REPO -e BRANCH=$BRANCH \
  -v $barge$(pwd)/output2:/output $repimg

