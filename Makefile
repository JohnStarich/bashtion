GOENABLE_VERSION := 0.2.0
TARGETS := darwin/amd64,linux/amd64
GO_VERSION := 1.11.5
DIST_PACKAGE := $(shell [[ -n "$${TRAVIS_COMMIT}" || "$${GO111MODULE}" == off ]] && echo . || echo github.com/johnstarich/bashtion/plugin)
SHELL := /usr/bin/env bash

.PHONY: all
all: bashtion

.PHONY: bashtion
bashtion: out
	go build -v -o out/bashtion -buildmode=plugin ./plugin

.PHONY: plugins-test
plugins-test: plugins cache/goenable.so
	@set -ex; \
		enable -f ./cache/goenable.so goenable; \
		goenable load ./out/namespace output; \
		eval "$$output"; \
		namespace output ./lib/utils/colors.sh; \
		eval "$$output"

.PHONY: dist
dist: out
	cd /tmp; go get github.com/karalabe/xgo  # avoid updating go.mod files
	@set -ex; \
		CGO_ENABLED=1 \
		GO111MODULE=on \
		xgo \
			--buildmode=plugin \
			--dest=out \
			--go="${GO_VERSION}" \
			--image="johnstarich/xgo:1.11-nano" \
			--targets="${TARGETS}" \
			${DIST_PACKAGE}

out:
	mkdir out

cache:
	mkdir cache

cache/goenable.so: cache
	curl -fsSL "https://github.com/JohnStarich/goenable/releases/download/${GOENABLE_VERSION}/goenable-$$(uname -s)-$$(uname -m).so" > cache/goenable.so

.PHONY: clean
clean:
	rm -rf out cache

