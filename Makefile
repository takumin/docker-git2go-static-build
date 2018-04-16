ARGS ?= --no-cache

ifneq (x${NO_PROXY},x)
ARGS += --build-arg NO_PROXY=${NO_PROXY}
endif

ifneq (x${FTP_PROXY},x)
ARGS += --build-arg FTP_PROXY=${FTP_PROXY}
endif

ifneq (x${HTTP_PROXY},x)
ARGS += --build-arg HTTP_PROXY=${HTTP_PROXY}
endif

ifneq (x${HTTPS_PROXY},x)
ARGS += --build-arg HTTPS_PROXY=${HTTPS_PROXY}
endif

ifneq (x${ALPINE_MIRROR},x)
ARGS += --build-arg ALPINE_MIRROR=${ALPINE_MIRROR}
endif

.PHONY: build
build:
	@docker build $(ARGS) -t takumi/git2go-static .

.PHONY: run
run:
	@docker run --name git2go-static -d takumi/git2go-static

.PHONY: clean
clean:
	@docker rmi takumi/git2go-static
