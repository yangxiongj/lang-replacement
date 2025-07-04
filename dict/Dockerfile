FROM golang:1.13.9-alpine3.10 as builder

# use go modules
ENV GO111MODULE=on
#ENV GOPROXY=https://goproxy.cn
WORKDIR /src
COPY ./src .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -o godiff -x -v -ldflags "-s -w $flags" ./diff/main.go; \
  go build -x -v -ldflags "-s -w $flags" ./

FROM alpine
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    TERM="xterm"
RUN domain="mirrors.aliyun.com"; \
  echo "http://$domain/alpine/v3.14/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.14/community" >> /etc/apk/repositories
    
RUN apk --update add \
      ca-certificates \
      curl wget bash jq \
      vim git \
      && rm -rf /tmp/src && rm -rf /var/cache/apk/*
WORKDIR /generate
RUN wget https://hub.fastgit.org/rinetd/transfer/releases/download/v1.0.2/transfer-v1.0.2-linux-amd64.tar.gz; \
  tar -zxf transfer-v1.0.2-linux-amd64.tar.gz && rm -f transfer-v1.0.2-linux-amd64.tar.gz
RUN wget https://hub.fastgit.org/covrom/xml2json/releases/download/1.0/xml2json; chmod +x xml2json  

#gitdiff.sh: dict容器未被替换?? #apk add sed
RUN apk --update add sed \
      && rm -rf /tmp/src && rm -rf /var/cache/apk/*

COPY --from=builder /src/lang-replacement /generate
COPY --from=builder /src/godiff /generate
ADD ./generate/tpl/ /generate/tpl/
ADD ./generate/gitdiff.sh /generate
# dictReplace.txt
ADD ./generate/dictReplace.txt /generate
ADD ./generate/dict_fications.txt /generate
ADD ./generate/dict_button_th_placeholer.txt /generate
ADD ./entry.sh /generate
RUN find /generate

# EXPOSE 80
ENV GENERATE_REPO="https://github.com/yangxiongj/portainer.git" \
    GENERATE_OUTPUT="portainer_zh.xml" \
    CMP1="2.31" \
    CMP2="develop"
ENTRYPOINT /generate/entry.sh
