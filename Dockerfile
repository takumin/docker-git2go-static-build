FROM ubuntu as builder

MAINTAINER Takumi Takahashi <takumiiinn@gmail.com>

ARG NO_PROXY
ARG FTP_PROXY
ARG HTTP_PROXY
ARG HTTPS_PROXY

ARG UBUNTU_MIRROR="http://jp.archive.ubuntu.com/ubuntu"

ARG ZLIB_URL=https://github.com/madler/zlib.git
ARG ZLIB_VER=v1.2.11
ARG OPENSSL_URL=https://github.com/openssl/openssl.git
ARG OPENSSL_VER=OpenSSL_1_1_0h
ARG LIBSSH2_URL=https://github.com/libssh2/libssh2.git
ARG LIBSSH2_VER=libssh2-1.8.0
ARG CURL_URL=https://github.com/curl/curl.git
ARG CURL_VER=curl-7_59_0
ARG HTTPPARSER_URL=https://github.com/nodejs/http-parser.git
ARG HTTPPARSER_VER=v2.8.1
ARG LIBGIT2_URL=https://github.com/libgit2/libgit2.git
ARG LIBGIT2_VER=v0.27.0

RUN echo Start! \
 && APT_PACKAGES="gcc g++ make ninja-build cmake autoconf automake libtool pkg-config git ca-certificates python" \
 && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && if [ "x${NO_PROXY}" != "x" ]; then export no_proxy="${NO_PROXY}"; fi \
 && if [ "x${FTP_PROXY}" != "x" ]; then export ftp_proxy="${FTP_PROXY}"; fi \
 && if [ "x${HTTP_PROXY}" != "x" ]; then export http_proxy="${HTTP_PROXY}"; fi \
 && if [ "x${HTTPS_PROXY}" != "x" ]; then export https_proxy="${HTTPS_PROXY}"; fi \
 && echo "deb ${UBUNTU_MIRROR} xenial          main restricted universe multiverse" >  /etc/apt/sources.list \
 && echo "deb ${UBUNTU_MIRROR} xenial-updates  main restricted universe multiverse" >> /etc/apt/sources.list \
 && echo "deb ${UBUNTU_MIRROR} xenial-security main restricted universe multiverse" >> /etc/apt/sources.list \
 && export DEBIAN_FRONTEND="noninteractive" \
 && export DEBIAN_PRIORITY="critical" \
 && export DEBCONF_NONINTERACTIVE_SEEN="true" \
 && apt-get -y update \
 && apt-get -y dist-upgrade \
 && apt-get -y --no-install-recommends install ${APT_PACKAGES} \
 && apt-get clean autoclean \
 && apt-get autoremove --purge -y \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* \
 && mkdir /src && mkdir /bld \
 && git clone --depth 1 -b $ZLIB_VER $ZLIB_URL /src/zlib \
 && ln -s /src/zlib /bld/zlib && cd /bld/zlib \
 && ./configure --prefix=/usr \
 && make -j $NPROC \
 && make -j $NPROC install \
 && git clone --depth 1 -b $OPENSSL_VER $OPENSSL_URL /src/openssl \
 && mkdir /bld/openssl && cd /bld/openssl \
 && /src/openssl/config --prefix=/usr \
 && make -j $NPROC \
 && make -j $NPROC install \
 && git clone --depth 1 -b $LIBSSH2_VER $LIBSSH2_URL /src/libssh2 \
 && ln -s /src/libssh2 /bld/libssh2 && cd /bld/libssh2 \
 && ./buildconf \
 && ./configure --prefix=/usr \
 && make -j $NPROC \
 && make -j $NPROC install \
 && git clone --depth 1 -b $CURL_VER $CURL_URL /src/curl \
 && ln -s /src/curl /bld/curl && cd /bld/curl \
 && ./buildconf \
 && ./configure --prefix=/usr --with-libssh2 \
 && make -j $NPROC \
 && make -j $NPROC install \
 && git clone --depth 1 -b $HTTPPARSER_VER $HTTPPARSER_URL /src/http-parser \
 && ln -s /src/http-parser /bld/http-parser && cd /bld/http-parser \
 && PREFIX=/usr make -j $NPROC \
 && PREFIX=/usr make -j $NPROC install \
 && git clone --depth 1 -b $LIBGIT2_VER $LIBGIT2_URL /src/libgit2 \
 && mkdir /bld/libgit2 && cd /bld/libgit2 \
 && cmake -G Ninja -D BUILD_SHARED_LIBS=OFF -D CMAKE_INSTALL_PREFIX=/usr /src/libgit2 \
 && cmake --build . \
 && cmake --build . --target install \
 && echo Complete!
