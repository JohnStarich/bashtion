GOENABLE_VERSION := 0.2.0

.PHONY: all
all: plugins

.PHONY: plugins
plugins: out
	set -ex; \
	for d in $$(ls plugins); do \
		go build -v -o out/"$$d" -buildmode=plugin ./plugins/"$$d"; \
	done

.PHONY: plugins-test
plugins-test: SHELL := /usr/bin/env bash
plugins-test: plugins cache/goenable.so
	@set -ex; \
		enable -f ./cache/goenable.so goenable; \
		goenable load ./out/namespace output; \
		eval "$$output"; \
		namespace output ./lib/utils/colors.sh; \
		eval "$$output"

out:
	mkdir out

cache:
	mkdir cache

cache/goenable.so: cache
	curl -fsSL "https://github.com/JohnStarich/goenable/releases/download/${GOENABLE_VERSION}/goenable-$$(uname -s)-$$(uname -m).so" > cache/goenable.so

.PHONY: clean
clean:
	rm -rf out cache

