FROM golang:alpine as builder

MAINTAINER Takumi Takahashi <takumiiinn@gmail.com>

ARG NO_PROXY
ARG FTP_PROXY
ARG HTTP_PROXY
ARG HTTPS_PROXY

ARG ALPINE_MIRROR

ARG OPENSSL_URL=https://github.com/openssl/openssl.git
ARG OPENSSL_VER=OpenSSL_1_1_0h
ARG CURL_URL=https://github.com/curl/curl.git
ARG CURL_VER=curl-7_59_0
ARG HTTPPARSER_URL=https://github.com/nodejs/http-parser.git
ARG HTTPPARSER_VER=v2.8.1
ARG LIBGIT2_URL=https://github.com/libgit2/libgit2.git
ARG LIBGIT2_VER=v0.27.0

RUN echo Start! \
 && if [ "x${NO_PROXY}" != "x" ]; then export no_proxy="${NO_PROXY}"; fi \
 && if [ "x${FTP_PROXY}" != "x" ]; then export ftp_proxy="${FTP_PROXY}"; fi \
 && if [ "x${HTTP_PROXY}" != "x" ]; then export http_proxy="${HTTP_PROXY}"; fi \
 && if [ "x${HTTPS_PROXY}" != "x" ]; then export https_proxy="${HTTPS_PROXY}"; fi \
 && if [ "x${ALPINE_MIRROR}" != "x" ]; then sed -i -e "s@http://dl-cdn.alpinelinux.org/alpine@${ALPINE_MIRROR}@" /etc/apk/repositories; fi \
 && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && apk add --no-cache --virtual .build-deps gcc musl-dev linux-headers cmake make ninja autoconf automake libtool git perl python2 \
 && mkdir /src && mkdir /build \
 && git clone --depth 1 -b $OPENSSL_VER $OPENSSL_URL /openssl \
 && cd /openssl \
 && ./config --prefix=/usr no-async \
 && make -j $NPROC \
 && make -j $NPROC test \
 && make -j $NPROC install \
 && git clone --depth 1 -b $CURL_VER $CURL_URL /curl \
 && cd /curl \
 && ./buildconf \
 && ./configure --prefix=/usr \
 && make -j $NPROC \
 && make -j $NPROC test \
 && make -j $NPROC install \
 && git clone --depth 1 -b $HTTPPARSER_VER $HTTPPARSER_URL /http-parser \
 && cd /http-parser \
 && PREFIX=/usr make -j $NPROC \
 && PREFIX=/usr make -j $NPROC test \
 && PREFIX=/usr make -j $NPROC install \
 && git clone --depth 1 -b $LIBGIT2_VER $LIBGIT2_URL /libgit2 \
 && mkdir /libgit2/build && cd /libgit2/build \
 && cmake -G Ninja -D BUILD_SHARED_LIBS=OFF -D CMAKE_INSTALL_PREFIX=/usr .. \
 && cmake --build . \
 && ctest -V \
 && cmake --build . --target install \
 && apk del .build-deps \
 && echo Complete!
