# Shell config
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Make config
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Executables
MAKE_VERSION := $(shell make --version | head -n 1 2> /dev/null)
SED := $(shell command -v sed 2> /dev/null)
SED_INPLACE := $(shell if [ -n "$(SED)" ]; then if $(SED) --version >/dev/null 2>&1; then echo "$(SED) -i"; else echo "$(SED) -i ''"; fi; fi)
AWK := $(shell command -v awk 2> /dev/null)
GREP := $(shell command -v grep 2> /dev/null)
UV := $(shell command -v uv 2> /dev/null)
PYTHON := $(shell command -v python 2> /dev/null)
GIT := $(shell command -v git 2> /dev/null)
GIT_VERSION := $(shell $(GIT) --version 2> /dev/null || printf '\033[31mnot installed\033[0m\n')
DOCKER := $(shell command -v docker 2> /dev/null)
DOCKER_VERSION := $(shell if [ -n "$(DOCKER)" ]; then $(DOCKER) --version 2> /dev/null; fi)
DOCKER_COMPOSE := $(shell if [ -n "$(DOCKER)" ]; then command -v docker-compose 2> /dev/null || echo "$(DOCKER) compose"; fi)
DOCKER_COMPOSE_VERSION := $(shell if [ -n "$(DOCKER_COMPOSE)" ]; then $(DOCKER_COMPOSE) version 2> /dev/null; fi )

