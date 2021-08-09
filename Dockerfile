ARG PHP_VERSION="8.0.9"

FROM php:${PHP_VERSION}-alpine AS build

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG GRPC_VERSION="1.36.0"
ARG GRPC_WEB_VERSION="1.2.1"
ARG PROTOBUF_VERSION="3.15.5"

RUN apk add --no-cache --virtual .build-deps cmake make g++ git zlib-dev \
    && apk add go --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    && mkdir -p /protoc \
    && cd /protoc && git clone -b v${GRPC_VERSION} https://github.com/grpc/grpc \
    && cd /protoc/grpc && git submodule update --init \
    && cd /protoc/grpc && mkdir cmake/build && cd cmake/build && cmake ../.. && make protoc grpc_php_plugin \
    && mv /protoc/grpc/cmake/build/grpc_php_plugin /usr/local/bin/grpc_php_plugin \
    && ls -lah /protoc/grpc/cmake/build/third_party/protobuf/ \
    && mv /protoc/grpc/cmake/build/third_party/protobuf/protoc-3.14.0.0 /usr/local/bin/protoc \
    && cd /protoc && git clone https://github.com/spiral/php-grpc.git \
    && cd /protoc/php-grpc/cmd/rr-grpc && go get -t . && go install \
    && cd /protoc/php-grpc/cmd/protoc-gen-php-grpc && go get -t . && go install \
    && cd /protoc \
    && wget https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 \
    && mv protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 /usr/local/bin/protoc-gen-grpc-web \
    && chmod +x /usr/local/bin/protoc-gen-grpc-web \
    && curl -Ls https://git.io/twirphp > twirphp \
    && chmod +x ./twirphp \
    && ./twirphp -b /usr/local/bin \
    && chmod +x /usr/local/bin/protoc-gen-twirp_php \
    && rm -rf /protoc \
    && apk del .build-deps \
    && apk add make
