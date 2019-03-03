GO111MODULE := on
CGO_ENABLED := 1
export
GOENABLE_VERSION := untagged-82eebf0d61329d0eca4a
TARGETS := darwin/amd64,linux/amd64
GO_VERSION := 1.11.5
SHELL := /usr/bin/env bash
CURRENT_DIST := $(shell uname -s)-$(shell uname -m)

.PHONY: all
all: bashtion

.PHONY: bashtion
bashtion: out
	go build -v -i -o out/bashtion-${CURRENT_DIST} -buildmode=plugin .
	ln -sf bashtion-${CURRENT_DIST} ./out/bashtion.so

.PHONY: lint
lint:
	shopt -s globstar nullglob; \
		shellcheck **/*.{sh,bash}

.PHONY: test
test: test-bashtion test-try-bashtion

.PHONY: test-bashtion
test-bashtion: goenable bashtion
	@set -ex; \
		BASHTION=./out/bashtion.so; \
		BASHTION_CACHE=./cache; \
		source ./bashtion.sh; \
		source test.sh

.PHONY: test-try-bashtion
test-try-bashtion: try-bashtion
	BASHTION=./out/bashtion.so; \
		source out/try-bashtion.sh

.PHONY: try-bashtion
try-bashtion: goenable bashtion out
	./build-standalone.sh

.PHONY: dist
dist: dist-try-bashtion dist-bashtion

.PHONY: dist-try-bashtion
dist-try-bashtion: try-bashtion
	rm out/bashtion-${CURRENT_DIST}

.PHONY: dist-bashtion
dist-bashtion: out
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

.PHONY: goenable
goenable: cache/goenable-${GOENABLE_VERSION}-${CURRENT_DIST}.so

cache/goenable-${GOENABLE_VERSION}-${CURRENT_DIST}.so: cache
	curl -fsSL -o cache/goenable-${GOENABLE_VERSION}-${CURRENT_DIST}.so "https://github.com/JohnStarich/goenable/releases/download/${GOENABLE_VERSION}/goenable-${CURRENT_DIST}.so"

.PHONY: clean
clean:
	rm -rf out cache


.PHONY: plugin-test
plugin-test: bashtion goenable
	@set -ex; \
		enable -f ./cache/goenable-${GOENABLE_VERSION}-${CURRENT_DIST}.so goenable; \
		goenable load ./out/bashtion-${CURRENT_DIST} output; \
		eval "$$output"; \
		bashtion load output namespace; \
		eval "$$output"; \
		namespace output ./lib/utils/colors.sh; \
		eval "$$output"; \
		colors color reset
	@set -ex; \
		source bashtion.sh; \
		import colors
	@set -ex; \
		source bashtion.sh; \
		function hey() { return 1; }; \
		function hi() { hey; }; \
		hi
