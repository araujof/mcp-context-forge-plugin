
REQUIRED_BUILD_BINS := uv

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Project variables
PACKAGE_NAME = denylist
CF_PROJECT_NAME = mcpgateway
TARGET ?= src

# Virtual-environment variables
VENVS_DIR := $(HOME)/.venv
VENV_DIR  := $(VENVS_DIR)/$(CF_PROJECT_NAME)

### Linters
black:
	@echo "🎨  black $(TARGET)..." && $(VENV_DIR)/bin/black -l 200 $(TARGET)

black-check:
	@echo "🎨  black --check $(TARGET)..." && $(VENV_DIR)/bin/black -l 200 --check --diff $(TARGET)

ruff:
	@echo "⚡ ruff $(TARGET)..." && $(VENV_DIR)/bin/ruff check $(TARGET) && $(VENV_DIR)/bin/ruff format $(TARGET)

ruff-check:
	@echo "⚡ ruff check $(TARGET)..." && $(VENV_DIR)/bin/ruff check $(TARGET)

ruff-fix:
	@echo "⚡ ruff check --fix $(TARGET)..." && $(VENV_DIR)/bin/ruff check --fix $(TARGET)

ruff-format:
	@echo "⚡ ruff format $(TARGET)..." && $(VENV_DIR)/bin/ruff format $(TARGET)

### Targets
.PHONY: install
install:
	$(foreach bin,$(REQUIRED_BUILD_BINS), $(if $(shell command -v $(bin) 2> /dev/null),,$(error Couldn't find `$(bin)`)))
	@/bin/bash -c "source $(VENV_DIR)/bin/activate && python3 -m uv pip install ."

.PHONY: uninstall
uninstall:
	pip uninstall $(PACKAGE_NAME)

.PHONY: build
build:
	$(foreach bin,$(REQUIRED_BUILD_BINS), $(if $(shell command -v $(bin) 2> /dev/null),,$(error Couldn't find `$(bin)`)))
	uv build

.PHONY: lint-fix
lint-fix:
	@# Handle file arguments
	@target_file="$(word 2,$(MAKECMDGOALS))"; \
	if [ -n "$$target_file" ] && [ "$$target_file" != "" ]; then \
		actual_target="$$target_file"; \
	else \
		actual_target="$(TARGET)"; \
	fi; \
	for target in $$(echo $$actual_target); do \
		if [ ! -e "$$target" ]; then \
			echo "❌ File/directory not found: $$target"; \
			exit 1; \
		fi; \
	done; \
	echo "🔧 Fixing lint issues in $$actual_target..."; \
	$(MAKE) --no-print-directory black TARGET="$$actual_target"; \
	$(MAKE) --no-print-directory isort TARGET="$$actual_target"; \
	$(MAKE) --no-print-directory ruff-fix TARGET="$$actual_target"

.PHONY: lint-check
lint-check:
	@# Handle file arguments
	@target_file="$(word 2,$(MAKECMDGOALS))"; \
	if [ -n "$$target_file" ] && [ "$$target_file" != "" ]; then \
		actual_target="$$target_file"; \
	else \
		actual_target="$(TARGET)"; \
	fi; \
	for target in $$(echo $$actual_target); do \
		if [ ! -e "$$target" ]; then \
			echo "❌ File/directory not found: $$target"; \
			exit 1; \
		fi; \
	done; \
	echo "🔧 Fixing lint issues in $$actual_target..."; \
	$(MAKE) --no-print-directory black-check TARGET="$$actual_target"; \
	$(MAKE) --no-print-directory isort-check TARGET="$$actual_target"; \
	$(MAKE) --no-print-directory ruff-check TARGET="$$actual_target"

.PHONY: lock
lock:
	$(foreach bin,$(REQUIRED_BUILD_BINS), $(if $(shell command -v $(bin) 2> /dev/null),,$(error Couldn't find `$(bin)`. Please run `make init`)))
	uv lock

.PHONY: test
test:
	pytest tests

.PHONY: clean
clean:
	find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
	rm -rf *.egg-info  src/*.egg-info .pytest_cache tests/.pytest_cache build dist .ruff_cache .coverage

.PHONY: help
help:
	@echo "This Makefile is offered for convenience."
	@echo ""
	@echo "The following are the valid targets for this Makefile:"
	@echo "...install           Install package from sources"
	@echo "...uninstall         Uninstall package"
	@echo "...build             Build package for distribution"
	@echo "...lock              Lock dependencies"
	@echo "...lint-fix          Check and fix lint errors"
	@echo "...lint-check        Check for lint errors"
	@echo "...test              Run all tests"
	@echo "...clean             Remove all artifacts and builds"
