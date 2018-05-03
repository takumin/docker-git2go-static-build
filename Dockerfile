FROM ubuntu as builder

MAINTAINER Takumi Takahashi <takumiiinn@gmail.com>

ARG NO_PROXY
ARG FTP_PROXY
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG APT_PROXY

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

ARG GO_VERSION=1.10.1
ARG GO_SHA256=72d820dec546752e5a8303b33b009079c15c2390ce76d67cf514991646c6127b

ARG GIT2GO_URL=https://github.com/libgit2/git2go.git

RUN echo Start! \
 && set -ex \
 && APT_PACKAGES="build-essential ninja-build cmake autoconf automake libtool pkg-config git wget ca-certificates python" \
 && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && . /etc/lsb-release \
 && if [ "x${NO_PROXY}" != "x" ]; then export no_proxy="${NO_PROXY}"; fi \
 && if [ "x${FTP_PROXY}" != "x" ]; then export ftp_proxy="${FTP_PROXY}"; fi \
 && if [ "x${HTTP_PROXY}" != "x" ]; then export http_proxy="${HTTP_PROXY}"; fi \
 && if [ "x${HTTPS_PROXY}" != "x" ]; then export https_proxy="${HTTPS_PROXY}"; fi \
 && if [ "x${APT_PROXY}" != "x" ]; then echo "// Apt Cache Proxy" > /etc/apt/apt.conf; fi \
 && if [ "x${APT_PROXY}" != "x" ]; then echo "Acquire::http::proxy \"${APT_PROXY}\";" >> /etc/apt/apt.conf; fi \
 && if [ "x${APT_PROXY}" != "x" ]; then echo "Acquire::https::proxy \"${APT_PROXY}\";" >> /etc/apt/apt.conf; fi \
 && echo "deb ${UBUNTU_MIRROR} ${DISTRIB_CODENAME}          main restricted universe multiverse" >  /etc/apt/sources.list \
 && echo "deb ${UBUNTU_MIRROR} ${DISTRIB_CODENAME}-updates  main restricted universe multiverse" >> /etc/apt/sources.list \
 && echo "deb ${UBUNTU_MIRROR} ${DISTRIB_CODENAME}-security main restricted universe multiverse" >> /etc/apt/sources.list \
 && export DEBIAN_FRONTEND="noninteractive" \
 && export DEBIAN_PRIORITY="critical" \
 && export DEBCONF_NONINTERACTIVE_SEEN="true" \
 && apt-get -y update \
 && apt-get -y dist-upgrade \
 && apt-get -y install --no-install-recommends ${APT_PACKAGES} \
 && apt-get clean autoclean \
 && apt-get autoremove --purge -y \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* \
 && mkdir /src && mkdir /bld \
 && git clone --depth 1 -b $ZLIB_VER $ZLIB_URL /src/zlib \
 && ln -s /src/zlib /bld/zlib && cd /bld/zlib \
 && ./configure \
 && make -j $NPROC \
 && make -j $NPROC install \
 && ldconfig \
 && git clone --depth 1 -b $OPENSSL_VER $OPENSSL_URL /src/openssl \
 && mkdir /bld/openssl && cd /bld/openssl \
 && /src/openssl/config zlib \
 && make -j $NPROC \
 && make -j $NPROC install \
 && ldconfig \
 && git clone --depth 1 -b $LIBSSH2_VER $LIBSSH2_URL /src/libssh2 \
 && ln -s /src/libssh2 /bld/libssh2 && cd /bld/libssh2 \
 && ./buildconf \
 && ./configure \
 && make -j $NPROC \
 && make -j $NPROC install \
 && ldconfig \
 && git clone --depth 1 -b $CURL_VER $CURL_URL /src/curl \
 && ln -s /src/curl /bld/curl && cd /bld/curl \
 && ./buildconf \
 && ./configure --with-ssl=/usr/local --with-libssh2=/usr/local \
 && make -j $NPROC \
 && make -j $NPROC install \
 && ldconfig \
 && git clone --depth 1 -b $HTTPPARSER_VER $HTTPPARSER_URL /src/http-parser \
 && ln -s /src/http-parser /bld/http-parser && cd /bld/http-parser \
 && make -j $NPROC \
 && make -j $NPROC install \
 && make -j $NPROC package \
 && install -D -m 0644 libhttp_parser.a /usr/local/lib/libhttp_parser.a \
 && ldconfig \
 && git clone --depth 1 -b $LIBGIT2_VER $LIBGIT2_URL /src/libgit2 \
 && mkdir /bld/libgit2 && cd /bld/libgit2 \
 && cmake -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo -D BUILD_SHARED_LIBS=ON /src/libgit2 \
 && cmake --build . \
 && cmake --build . --target install \
 && ldconfig \
 && rm -fr * \
 && cmake -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo -D BUILD_SHARED_LIBS=OFF /src/libgit2 \
 && cmake --build . \
 && cmake --build . --target install \
 && ldconfig \
 && cd / \
 && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
 && echo "${GO_SHA256} go${GO_VERSION}.linux-amd64.tar.gz" | sha256sum -c - \
 && tar -xvf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local \
 && export GOPATH="/go" \
 && export PATH="$GOPATH/bin:/usr/local/go/bin:$PATH" \
 && mkdir -p "$GOPATH/src" "$GOPATH/bin" \
 && mkdir -p "$GOPATH/src/github.com/libgit2" \
 && git clone --depth 1 $GIT2GO_URL "$GOPATH/src/github.com/libgit2/git2go" \
 && sed -i -e 's@ -I${SRCDIR}/vendor/libgit2/include@ -I/usr/local/include@' $GOPATH/src/github.com/libgit2/git2go/git_static.go \
 && sed -i -e 's@ -L${SRCDIR}/vendor/libgit2/build/@ -L/usr/local/lib@' $GOPATH/src/github.com/libgit2/git2go/git_static.go \
 && sed -i -e 's@${SRCDIR}/vendor/libgit2/build/libgit2.pc@/usr/local/lib/pkgconfig/libgit2.pc@' $GOPATH/src/github.com/libgit2/git2go/git_static.go \
 && cd "$GOPATH/src/github.com/libgit2/git2go" \
 && go install -tags "static" -ldflags "-extldflags '-static'" ./... \
 && go run -tags "static" -ldflags "-extldflags '-static'" script/check-MakeGitError-thread-lock.go \
 && go version \
 && echo Complete!

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

WORKDIR $GOPATH
