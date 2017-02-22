BIN_DIR = binaries

.PHONY=build
build: clean
	scripts/write-git-info
	pyinstaller --onefile --add-data cogctl/GITSHA:. --add-data cogctl/GITTAG:. bin/cogctl

clean:
	rm -Rf build
	rm -Rf dist

lint:
	flake8 --max-line-length=85 --max-complexity=10

test:
		pytest -vv \
	--cov-report=term:skip-covered \
	--cov-report=html \
	--cov=cogctl \
	--cov-fail-under=95

acceptance:
	bin/cucumber

all: clean lint test acceptance build

deps: python-deps ruby-deps

python-deps:
	pip install -r requirements.txt
	pip install -r requirements.build.txt

ruby-deps:
	bundle install --path=vendor --binstubs


PLATFORM ?= alpine
BUILD_HASH := $(shell git rev-parse HEAD)
DOCKER_TAG ?= cogctl-local-build-$(BUILD_HASH)
BINARY_NAME ?= cogctl-$(PLATFORM)-$(BUILD_HASH)
# Make an executable for Linux platform
exe: | $(BIN_DIR)
	docker build \
	--tag=$(DOCKER_TAG) \
	--label="git_commit=$(BUILD_HASH)" \
	--file Dockerfile.$(PLATFORM) . && \
	docker run \
	--volume "$(shell pwd)"/binaries:/binaries \
	--rm \
	$(DOCKER_TAG) \
	cp /usr/bin/cogctl /binaries/$(BINARY_NAME)

$(BIN_DIR):
	mkdir -p $@
