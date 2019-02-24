GO111MODULE := on
CGO_ENABLED := 1
export
GOENABLE_VERSION := 0.2.0
TARGETS := darwin/amd64,linux/amd64
GO_VERSION := 1.11.5
SHELL := /usr/bin/env bash

.PHONY: all
all: bashtion

.PHONY: bashtion
bashtion: out
	go build -v -o out/bashtion -buildmode=plugin .

.PHONY: plugin-test
plugin-test: bashtion cache/goenable.so
	@set -ex; \
		enable -f ./cache/goenable.so goenable; \
		goenable load ./out/bashtion output; \
		eval "$$output"; \
		bashtion load output namespace; \
		eval "$$output"; \
		namespace output ./lib/utils/colors.sh; \
		eval "$$output"; \
		colors color reset

.PHONY: dist
dist: out
	# cd /tmp: avoid updating go.mod files
	cd /tmp; \
		GO111MODULE=auto go get -u \
			github.com/johnstarich/goenable \
			github.com/johnstarich/xgo
	xgo \
		--buildmode=plugin \
		--dest=out \
		--go="${GO_VERSION}" \
		--image="johnstarich/xgo:1.11-nano" \
		--targets="${TARGETS}" \
		.
	# if not building in $GOPATH, fix output paths
	set -e; \
		if [[ -d out/github.com ]]; then \
			mv -fv out/github.com/johnstarich/* out/; \
			rm -rf out/github.com; \
		fi
	go run $$GOPATH/src/github.com/JohnStarich/goenable/cmd/rename_binaries.go ./out

out:
	mkdir out

cache:
	mkdir cache

cache/goenable.so: cache
	curl -fsSL "https://github.com/JohnStarich/goenable/releases/download/${GOENABLE_VERSION}/goenable-$$(uname -s)-$$(uname -m).so" > cache/goenable.so

.PHONY: clean
clean:
	rm -rf out cache

