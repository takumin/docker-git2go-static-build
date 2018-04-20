ARGS ?= --no-cache --rm

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

ifneq (x${UBUNTU_MIRROR},x)
ARGS += --build-arg UBUNTU_MIRROR=${UBUNTU_MIRROR}
endif

.PHONY: build
build:
	@docker build $(ARGS) -t takumi/git2go-static .

.PHONY: run
run:
	@docker run -i -t --name git2go-static takumi/git2go-static

.PHONY: clean
clean:
ifneq (x$(shell docker ps -aq),x)
	@docker stop $(shell docker ps -aq)
	@docker rm $(shell docker ps -aq)
endif
ifneq (x$(shell docker images -f "dangling=true" -aq),x)
	@docker rmi $(shell docker images -f "dangling=true" -aq)
endif
ifneq (x$(shell docker images takumi/git2go-static -aq),x)
	@docker rmi takumi/git2go-static
endif
