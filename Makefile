# ==============================================================================
# Build Configuration
# ==============================================================================
UNAME := $(shell uname)
ARCH := $(shell uname -m)

# Detect OS and set appropriate file extensions
ifeq ($(UNAME), Linux)
	OS := linux
	EXT := so
	SHELL := /bin/bash
else ifeq ($(UNAME), Darwin)
	OS := darwin
	EXT := dylib
	SHELL := /bin/bash
else
	$(error Unsupported operating system: $(UNAME))
endif

# Build configuration
BUILD_DIR := build
BUILD_TYPE ?= release
BUILD_FROM_SOURCE ?= false
TARGET_LIBRARY ?= all
LUA_VERSIONS := luajit lua51
CARGO_FLAGS ?= --release
CARGO_FEATURES ?= --features luajit

# Docker configuration
RAG_SERVICE_VERSION ?= 0.0.11
RAG_SERVICE_IMAGE := ghcr.io/neopilot-ai/neopilot-rag-service:$(RAG_SERVICE_IMAGE_TAG)
RAG_SERVICE_IMAGE_TAG ?= $(RAG_SERVICE_VERSION)-$(shell git rev-parse --short HEAD)

# Build type specific flags
ifeq ($(BUILD_TYPE),debug)
	CARGO_FLAGS := --debug
	TARGET_DIR := debug
else
	CARGO_FLAGS := --release
	TARGET_DIR := release
	CARGO_FEATURES += --release
endif

# Default target
.DEFAULT_GOAL := help
.PHONY: all
all: build

# Help target
.PHONY: help
help:
	@echo '\nNeoPilot.nvim Build System\n'
	@echo 'Usage:'
	@echo '  make <target> [options]\n'
	@echo 'Targets:'
	@echo '  build           Build all components (default)'
	@echo '  test           Run all tests'
	@echo '  lint           Run all linters'
	@echo '  clean          Remove build artifacts'
	@echo '  help           Show this help message\n'
	@echo 'Options:'
	@echo '  BUILD_TYPE=debug|release  Build type (default: release)'
	@echo '  BUILD_FROM_SOURCE=true    Force build from source'
	@echo '  TARGET_LIBRARY=all|tokenizers|templates|repo-map|html2md'
	@echo '                         Build specific library (default: all)'
	@echo '  RAG_SERVICE_VERSION=x.y.z  Set RAG service version\n'

# ==============================================================================
# Build Rules
# ==============================================================================
# Define build rules for each Lua version
define make_definitions
.PHONY: $1
$1: check-lua-version-$1

.PHONY: check-lua-version-$1
check-lua-version-$1:
	@if [ "$$(LUA_VERSION)" != "" ] && [ "$$(LUA_VERSION)" != "$1" ]; then \
		echo "Error: LUA_VERSION=$$LUA_VERSION does not match target $1"; \
		exit 1; \
	fi

# Build from source if requested, otherwise use pre-built binaries
ifeq ($$(BUILD_FROM_SOURCE),true)
$1: $(addprefix $(BUILD_DIR)/libNeopilot,$(addsuffix -$1.$(EXT),$(addprefix ,$(if $(filter all tokenizers,$(TARGET_LIBRARY)), Tokenizers)) $(if $(filter all templates,$(TARGET_LIBRARY)), Templates) $(if $(filter all repo-map,$(TARGET_LIBRARY)), RepoMap) $(if $(filter all html2md,$(TARGET_LIBRARY)), Html2md))))
else
$1:
	@echo "Building $1 using pre-built binaries..."
	LUA_VERSION=$1 bash ./build.sh
endif
endef

$(foreach lua_version,$(LUA_VERSIONS),$(eval $(call make_definitions,$(lua_version))))

# Define how to build each package
define build_package
.PHONY: $1-$2
$1-$2: check-lua-version-$1
	@echo "Building neopilot-$2 for $1..."
	@if ! cargo build $(CARGO_FLAGS) --features=$1 -p neopilot-$(subst -,,$2); then \
		echo "Failed to build neopilot-$2 for $1"; \
		exit 1; \
	fi
	@mkdir -p $(BUILD_DIR)
	@cp target/$(TARGET_DIR)/libneopilot_$(subst -,,$2).$(EXT) $(BUILD_DIR)/libNeopilot$(shell echo $(subst -, ,$2) | sed -E 's/(^| )([a-z])/\U\2/g' | tr -d ' ')-$1.$(EXT)
endef

# Define file targets for each library
define build_targets
$(BUILD_DIR)/libNeopilotTokenizers-$1.$(EXT): $(BUILD_DIR) $1-tokenizers
$(BUILD_DIR)/libNeopilotTemplates-$1.$(EXT): $(BUILD_DIR) $1-templates
$(BUILD_DIR)/libNeopilotRepoMap-$1.$(EXT): $(BUILD_DIR) $1-repo-map
$(BUILD_DIR)/libNeopilotHtml2md-$1.$(EXT): $(BUILD_DIR) $1-html2md
endef

