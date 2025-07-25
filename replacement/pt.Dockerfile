FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/lang-replacement:dict as bins
FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/lang-replacement:cache as cache

##PT-FRONTEND########################################
# ref: dvp-ci-mgr.ui-frontend
# FROM node:10.15.0-alpine AS builder
# ref: docs-devops_vuepress
FROM library/node:16-alpine AS builder
# FROM library/node:14.20.0-slim AS builder
LABEL maintainer="sam <sam@devcn.top>"

RUN domain="mirrors.aliyun.com" \
&& echo "http://$domain/alpine/v3.14/main" > /etc/apk/repositories \
&& echo "http://$domain/alpine/v3.14/community" >> /etc/apk/repositories \
&& apk update \
&& apk --no-cache add git bash curl wget jq build-base gcc g++ make python3 \
&& apk --no-cache add libpng-dev jpeg-dev autoconf libtool automake
# portainer: yarn install
# RUN apk add autoconf libtool libpng automake gcc

# ref ./Dockerfile >> deb9: EOF
# RUN domain="mirrors.163.com" \
#   && echo "deb http://$domain/debian/ stretch main contrib non-free" > /etc/apt/sources.list \
#   && echo "deb http://$domain/debian/ stretch-updates main contrib non-free">> /etc/apt/sources.list; \
#   \
#   echo 'apt update -qq && apt install -yq --no-install-recommends $@ && apt-get clean && rm -rf /var/lib/apt/lists/*; ' > /usr/local/bin/apt.sh \
#   && chmod +x /usr/local/bin/apt.sh
# RUN apt.sh \ git bash curl wget jq libpng*

#RUN \
#    # npm
#    npm -v; \
#    npm config set registry=https://registry.npm.taobao.org -g; \
#    npm config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass -g; \
#    yarn config set registry https://registry.npm.taobao.org -g; \
#    yarn config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass -g
RUN npm install -g grunt-cli;\
    npm install -g grunt;
# TODO: node_mods from res_repo
# ADD ./node_modules /.cache/node_modules
COPY --from=cache /.cache/node_modules /.cache/node_modules
ADD ./replacement/entry.sh /entry.sh
ADD ./replacement/conf/webpack/ /conf/webpack/
ADD ./replacement/conf/gruntfile.js /conf/gruntfile.js
COPY --from=bins /generate/lang-replacement /usr/local/bin/
WORKDIR /output
ENV \
    REPO="https://github.com/yangxiongj/portainer.git" \
    # TAG="2.9.1"
    # TAG="v291-patch"
    BRANCH="develop"
# VOLUME ["/data"]
# EXPOSE 8080
ENTRYPOINT ["/entry.sh"]

#############
#just lastStage build ##echo 123: force new build.
RUN echo node.ac.1234567; /entry.sh


##PT-BACKEND########################################
# PT/API
# FROM golang:1.13.9-alpine3.10 as api
# FROM golang:1.16.9-alpine3.14 as api
FROM golang:1.23-alpine3.21 as api
# use go modules
ENV GO111MODULE=on
#ENV GOPROXY=https://goproxy.cn

# Build
RUN domain="mirrors.aliyun.com" \
&& echo "http://$domain/alpine/v3.14/main" > /etc/apk/repositories \
&& echo "http://$domain/alpine/v3.14/community" >> /etc/apk/repositories \
&& apk add curl tree bash git 
#git: for build_ver

# Copy in the go src
WORKDIR /src
ENV \
    REPO="https://github.com/yangxiongj/portainer.git" \
    BRANCH="develop"
    # TAG="2.9.1"

# COPY . .
RUN echo golang.abc.0; \
  git clone --depth=1 -b ${BRANCH} ${REPO} pt0; cd pt0/api; ls -lh; \
  CGO_ENABLED=0 \
  go build -o portainer -v -ldflags "-s -w $flags" ./cmd/portainer/

##AGENT########################################
# FROM library/golang:1.13.9-alpine3.10 as api
FROM golang:1.23-alpine3.21 as agent
# use go modules
ENV GO111MODULE=on
#ENV GOPROXY=https://goproxy.cn
# Build
RUN domain="mirrors.aliyun.com" \
&& echo "http://$domain/alpine/v3.14/main" > /etc/apk/repositories \
&& echo "http://$domain/alpine/v3.14/community" >> /etc/apk/repositories \
&& apk add curl tree bash git upx
#git: for build_ver

# gojq 1.4M; goawk 1.9M;
RUN cd /tmp; \
  curl -fSL -O https://github.com/itchyny/gojq/releases/download/v0.12.7/gojq_v0.12.7_linux_amd64.tar.gz; \
  curl -fSL -O https://github.com/benhoyt/goawk/releases/download/v1.17.0/goawk_v1.17.0_linux_amd64.tar.gz; \
  mkdir -p unpack1; \
  tar -zxf gojq_v0.12.7_linux_amd64.tar.gz -C /tmp/unpack1 --strip-components 1; \
  tar -zxf goawk_v1.17.0_linux_amd64.tar.gz -C /tmp/unpack1; \
  ls -lh /tmp/unpack1

# Copy in the go src
WORKDIR /src
ENV \
    REPO="https://gitee.com/oopjava/fk-agent" \
    BRANCH="sam-custom"
    # TAG="2.9.1"
RUN echo agent.a.1234; \
  git clone --depth=1 -b ${BRANCH} ${REPO} agent0; cd agent0; ls -lh; \
  # 下载缺失的依赖模块
  go mod download gitee.com/g-devops/chisel; \
  # 下载所有依赖
  go mod download all; \
  # 验证依赖是否正确
  go mod verify; \
  # 清理缓存
  go clean -cache; \
  CGO_ENABLED=0 \
  go build -o agent -v -ldflags "-s -w $flags" ./cmd/agent/
RUN cd agent0; \
  seq=$(date +%Y%m%d |sed "s/^20//g"); echo "seq: $seq"; \
  rm -f /tmp/agent; upx -7 ./agent -o /tmp/agent; \
  cat env.conf |grep -v "^# \|^$" > /tmp/env.conf; \
  #v291-$seq
  cd /tmp; tar -zcvf /src/agent0/agent-v291.tar.gz agent env.conf

##########################################
# FROM portainer/portainer-ce:2.9.1-alpine
# FROM portainer/portainer-ce:2.30.1-alpine
FROM portainer/portainer-ce:2.30.1-alpine
RUN rm -rf /public /portainer
COPY --from=api /src/pt0/api/portainer /portainer
COPY --from=builder /output/portainer/dist/public/ /public/
# agent
COPY --from=agent /src/agent0/agent-v291.tar.gz /public/static/agent-v291.tar.gz
COPY --from=agent /tmp/unpack1/gojq /public/static/
COPY --from=agent /tmp/unpack1/goawk /public/static/
# COPY --from=agent /src/agent0/_deploy/binary_ins.sh /public/static/binary_ins.sh.tpl
ADD ./static/binary_ins.sh /public/static/binary_ins.sh.tpl

# tpl http://xxx/static/templates-2.0/templates-2.0.json
ADD ./static/templates-2.0 /public/static/templates-2.0
RUN ls -lh /public; ls -lh /public/static

