.PHONY: ci up docker front back compose '*' help

# Optional: SOURCE=front|back|*  (default *)
# Also supports: make ci front | make up back | make docker compose
SOURCE ?= *
GOAL := $(firstword $(MAKECMDGOALS))
ARG := $(word 2,$(MAKECMDGOALS))

ifeq ($(GOAL),ci)
  ifneq ($(ARG),)
    SOURCE := $(ARG)
  endif
endif

ifeq ($(GOAL),up)
  ifneq ($(ARG),)
    SOURCE := $(ARG)
  endif
endif

ifeq ($(GOAL),docker)
  ifneq ($(ARG),)
    SOURCE := $(ARG)
  endif
endif

# Normalize aliases
ifeq ($(SOURCE),backend)
  SOURCE := back
endif
ifeq ($(SOURCE),frontend)
  SOURCE := front
endif
ifeq ($(SOURCE),all)
  SOURCE := *
endif

help:
	@echo "Targets:"
	@echo "  make ci [front|back|*]          Run local CI checks"
	@echo "  make up [front|back|*]          docker compose up --build"
	@echo "  make docker front|back|compose  Build image(s)"
	@echo "  Also: make ci SOURCE=back"

ci:
ifeq ($(SOURCE),front)
	@$(MAKE) --no-print-directory _ci-front
else ifeq ($(SOURCE),back)
	@$(MAKE) --no-print-directory _ci-back
else
	@$(MAKE) --no-print-directory _ci-front
	@$(MAKE) --no-print-directory _ci-back
endif

_ci-front:
	@echo "==> frontend: lint"
	cd frontend && pnpm install --frozen-lockfile
	cd frontend && pnpm lint
	@echo "==> frontend: typecheck"
	cd frontend && pnpm typecheck
	@echo "==> frontend: test"
	cd frontend && pnpm test
	@echo "==> frontend: build"
	cd frontend && pnpm build

_ci-back:
	@echo "==> backend: sync"
	cd backend && uv sync --group dev
	@echo "==> backend: ruff check"
	cd backend && uv run ruff check .
	@echo "==> backend: ruff format"
	cd backend && uv run ruff format --check .
	@echo "==> backend: test (coverage >= 70%)"
	cd backend && uv run pytest --cov=app --cov-fail-under=70

up:
ifeq ($(SOURCE),front)
	docker compose up --build frontend
else ifeq ($(SOURCE),back)
	docker compose up --build backend
else
	docker compose up --build
endif

docker:
ifeq ($(SOURCE),front)
	docker build -t slm-frontend ./frontend
else ifeq ($(SOURCE),back)
	docker build -t slm-backend ./backend
else ifeq ($(SOURCE),compose)
	docker compose build
else
	@echo "Usage: make docker front|back|compose"
	@exit 1
endif

# Swallow positional args so "make up back" does not fail
front back compose '*':
	@:
