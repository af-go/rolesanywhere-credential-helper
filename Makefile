VERSION=1.0.5-1

SHELL = /bin/bash

BINARY_NAME := aws_signing_helper

GOCMD :=go
GOBUILD :=$(GOCMD) build
SWAGGERCMD := swagger

GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/bin
GODIST=$(GOBASE)/dist

$(info argument BUILD_VERSION: ${BUILD_VERSION})
$(info argument GOPROXY: ${GOPROXY})

# export GOPROXY 
GO_PROXY := GOPROXY=${GOPROXY}

PKGS := $(shell ${GO_PROXY} go list ./... | grep -v vendor | grep -v testing )
GOSECFLAGS := -fmt=json -out=gosec-results.json ./...
FILES := $(shell find . -type f -name '*.go' ! -path "./vendor/*")

LDFLAGS += \
    -w -s -extldflags 'static' \
	-X 'github.com/aws/rolesanywhere-credential-helper/cmd.Version=${VERSION}' \

BUILD_OPTIONS ?= -a -installsuffix cgo -a -tags netgo -ldflags "${LDFLAGS}"

all: build
build:
	@echo "==> building go code $(GOPROXY)"
	$(GO_PROXY) CGO_ENABLED=0 $(GOBUILD) ${BUILD_OPTIONS} -v -o ${GODIST}/${BINARY_NAME} main.go


dep:
	@echo "==> downloading go tools $(GOPROXY)"
	GOBIN=$(GOBIN) go install  golang.org/x/tools/cmd/goimports@latest
	GOBIN=$(GOBIN) go install  honnef.co/go/tools/cmd/staticcheck@latest
	GOBIN=$(GOBIN) go install github.com/securego/gosec/v2/cmd/gosec@v2.18.2
	GOBIN=$(GOBIN) go install github.com/golang/mock/mockgen@v1.6.0

lint:
	@echo "==> lint"
	GOBIN=$(GOBIN) CGO_ENABLED=0 go vet -ldflags "-w -s -extldflags 'static'" $(PKGS)

go-download:
	@echo "==> downloading deps $(GOPROXY)"
	GOBIN=$(GOBIN) go mod download
	
gosec:
	@echo "==> static files scan (gosec), see gosec-results.json for details"
	$(GOBIN)/gosec $(GOSECFLAGS)

check-fmt:
	@echo "==> check format"
	$(GOBIN)/goimports -d $(FILES)

fmt:
	@echo "==> formating"
	$(GOBIN)/goimports -w .

test:
	@echo "==> testing"
	${GOCMD} test ./... -v

local-release:
	@echo "==> local release"
	goreleaser release  --clean --skip=publish --snapshot --timeout 60m

release:
	@echo "==> release"
	goreleaser release  --clean --timeout 60m