# Generate build rules for all Lua versions and packages
$(foreach lua_version,$(LUA_VERSIONS),$(eval $(call build_package,$(lua_version),tokenizers)))
$(foreach lua_version,$(LUA_VERSIONS),$(eval $(call build_package,$(lua_version),templates)))
$(foreach lua_version,$(LUA_VERSIONS),$(eval $(call build_package,$(lua_version),repo-map)))
$(foreach lua_version,$(LUA_VERSIONS),$(eval $(call build_package,$(lua_version),html2md)))
$(foreach lua_version,$(LUA_VERSIONS),$(eval $(call build_targets,$(lua_version))))

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Clean targets
.PHONY: clean clean-all
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)

clean-all: clean
	@echo "Cleaning all generated files..."
	@cargo clean
	@rm -rf target/

# ==============================================================================
# Lint and Format
# ==============================================================================
LUACHECK_ARGS := --codes --no-unused --no-redefined --no-self --no-max-line-length
LUACHECK_FILES := $(shell find . -name "*.lua" -type f -not -path "*/target/*" -not -path "*/.git/*")
STYLUA_FILES := lua/ plugin/ tests/

.PHONY: luacheck
luacheck:
	@echo "Running LuaCheck..."
	@luacheck $(LUACHECK_FILES) $(LUACHECK_ARGS)

.PHONY: luastylecheck
luastylecheck:
	@echo "Checking Lua code style..."
	@stylua --check $(STYLUA_FILES)

.PHONY: stylefix
stylefix:
	@echo "Fixing Lua code style..."
	@stylua $(STYLUA_FILES)

# ==============================================================================
# Rust Tools
# ==============================================================================
.PHONY: ruststylecheck
ruststylecheck:
	@echo "Checking Rust code style..."
	@if ! command -v rustup &> /dev/null; then \
		echo "Error: rustup is not installed"; \
		exit 1; \
	fi
	@rustup component add rustfmt 2> /dev/null || true
	@cargo fmt --all -- --check

.PHONY: rustlint
rustlint:
	@echo "Running Rust linter..."
	@if ! command -v rustup &> /dev/null; then \
		echo "Error: rustup is not installed"; \
		exit 1; \
	fi
	@rustup component add clippy 2> /dev/null || true
	@cargo clippy $(CARGO_FEATURES) --all -- -F clippy::dbg-macro -D warnings -D clippy::unwrap_used

.PHONY: rusttest
rusttest:
	@echo "Running Rust tests..."
	@cargo test $(CARGO_FEATURES) -- --nocapture

# ==============================================================================
# Testing
# ==============================================================================
.PHONY: luatest
luatest:
	@echo "Running Lua tests..."
	@nvim --headless -c "PlenaryBustedDirectory tests/"

.PHONY: test test-lua test-rust
test: test-lua test-rust

test-lua: luatest lua-typecheck

test-rust: rusttest

.PHONY: lint
lint: luacheck luastylecheck ruststylecheck rustlint

.PHONY: lua-typecheck
lua-typecheck:
	@echo "Type checking Lua code..."
	@if [ ! -f "./scripts/lua-typecheck.sh" ]; then \
		echo "Error: lua-typecheck.sh not found"; \
		exit 1; \
	fi
	@bash ./scripts/lua-typecheck.sh

# ==============================================================================
# Docker
# ==============================================================================
.PHONY: build-image
build-image:
	@echo "Building RAG service Docker image..."
	@docker build --platform=linux/amd64 \
		-t $(RAG_SERVICE_IMAGE) \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		-f py/rag-service/Dockerfile \
		py/rag-service

.PHONY: push-image
push-image: build-image
	@echo "Pushing RAG service image to registry..."
	@docker push $(RAG_SERVICE_IMAGE)

.PHONY: run-container
run-container: build-image
	@echo "Starting RAG service container..."
	@docker run -d --rm \
		--name neopilot-rag-service \
		-p 8000:8000 \
		$(RAG_SERVICE_IMAGE)

# ==============================================================================
# Development
# ==============================================================================
.PHONY: dev-setup
dev-setup:
	@echo "Setting up development environment..."
	@if ! command -v rustup &> /dev/null; then \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh; \
	fi
	@rustup component add rustfmt clippy
	@cargo install stylua --features lua52
	@cargo install luacheck
	@echo "Development setup complete!"

# ==============================================================================
# Build
# ==============================================================================
.PHONY: build build-release build-debug

build: build-release

build-release:
	$(MAKE) BUILD_TYPE=release all

build-debug:
	$(MAKE) BUILD_TYPE=debug all

# ==============================================================================
# Version Management
# ==============================================================================
VERSION_FILE := lua/neopilot/version.lua
.PHONY: version bump-version

version:
	@echo "Current version: $(shell grep -oP 'return "\K[0-9]+\.[0-9]+\.[0-9]+' $(VERSION_FILE))"

bump-version:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is not set. Usage: make bump-version VERSION=x.y.z"; \
		exit 1; \
	fi
	@echo "Bumping version to $(VERSION)..."
	@sed -i.bak -E 's/return "[0-9]+\.[0-9]+\.[0-9]+"/return "$(VERSION)"/' $(VERSION_FILE)
	@rm -f $(VERSION_FILE).bak
	@git add $(VERSION_FILE)
	@git commit -m "chore: bump version to $(VERSION)"
	@git tag -a v$(VERSION) -m "Version $(VERSION)"
	@echo "Version bumped to $(VERSION) and tagged as v$(VERSION)"