# Project variables -- change as needed before running make install
# override the defaults by setting the variables in a Makefile.env file
-include Makefile.env
PROJECT_NAME ?= $(shell if [ -n "$(GREP)" ] && [ -n "$(SED)" ]; then $(GREP) '^name = ' pyproject.toml | $(SED) 's/name = "\(.*\)"/\1/'; fi)
# make sure the project name is lowercase and has no spaces
PROJECT_NAME := $(shell echo $(PROJECT_NAME) | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
AUTHOR_NAME ?= $(shell if [ -n "$(GREP)" ] && [ -n "$(SED)" ]; then $(GREP) 'name.*email' pyproject.toml | $(SED) -E 's/.*name = "([^"]+)".*/\1/'; fi || if [ -n "$(GIT)" ]; then $(GIT) config --get user.name; fi)
AUTHOR_EMAIL ?= $(shell if [ -n "$(GREP)" ] && [ -n "$(SED)" ]; then $(GREP) 'email' pyproject.toml | $(SED) -E 's/.*email = "([^"]+)".*/\1/'; fi || if [ -n "$(GIT)" ]; then $(GIT) config --get user.email; fi)
GITHUB_REPO ?= $(shell if [ -n "$(GIT)" ]; then url=$$($(GIT) config --get remote.origin.url); echo $${url%.git}; fi)
GITHUB_USER_NAME ?= $(shell if [ -n "$(AWK)" ]; then echo $(GITHUB_REPO) | $(AWK) -F/ 'NF>=4{print $$4}'; fi || echo "")
PROJECT_VERSION ?= $(shell if [ -n "$(GREP)" ] && [ -n "$(SED)" ]; then $(GREP) '^version = ' pyproject.toml | $(SED) 's/version = "\(.*\)"/\1/'; fi)
PROJECT_DESCRIPTION ?= '$(shell if [ -n "$(GREP)" ] && [ -n "$(SED)" ]; then $(GREP) 'description' pyproject.toml | $(SED) 's/description = //'; fi)'
PROJECT_LICENSE ?= $(shell if [ -n "$(GREP)" ] && [ -n "$(SED)" ]; then $(GREP) -e 'license.*text.*=.*".*"' pyproject.toml | $(SED) -E 's/.*"([^"]+)".*/\1/'; fi)
PYTHON_VERSION ?= 3.11.11
VIRTUALENV_NAME ?= .venv
PRECOMMIT_CONF ?= .pre-commit-config.yaml
DOCKER_FILE ?= Dockerfile
DOCKER_COMPOSE_FILE ?= docker-compose.yml
DOCKER_IMAGE_NAME ?= $(PROJECT_NAME)
DOCKER_CONTAINER_NAME ?= $(PROJECT_NAME)

# Stamp files
INSTALL_STAMP := .install.stamp
PRODUCTION_STAMP := .production.stamp
DEPS_EXPORT_STAMP := .deps-export.stamp
BUILD_STAMP := .build.stamp
DOCKER_BUILD_STAMP := .docker-build.stamp
DOCS_STAMP := .docs.stamp
RELEASE_STAMP := .release.stamp
STAGING_STAMP := .staging.stamp
STAMP_FILES := $(wildcard .*.stamp)

# Dirs
SRC := $(PROJECT_NAME)
TESTS := tests
BUILD := dist
DOCS := docs
DOCS_SITE := site
CACHE_DIRS := $(wildcard .*_cache)
COVERAGE := .coverage $(wildcard coverage.*)
EGG_INFO := $(PROJECT_NAME).egg-info

# Files
PY_FILES := $(shell find $(SRC) -type f -name '*.py')
TEST_FILES := $(shell find $(TESTS) -type f -name '*.py')
DOCS_FILES := $(shell find $(DOCS) -type f -name '*.md') README.md
PROJECT_INIT := .project-init
DOCKER_FILES_TO_UPDATE := $(DOCKER_FILE) $(DOCKER_COMPOSE_FILE) entrypoint.sh
PY_FILES_TO_UPDATE := $(SRC)/main.py $(SRC)/__main__.py $(SRC)/logger/__init__.py $(TESTS)/test_main.py
DOCS_FILES_TO_RESET := README.md $(DOCS)/index.md $(DOCS)/about.md

# Colors
# Color scheme:
#   MAGENTA: Section headers and main titles
#   CYAN: Labels, field names, and operation start messages
#   GREEN: Success and completion messages
#   YELLOW: Warnings, advisory notes, "already exists" messages, and user prompts
#   RED: Errors and missing dependencies
RESET := \033[0m
RED := \033[1;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
MAGENTA := \033[1;35m
CYAN := \033[0;36m

# Intentionally left empty
ARGS ?=

#-- Info

.DEFAULT_GOAL := help
.PHONY: help
help:  ## Show this help message
	@echo -e "\n$(MAGENTA)$(PROJECT_NAME) v$(PROJECT_VERSION) Makefile$(RESET)"
	@echo -e "\n$(MAGENTA)Usage:\n$(RESET)  make $(CYAN)[target] [ARGS=\"...\"]$(RESET)\n"
	@if [ -z "$(GREP)" ] || [ -z "$(AWK)" ] || [ -z "$(SED)" ]; then \
		echo -e "$(RED)Error: Required tools (grep, awk, sed) not found.$(RESET)"; \
		echo -e "$(YELLOW)Please install them to see the full help menu.$(RESET)"; \
		exit 1; \
	fi
	@$(GREP) -E '^[0-9a-zA-Z_-]+(/?[0-9a-zA-Z_-]*)*:.*?## .*$$|(^#--)' $(firstword $(MAKEFILE_LIST)) \
	| $(AWK) 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-21s\033[0m %s\n", $$1, $$2}' \
	| $(SED) -e 's/\[36m  #-- /\[1;35m/'

.PHONY: info
info:  ## Show development environment info
	@echo -e "\n$(MAGENTA)$(PROJECT_NAME) v$(PROJECT_VERSION)$(RESET)"
	@echo -e "$(MAGENTA)\nSystem:$(RESET)"
	@echo -e "  $(CYAN)OS:$(RESET) $(shell uname -s)"
	@echo -e "  $(CYAN)Shell:$(RESET) $(SHELL) - $(shell $(SHELL) --version | head -n 1)"
	@echo -e "  $(CYAN)Make:$(RESET) $(MAKE_VERSION)"
	@echo -e "  $(CYAN)Git:$(RESET) $(GIT_VERSION)"
	@echo -e "$(MAGENTA)Project:$(RESET)"
	@echo -e "  $(CYAN)Project name:$(RESET) $(PROJECT_NAME)"
	@echo -e "  $(CYAN)Project description:$(RESET) $(PROJECT_DESCRIPTION)"
	@echo -e "  $(CYAN)Project author:$(RESET) $(AUTHOR_NAME) ($(GITHUB_USER_NAME) <$(AUTHOR_EMAIL)>)"
	@echo -e "  $(CYAN)Project version:$(RESET) $(PROJECT_VERSION)"
	@echo -e "  $(CYAN)Project license:$(RESET) $(PROJECT_LICENSE)"
	@echo -e "  $(CYAN)Project repository:$(RESET) $(GITHUB_REPO)"
	@echo -e "  $(CYAN)Project directory:$(RESET) $(CURDIR)"
	@echo -e "$(MAGENTA)Python:$(RESET)"
	@echo -e "  $(CYAN)Python version:$(RESET) $(PYTHON_VERSION)"
	@echo -e "  $(CYAN)Virtualenv name:$(RESET) $(VIRTUALENV_NAME)"
	@echo -e "  $(CYAN)uv version:$(RESET) $(shell $(UV) --version || echo "$(RED)not installed $(RESET)")"
	@echo -e "$(MAGENTA)Docker:$(RESET)"
	@if [ -n "$(DOCKER_VERSION)" ]; then \
		echo -e "  $(CYAN)Docker:$(RESET) $(DOCKER_VERSION)"; \
	else \
		echo -e "  $(CYAN)Docker:$(RESET) $(RED)not installed $(RESET)"; \
	fi
	@if [ -n "$(DOCKER_COMPOSE_VERSION)" ]; then \
		echo -e "  $(CYAN)Docker Compose:$(RESET) $(DOCKER_COMPOSE_VERSION)"; \
	else \
		echo -e "  $(CYAN)Docker Compose:$(RESET) $(RED)not installed $(RESET)"; \
	fi
	@echo -e "  $(CYAN)Docker image name:$(RESET) $(DOCKER_IMAGE_NAME)"
	@echo -e "  $(CYAN)Docker container name:$(RESET) $(DOCKER_CONTAINER_NAME)"

# Dependencies

.PHONY: dep/git
dep/git:
	@if [ -z "$(GIT)" ]; then echo -e "$(RED)Git not found.$(RESET)" && exit 1; fi

.PHONY: dep/venv
dep/venv: dep/uv
	@if [ ! -d "$(VIRTUALENV_NAME)" ]; then \
		echo -e "$(RED)Virtualenv not found. Run 'make virtualenv' first.$(RESET)" && exit 1; \
	fi

.PHONY: dep/python
dep/python:
	@if [ -z "$(PYTHON)" ]; then echo -e "$(RED)Python not found.$(RESET)" && exit 1; fi

.PHONY: dep/uv
dep/uv: dep/python
	@if [ -z "$(UV)" ]; then echo -e "$(RED)uv not found.$(RESET)" && exit 1; fi

.PHONY: dep/docker
dep/docker:
	@if [ -z "$(DOCKER)" ]; then echo -e "$(RED)Docker not found.$(RESET)" && exit 1; fi

.PHONY: dep/docker-compose
dep/docker-compose:
	@if [ -z "$(DOCKER_COMPOSE)" ]; then echo -e "$(RED)Docker Compose not found.$(RESET)" && exit 1; fi

.PHONY: dep/ruff
dep/ruff: dep/venv
	@if ! $(UV) run ruff --version > /dev/null 2>&1; then \
		echo -e "$(RED)Ruff not found. Please run 'make install' first.$(RESET)" && exit 1; \
	fi

#-- System

.PHONY: python
python: | dep/uv  ## Check if Python is installed
	@if ! $(PYTHON) --version | grep $(PYTHON_VERSION) > /dev/null ; then \
		echo -e "$(YELLOW)Python version $(PYTHON_VERSION) not installed, installing it...$(RESET)"; \
		$(UV) python install $(PYTHON_VERSION) || exit 1; \
		echo -e "$(GREEN)Python version $(PYTHON_VERSION) installed.$(RESET)"; \
	else \
		echo -e "$(CYAN)\nPython version $(PYTHON_VERSION) available.$(RESET)"; \
	fi

# duplication dep/venv
.PHONY: virtualenv
virtualenv: | dep/uv  ## Check if virtualenv exists - create it if not
	@echo -e "$(CYAN)\nChecking Python and virtualenv setup...$(RESET)"
	@PYTHON_MAJOR_MINOR=$$(echo $(PYTHON_VERSION) | $(AWK) -F. '{print $$1"."$$2}'); \
	UV_PYTHON_LIST=$$($(UV) python list); \
	if echo "$$UV_PYTHON_LIST" | grep -q "cpython-$$PYTHON_MAJOR_MINOR" ; then \
		FOUND_VERSION=$$(echo "$$UV_PYTHON_LIST" | grep "cpython-$$PYTHON_MAJOR_MINOR" | head -1 | $(AWK) '{print $$1}' | $(SED) 's/cpython-//'); \
		echo -e "$(GREEN)Python version $$FOUND_VERSION is available.$(RESET)"; \
	else \
		echo -e "$(YELLOW)Python version $$PYTHON_MAJOR_MINOR not found, installing $(PYTHON_VERSION)...$(RESET)"; \
		$(UV) python install $(PYTHON_VERSION) || exit 1; \
		echo -e "$(GREEN)Python version $(PYTHON_VERSION) installed.$(RESET)"; \
	fi
	@if ! ls $(VIRTUALENV_NAME) > /dev/null 2>&1 ; then \
		echo -e "$(YELLOW)Local virtualenv not found. Creating it...$(RESET)"; \
		PYTHON_MAJOR_MINOR=$$(echo $(PYTHON_VERSION) | $(AWK) -F. '{print $$1"."$$2}'); \
		$(UV) venv --python $$PYTHON_MAJOR_MINOR || exit 1; \
		echo -e "$(GREEN)Virtualenv created at $(VIRTUALENV_NAME).$(RESET)"; \
	else \
		echo -e "$(YELLOW)Virtualenv already exists at $(VIRTUALENV_NAME).$(RESET)"; \
	fi
	@echo -e "$(YELLOW)To activate manually, run: source $(VIRTUALENV_NAME)/bin/activate$(RESET)"
	@echo -e "$(YELLOW)Note: Make targets use 'uv run' and don't require manual activation.$(RESET)"

.PHONY: shell
shell: dep/venv  ## Open an interactive shell in the virtual environment
	@echo -e "$(CYAN)\nOpening shell in virtual environment...$(RESET)"
	@echo -e "$(YELLOW)Type 'exit' to leave the shell.$(RESET)"
	@bash --init-file <(echo "source $(VIRTUALENV_NAME)/bin/activate; PS1='(venv) \[\033[1;35m\]$(PROJECT_NAME)\[\033[0m\] \w\$$ '")

.PHONY: uv
uv: | dep/uv  ## Check if uv is installed
	@echo -e "$(CYAN)\n$(shell $(UV) --version) available.$(RESET)"

.PHONY: uv-update
uv-update: | dep/uv  ## Update uv
	@echo -e "$(CYAN)\nUpdating uv...$(RESET)"
	@$(UV) self update $(ARGS)
	@echo -e "$(GREEN)uv updated.$(RESET)"

#-- Project

.PHONY: install
install: dep/venv $(INSTALL_STAMP)  ## Install the project for development
$(INSTALL_STAMP): pyproject.toml .pre-commit-config.yaml
	@echo -e "$(CYAN)\nInstalling project $(PROJECT_NAME)...$(RESET)"
	@mkdir -p $(SRC) $(TESTS) $(DOCS) $(BUILD) || true
	@$(UV) sync --extra dev --extra test --extra docs
	@$(UV) lock
	@$(UV) run pre-commit install
	@if [ ! -f $(PROJECT_INIT) ] && [ "$(PROJECT_NAME)" != "pyrays" ]; then \
		echo -e "$(CYAN)Updating project $(PROJECT_NAME) information...$(RESET)"; \
		$(PYTHON) toml.py --name $(PROJECT_NAME) --ver $(PROJECT_VERSION) --desc $(PROJECT_DESCRIPTION) --repo $(GITHUB_REPO)  --lic $(PROJECT_LICENSE) ; \
		echo -e "$(CYAN)Creating $(PROJECT_NAME) package module...$(RESET)"; \
		mv pyrays/* $(SRC)/ ; \
		rm -rf pyrays ; \
		echo -e "$(CYAN)Updating files...$(RESET)"; \
		$(SED_INPLACE) "s/pyrays/$(PROJECT_NAME)/g" $(DOCKER_FILES_TO_UPDATE) ; \
		$(SED_INPLACE) "s/pyrays/$(PROJECT_NAME)/g" $(PY_FILES_TO_UPDATE) ; \
		$(SED_INPLACE) "s/pyrays/$(PROJECT_NAME)/g" $(DOCS)/module.md ; \
		NEW_TEXT="#$(PROJECT_NAME)\n\n$(subst ",,$(subst ',,$(PROJECT_DESCRIPTION)))"; \
		for file in $(DOCS_FILES_TO_RESET); do \
			echo -e $$NEW_TEXT > $$file; \
		done; \
		$(SED_INPLACE) "1s/.*/$$NEW_TEXT/" $(DOCS)/module.md ; \
		$(SED_INPLACE) 's|copyright: MIT License 2024|copyright: $(PROJECT_LICENSE)|g' mkdocs.yml ; \
		$(SED_INPLACE) 's|site_name: pyrays|site_name: $(PROJECT_NAME)|g' mkdocs.yml ; \
		$(SED_INPLACE) 's|site_url: https://github.com/bateman/pyrays|site_url: https:\/\/$(GITHUB_USER_NAME)\.github\.io\/$(PROJECT_NAME)|g' mkdocs.yml ; \
		$(SED_INPLACE) 's|site_description: A GitHub template project with Python + uv.|site_description: $(subst ",,$(subst ',,$(PROJECT_DESCRIPTION)))|g' mkdocs.yml ; \
		$(SED_INPLACE) 's|site_author: Fabio Calefato <fcalefato@gmail.com>|site_author: $(GITHUB_USER_NAME) <$(AUTHOR_EMAIL)>|g' mkdocs.yml ; \
		$(SED_INPLACE) 's|repo_url: https://github.com/bateman/pyrays|repo_url: $(GITHUB_REPO)|g' mkdocs.yml ; \
		$(SED_INPLACE) 's|repo_name: bateman/pyrays|repo_name: $(GITHUB_USER_NAME)\/$(PROJECT_NAME)|g' mkdocs.yml ; \
		echo -e "$(GREEN)Project $(PROJECT_NAME) initialized.$(RESET)"; \
		touch $(PROJECT_INIT); \
	else \
		echo -e "$(YELLOW)Project $(PROJECT_NAME) already initialized.$(RESET)"; \
	fi
	@echo -e "$(GREEN)Project $(PROJECT_NAME) installed for development.$(RESET)"
	@touch $(INSTALL_STAMP)


.PHONY: production
production: dep/venv $(PRODUCTION_STAMP)  ## Install the project for production
$(PRODUCTION_STAMP): $(INSTALL_STAMP)
	@echo -e "$(CYAN)\nInstall project for production...$(RESET)"
	@$(UV) sync
	@$(UV) lock
	@touch $(PRODUCTION_STAMP)
	@echo -e "$(GREEN)Project installed for production.$(RESET)"

.PHONY: install-hooks
install-hooks: dep/venv $(PRECOMMIT_CONF)  ## Install git pre-commit hooks
	@echo -e "$(CYAN)\nInstalling git pre-commit hooks...$(RESET)"
	@$(UV) run pre-commit install
	@$(UV) run pre-commit install --hook-type commit-msg
	@echo -e "$(GREEN)Pre-commit hooks installed.$(RESET)"
	@echo -e "$(YELLOW)Hooks will run automatically before commits.$(RESET)"

.PHONY: update
update: | dep/uv install  ## Update all project dependencies
	@echo -e "$(CYAN)\nUpdating project dependencies...$(RESET)"
	@if [ -f "$(PRODUCTION_STAMP)" ]; then \
		echo -e "$(CYAN)Production environment detected. Updating only core dependencies...$(RESET)"; \
		$(UV) lock --upgrade; \
		$(UV) sync --all-packages --upgrade $(ARGS); \
	else \
		echo -e "$(CYAN)Development environment detected. Updating all dependencies...$(RESET)"; \
		$(UV) lock --upgrade; \
		$(UV) sync --all-packages --upgrade --extra dev --extra test --extra docs $(ARGS); \
		$(UV) run pre-commit autoupdate; \
	fi
	@echo -e "$(GREEN)Dependencies updated.$(RESET)"

.PHONY: clean
clean:  dep/python  ## Clean the project - removes all cache dirs and stamp files
	@echo -e "$(CYAN)\nCleaning the project...$(RESET)"
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@rm -rf $(STAMP_FILES) $(CACHE_DIRS) $(BUILD) $(EGG_INFO) $(DOCS_SITE) $(COVERAGE) || true
	@echo -e "$(GREEN)Project cleaned.$(RESET)"

.PHONY: reset
reset:  ## Cleans plus removes the virtual environment (use ARGS="hard" to re-initialize the project)
	@echo -e "$(RED)\nAre you sure you want to proceed with the reset (this involves wiping also the virual environment)? [y/N]: $(RESET)"
	@read -r answer; \
	case $$answer in \
		[Yy]* ) \
			$(MAKE) clean; \
			echo -e "$(CYAN)Resetting the project...$(RESET)"; \
			$(GIT) checkout uv.lock > /dev/null || true ; \
			rm -rf $(VIRTUALENV_NAME) > /dev/null || true  ; \
			if [ "$(ARGS)" = "hard" ]; then \
				rm -f $(PROJECT_INIT) > /dev/null || true ; \
			fi; \
			echo -e "$(GREEN)Project reset.$(RESET)" ;; \
		* ) \
			echo -e "$(YELLOW)Project reset aborted.$(RESET)"; \
			exit 0 ;; \
	esac

.PHONY: run
run: $(INSTALL_STAMP)  ## Run the project
	@$(UV) run python -m $(PROJECT_NAME) $(ARGS)

.PHONY: test
test: $(INSTALL_STAMP)  ## Run the tests
	@echo -e "$(CYAN)\nRunning the tests...$(RESET)"
	@$(UV) run pytest --cov=$(SRC) $(TESTS) $(ARGS)

.PHONY: build
build: dep/uv $(BUILD_STAMP)  ## Build the project as a package
$(BUILD_STAMP): pyproject.toml Makefile $(PY_FILES)
	@echo -e "$(CYAN)\nBuilding the project...$(RESET)"
	@rm -rf $(BUILD)
	@$(UV) build $(ARGS)
	@echo -e "$(GREEN)Project built.$(RESET)"
	@touch $(BUILD_STAMP)

.PHONY: build-all
build-all: build docker-build docs-build  ## Build the project package and generate the documentation

.PHONY: publish
publish: dep/uv $(BUILD_STAMP)  ## Publish the project to PyPI (use ARGS="<PyPI token>")
	## if no .env file is found, check ARGS
	@if [ ! -f .env ]; then \
		if [ -z "$(ARGS)" ]; then \
			echo -e "$(RED)Missing PyPI token.$(RESET)"; \
			echo -e "$(RED)\nUsage: make publish ARGS=\"<PyPI token>\"$(RESET)"; \
			exit 1; \
		fi; \
	fi
	@echo -e "$(CYAN)\nPublishing the project to PyPI...$(RESET)"
	@export UV_PUBLISH_USERNAME=__token__
	@export UV_PUBLISH_PASSWORD=$(ARGS)
	$(UV) publish $(BUILD)/*
	@if [ $$? -eq 0 ]; then \
		echo -e "$(GREEN)Project published.$(RESET)"; \
	else \
		echo -e "$(RED)Failed to publish to PyPI.$(RESET)"; \
		exit 1; \
	fi

.PHONY: publish-all
publish-all: publish docs-publish  ## Publish the project package to PyPI and the documentation to GitHub Pages

.PHONY: export-deps
export-deps: dep/uv $(DEPS_EXPORT_STAMP)  ## Export the project's dependencies to requirements*.txt files
$(DEPS_EXPORT_STAMP): pyproject.toml uv.lock
	@echo -e "$(CYAN)\nExporting the project dependencies...$(RESET)"
	@$(UV) pip compile pyproject.toml -o requirements.txt
	@$(UV) pip compile pyproject.toml -o requirements-dev.txt --extra test --extra dev
	@$(UV) pip compile pyproject.toml -o requirements-docs.txt --extra docs
	@echo -e "$(GREEN)Dependencies exported.$(RESET)"
	@touch $(DEPS_EXPORT_STAMP)

.PHONY: deps-tree
deps-tree: | dep/uv  ## Show the dependency tree
	@echo -e "$(CYAN)\nShowing dependency tree...$(RESET)"
	@$(UV) tree

.PHONY: deps-outdated
deps-outdated: dep/venv  ## Show outdated dependencies
	@echo -e "$(CYAN)\nChecking for outdated dependencies...$(RESET)"
	@$(UV) pip list --outdated

#-- Check

.PHONY: format
format: $(INSTALL_STAMP)  ## Format the code
	@echo -e "$(CYAN)\nFormatting the code...$(RESET)"
	@$(UV) run ruff format $(PY_FILES) $(TEST_FILES)
	@echo -e "$(GREEN)Code formatted.$(RESET)"

.PHONY: lint
lint: $(INSTALL_STAMP)  ## Lint the code
	@echo -e "$(CYAN)\nLinting the code...$(RESET)"
	@$(UV) run ruff check $(PY_FILES) $(TEST_FILES)
	@echo -e "$(GREEN)Code linted.$(RESET)"

.PHONY: format-check
format-check: $(INSTALL_STAMP)  ## Check code formatting without modifying files
	@echo -e "$(CYAN)\nChecking code formatting...$(RESET)"
	@$(UV) run ruff format --check $(PY_FILES) $(TEST_FILES)
	@echo -e "$(GREEN)Code formatting check completed.$(RESET)"

.PHONY: type-check
type-check: $(INSTALL_STAMP)  ## Run static type checking with mypy
	@echo -e "$(CYAN)\nRunning type checks...$(RESET)"
	@$(UV) run mypy $(PY_FILES)
	@echo -e "$(GREEN)Type checking completed.$(RESET)"

.PHONY: check
check: format-check lint type-check  ## Run all checks without fixing (format-check, lint, type-check)
	@echo -e "$(GREEN)\nAll checks passed!$(RESET)"

.PHONY: precommit
precommit: $(INSTALL_STAMP) $(PRECOMMIT_CONF)  ## Run all pre-commit checks
	@echo -e "$(CYAN)\nRunning the pre-commit checks...$(RESET)"
	@$(UV) run pre-commit run --all-files
	@echo -e "$(GREEN)Pre-commit checks completed.$(RESET)"

#-- Release

.PHONY: show-version
show-version:  ## Show current project version
	@echo -e "$(CYAN)\nCurrent version:$(RESET) $(PROJECT_VERSION)"

.PHONY: show-tags
show-tags: | dep/git  ## Show all tags (local and remote)
	@echo -e "$(CYAN)\nLocal tags:$(RESET)"
	@$(GIT) tag -l | sort -V || echo -e "$(YELLOW)  No local tags found$(RESET)"
	@echo -e "$(CYAN)Remote tags:$(RESET)"
	@$(GIT) ls-remote --tags origin | $(AWK) -F'/' '{print $$NF}' | sort -V || echo -e "$(YELLOW)  No remote tags found$(RESET)"

.PHONY: changelog
changelog: | dep/git  ## Generate changelog from git commits since last tag
	@echo -e "$(CYAN)\nGenerating changelog...$(RESET)"
	@$(eval LAST_TAG := $(shell $(GIT) describe --tags --abbrev=0 2>/dev/null || echo ""))
	@if [ -z "$(LAST_TAG)" ]; then \
		echo -e "$(YELLOW)No tags found. Generating changelog from all commits...$(RESET)"; \
		echo "# Changelog" > CHANGELOG.md; \
		echo "" >> CHANGELOG.md; \
		echo "## All Commits" >> CHANGELOG.md; \
		echo "" >> CHANGELOG.md; \
		$(GIT) log --pretty=format:"- %s (%h)" >> CHANGELOG.md; \
	else \
		echo -e "$(CYAN)Last tag: $(LAST_TAG)$(RESET)"; \
		echo "# Changelog" > CHANGELOG.md; \
		echo "" >> CHANGELOG.md; \
		echo "## Unreleased" >> CHANGELOG.md; \
		echo "" >> CHANGELOG.md; \
		$(GIT) log $(LAST_TAG)..HEAD --pretty=format:"- %s (%h)" >> CHANGELOG.md; \
	fi
	@echo "" >> CHANGELOG.md
	@echo -e "$(GREEN)Changelog generated at CHANGELOG.md$(RESET)"

.PHONY: version
version: | dep/git
	@$(eval TAG := $(shell $(GIT) describe --tags --abbrev=0 2>/dev/null || echo "0.0.0"))
	@$(eval BEHIND_AHEAD := $(shell if [ "$(TAG)" = "0.0.0" ]; then \
		echo "0	1"; \
	else \
		$(GIT) rev-list --left-right --count $(TAG)...origin/main; \
	fi))
	@$(shell if [ "$(TAG)" = "0.0.0" ] || [ "$(BEHIND_AHEAD)" != "0	0" ]; then \
		echo "true" > $(RELEASE_STAMP); \
	else \
		echo "false" > $(RELEASE_STAMP); \
	fi)
	@echo -e "$(CYAN)\nChecking if a new release is needed...$(RESET)"
	@echo -e "  $(CYAN)Current tag:$(RESET) $(TAG)"
	@echo -e "  $(CYAN)Commits behind/ahead:$(RESET) $(shell echo ${BEHIND_AHEAD} | tr '[:space:]' '/' | $(SED) 's/\/$$//')"
	@echo -e "  $(CYAN)Needs release:$(RESET) $(shell cat $(RELEASE_STAMP))"

.PHONY: staging
staging: | dep/git
	@if $(GIT) diff --cached --quiet; then \
		echo "true" > $(STAGING_STAMP); \
	else \
		echo "false" > $(STAGING_STAMP); \
	fi; \
	echo -e "$(CYAN)\nChecking the staging area...$(RESET)"; \
	echo -e "  $(CYAN)Staging area empty:$(RESET) $$(cat $(STAGING_STAMP))"

.PHONY: tag
tag: | version staging  ## Tag a new release version (use ARGS="patch|minor|major")
	@NEEDS_RELEASE=$$(cat $(RELEASE_STAMP)); \
	if [ "$$NEEDS_RELEASE" = "true" ]; then \
		case "$(ARGS)" in \
			"patch"|"minor"|"major") \
				echo -e "$(CYAN)\nCreating a new version...$(RESET)"; \
				if [ -z "$(GREP)" ] || [ -z "$(SED)" ] || [ -z "$(AWK)" ] || [ -z "$(SED_INPLACE)" ] || [ -z "$(UV)" ] || [ -z "$(GIT)" ]; then \
					echo -e "$(RED)Error: Required tools (grep, sed, awk, uv, git) not found.$(RESET)"; \
					exit 1; \
				fi; \
				$(eval CURRENT_VERSION := $(shell $(GREP) -m1 'version = "[^"]*"' pyproject.toml | $(SED) 's/.*version = "\([^"]*\)".*/\1/')) \
				$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | $(AWK) -F. \
					-v OFS=. \
					-v action="$(ARGS)" \
					'{ \
						major=$$1; minor=$$2; patch=$$3; \
						if (action=="major") {major++; minor=0; patch=0} \
						else if (action=="minor") {minor++; patch=0} \
						else if (action=="patch") {patch++} \
						print major,minor,patch \
					}')) \
				if [ -z "$(CURRENT_VERSION)" ] || [ -z "$(NEW_VERSION)" ]; then \
					echo -e "$(RED)Error: Failed to compute version. Check pyproject.toml format.$(RESET)"; \
					exit 1; \
				fi; \
				$(SED_INPLACE) 's/^version = ".*"/version = "$(NEW_VERSION)"/' pyproject.toml; \
				$(UV) lock; \
				$(GIT) add pyproject.toml uv.lock; \
				$(GIT) commit -m "Bump version from $(CURRENT_VERSION) to $(NEW_VERSION)"; \
				echo -e "$(CYAN)\nTagging new version... [$(CURRENT_VERSION)->$(NEW_VERSION)]$(RESET)"; \
				$(GIT) tag -a v$(NEW_VERSION) -m "Release version $(NEW_VERSION)"; \
				echo -e "$(GREEN)New version tagged.$(RESET)"; \
				;; \
			*) \
				echo -e "$(RED)Invalid version argument.$(RESET)"; \
				echo -e "$(RED)\nUsage: make tag ARGS=\"patch|minor|major\"$(RESET)"; \
				exit 1; \
				;; \
		esac; \
	else \
		echo -e "$(YELLOW)\nNo new release needed.$(RESET)"; \
	fi

.PHONY: release
release: | dep/git  ## Push the tagged version to origin - triggers the release and docker actions
	@if [ -z "$(GREP)" ] || [ -z "$(AWK)" ]; then \
		echo -e "$(RED)Error: Required tools (grep, awk) not found.$(RESET)"; \
		exit 1; \
	fi
	@$(eval TAG := $(shell $(GIT) describe --tags --abbrev=0))
	@$(eval REMOTE_TAGS := $(shell $(GIT) ls-remote --tags origin | $(AWK) '{print $$2}'))
	@if [ -z "$(TAG)" ]; then \
		echo -e "$(RED)Error: No tags found. Please create a tag first with 'make tag'.$(RESET)"; \
		exit 1; \
	fi
	@if echo $(REMOTE_TAGS) | $(GREP) -q $(TAG); then \
		echo -e "$(YELLOW)\nNothing to push: tag $(TAG) already exists on origin.$(RESET)"; \
	else \
		echo -e "$(CYAN)\nPushing new release $(TAG)...$(RESET)"; \
		$(GIT) push origin; \
		$(GIT) push origin $(TAG); \
		echo -e "$(GREEN)Release $(TAG) pushed.$(RESET)"; \
	fi

#-- Docker

.PHONY: docker-build
docker-build: dep/docker dep/docker-compose $(INSTALL_STAMP) $(DEPS_EXPORT_STAMP) $(DOCKER_BUILD_STAMP)  ## Build the Docker image
$(DOCKER_BUILD_STAMP): $(DOCKER_FILE) $(DOCKER_COMPOSE_FILE)
	@echo -e "$(CYAN)\nBuilding the Docker image...$(RESET)"
	@DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) DOCKER_CONTAINER_NAME=$(DOCKER_CONTAINER_NAME) $(DOCKER_COMPOSE) build
	@echo -e "$(GREEN)Docker image built.$(RESET)"
	@touch $(DOCKER_BUILD_STAMP)

.PHONY: docker-run
docker-run: dep/docker $(DOCKER_BUILD_STAMP)  ## Run the Docker container
	@echo -e "$(CYAN)\nRunning the Docker container...$(RESET)"
	@DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) DOCKER_CONTAINER_NAME=$(DOCKER_CONTAINER_NAME) ARGS="$(ARGS)" $(DOCKER_COMPOSE) up
	@echo -e "$(GREEN)Docker container executed.$(RESET)"

.PHONY: docker-shell
docker-shell: | dep/docker  ## Open shell in running Docker container
	@echo -e "$(CYAN)\nOpening shell in Docker container...$(RESET)"
	@if [ -z "$$($(DOCKER) ps -q -f name=$(DOCKER_CONTAINER_NAME))" ]; then \
		echo -e "$(RED)Container $(DOCKER_CONTAINER_NAME) is not running.$(RESET)"; \
		echo -e "$(YELLOW)Start it with 'make docker-run' first.$(RESET)"; \
		exit 1; \
	fi
	@$(DOCKER) exec -it $(DOCKER_CONTAINER_NAME) /bin/bash || $(DOCKER) exec -it $(DOCKER_CONTAINER_NAME) /bin/sh

.PHONY: docker-logs
docker-logs: | dep/docker  ## Show Docker container logs (use ARGS="--follow" to stream logs)
	@echo -e "$(CYAN)\nShowing Docker container logs...$(RESET)"
	@if [ -z "$$($(DOCKER) ps -aq -f name=$(DOCKER_CONTAINER_NAME))" ]; then \
		echo -e "$(RED)Container $(DOCKER_CONTAINER_NAME) does not exist.$(RESET)"; \
		echo -e "$(YELLOW)Build and run it with 'make docker-all' first.$(RESET)"; \
		exit 1; \
	fi
	@$(DOCKER) logs $(ARGS) $(DOCKER_CONTAINER_NAME)

.PHONY: docker-all
docker-all: docker-build docker-run  ## Build and run the Docker container

.PHONY: docker-stop
docker-stop: | dep/docker dep/docker-compose  ## Stop the Docker container
	@echo -e "$(CYAN)\nStopping the Docker container...$(RESET)"
	@DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) DOCKER_CONTAINER_NAME=$(DOCKER_CONTAINER_NAME) $(DOCKER_COMPOSE) down
	@echo -e "$(GREEN)Docker container stopped.$(RESET)"

.PHONY: docker-remove
docker-remove: | dep/docker dep/docker-compose  ## Remove the Docker image, container, and volumes
	@echo -e "$(CYAN)\nRemoving the Docker image...$(RESET)"
	@DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) DOCKER_CONTAINER_NAME=$(DOCKER_CONTAINER_NAME) $(DOCKER_COMPOSE) down -v --rmi all
	@rm -f $(DOCKER_BUILD_STAMP)
	@echo -e "$(GREEN)Docker image removed.$(RESET)"

#-- Documentation

.PHONY: docs-build
docs-build: dep/uv $(DOCS_STAMP)  ## Generate the project documentation
$(DOCS_STAMP): $(DOCS_FILES) mkdocs.yml
	@echo -e "$(CYAN)\nGenerating the project documentation...$(RESET)"
	@if ! cmp -s README.md $(DOCS)/index.md; then \
		echo -e "$(YELLOW)Syncing README.md with $(DOCS)/index.md$(RESET)"; \
		cp README.md $(DOCS)/index.md; \
	fi
	@$(UV) run mkdocs build $(ARGS)
	@echo -e "$(GREEN)Project documentation generated.$(RESET)"
	@touch $(DOCS_STAMP)

.PHONY: docs-serve
docs-serve: dep/uv $(DOCS_STAMP)  ## Serve the project documentation locally
	@echo -e "$(CYAN)\nServing the project documentation...$(RESET)"
	@$(UV) run mkdocs serve --watch $(SRC) $(ARGS)

.PHONY: docs-publish
docs-publish: dep/uv $(DOCS_STAMP)  ## Publish the project documentation to GitHub Pages (use ARGS="--force" to force the deployment)
	@echo -e "$(CYAN)\nPublishing the project documentation to GitHub Pages...$(RESET)"
	@$(UV) run mkdocs gh-deploy $(ARGS)
	@echo -e "$(GREEN)Project documentation published.$(RESET)"
