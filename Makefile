.PHONY: help install lint build link-check check clean serve install-lychee install-markdownlint install-act act act-lint act-build act-link-check

# Find act binary (workspace bin/ or system PATH)
ACT := $(shell if [ -x "bin/act" ]; then echo "bin/act"; elif command -v act >/dev/null 2>&1; then echo "act"; fi)

# Default target - show help
help:
	@echo "Documentation CI Commands"
	@echo "========================="
	@echo ""
	@echo "Main targets:"
	@echo "  make check          - Run all CI checks (lint + build + link-check)"
	@echo "  make lint           - Run markdown linting"
	@echo "  make build          - Build documentation site"
	@echo "  make link-check     - Check all links in built site"
	@echo "  make serve          - Start local development server"
	@echo ""
	@echo "GitHub Actions locally (using act):"
	@echo "  make act            - Run full workflow with act"
	@echo "  make act-lint       - Run only lint job with act"
	@echo "  make act-build      - Run only build job with act"
	@echo "  make act-link-check - Run only link-check job with act"
	@echo ""
	@echo "Setup targets:"
	@echo "  make install              - Install Python dependencies"
	@echo "  make install-tools        - Install all checking tools (markdownlint + lychee + act)"
	@echo "  make install-markdownlint - Install markdownlint only"
	@echo "  make install-lychee       - Install lychee only"
	@echo "  make install-act          - Install act only"
	@echo ""
	@echo "Utility targets:"
	@echo "  make clean          - Remove built site directory"
	@echo ""

# Install Python dependencies
install:
	@echo "Installing Python dependencies..."
	pip install --upgrade pip
	pip install -r requirements.txt

# Install all checking tools
install-tools: install-markdownlint install-lychee install-act

# Install markdownlint
install-markdownlint:
	@echo "Installing markdownlint-cli..."
	@if command -v npm >/dev/null 2>&1; then \
		npm install -g markdownlint-cli; \
		echo "[OK] markdownlint-cli installed"; \
	else \
		echo "[ERROR] npm not found. Install Node.js first."; \
		exit 1; \
	fi

# Install lychee link checker
install-lychee:
	@echo "Installing lychee..."
	@mkdir -p bin
	@if [ "$$(uname -s)" = "Linux" ]; then \
		curl -sSL https://github.com/lycheeverse/lychee/releases/download/v0.14.3/lychee-v0.14.3-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C bin; \
		echo "[OK] lychee installed to bin/lychee"; \
	elif [ "$$(uname -s)" = "Darwin" ]; then \
		curl -sSL https://github.com/lycheeverse/lychee/releases/download/v0.14.3/lychee-v0.14.3-x86_64-apple-darwin.tar.gz | tar -xz -C bin; \
		echo "[OK] lychee installed to bin/lychee"; \
	else \
		echo "[ERROR] Unsupported platform. Install lychee manually from https://github.com/lycheeverse/lychee"; \
		exit 1; \
	fi

# Install act (GitHub Actions locally)
install-act:
	@echo "Installing act..."
	@mkdir -p bin
	@if [ "$$(uname -s)" = "Linux" ]; then \
		curl -sSL https://github.com/nektos/act/releases/download/v0.2.69/act_Linux_x86_64.tar.gz | tar -xz -C bin; \
		echo "[OK] act installed to bin/act"; \
	elif [ "$$(uname -s)" = "Darwin" ]; then \
		curl -sSL https://github.com/nektos/act/releases/download/v0.2.69/act_Darwin_x86_64.tar.gz | tar -xz -C bin; \
		echo "[OK] act installed to bin/act"; \
	else \
		echo "[ERROR] Unsupported platform. Install act manually from https://github.com/nektos/act"; \
		exit 1; \
	fi

# Run markdown linting
lint:
	@echo "Running markdown linting..."
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint docs/ && echo "[OK] Markdown linting passed"; \
	else \
		echo "[ERROR] markdownlint-cli not installed. Run: make install-markdownlint"; \
		exit 1; \
	fi

# Build documentation site
build:
	@echo "Building documentation..."
	mkdocs build --strict
	@echo "[OK] Documentation built successfully"

# Check all links in the built site
link-check:
	@echo "Checking links..."
	@LYCHEE=$$(if [ -x "bin/lychee" ]; then echo "bin/lychee"; elif command -v lychee >/dev/null 2>&1; then echo "lychee"; fi); \
	if [ -z "$$LYCHEE" ]; then \
		echo "[ERROR] lychee not installed. Run: make install-lychee"; \
		exit 1; \
	fi; \
	$$LYCHEE --verbose \
			--no-progress \
			--accept 200,204,206,301,302,307,308,429 \
			--timeout 30 \
			--max-retries 3 \
			--exclude-mail \
			--exclude "example.com" \
			--exclude "localhost" \
			--exclude "127.0.0.1" \
			--exclude "nexus-cmdb.slack.com" \
			--exclude "docs.nexus-cmdb.io" \
			--exclude "yourapp.com" \
			--exclude "staging-cmdb.example.com" \
			--exclude "api.example.com" \
			--exclude "docs.example.com" \
			--exclude "github.com/example" \
			site/ && echo "[OK] Link checking passed"

# Run all CI checks in sequence
check: lint build link-check
	@echo ""
	@echo "=========================================="
	@echo "  All CI checks passed!"
	@echo "=========================================="

# Start local development server
serve:
	@echo "Starting development server..."
	@echo "Documentation will be available at http://127.0.0.1:8000"
	mkdocs serve

# Clean built site
clean:
	@echo "Cleaning built site..."
	rm -rf site/
	@echo "[OK] Cleaned"

# Run full GitHub Actions workflow locally with act
act:
	@echo "Running full workflow with act..."
	@if [ -z "$(ACT)" ]; then \
		echo "[ERROR] act not installed. Run: make install-act"; \
		exit 1; \
	fi
	@$(ACT) -W .github/workflows/docs-ci.yml

# Run only the lint job with act
act-lint:
	@echo "Running lint job with act..."
	@if [ -z "$(ACT)" ]; then \
		echo "[ERROR] act not installed. Run: make install-act"; \
		exit 1; \
	fi
	@$(ACT) -W .github/workflows/docs-ci.yml -j lint

# Run only the build job with act
act-build:
	@echo "Running build job with act..."
	@if [ -z "$(ACT)" ]; then \
		echo "[ERROR] act not installed. Run: make install-act"; \
		exit 1; \
	fi
	@$(ACT) -W .github/workflows/docs-ci.yml -j build

# Run only the link-check job with act
act-link-check:
	@echo "Running link-check job with act..."
	@if [ -z "$(ACT)" ]; then \
		echo "[ERROR] act not installed. Run: make install-act"; \
		exit 1; \
	fi
	@$(ACT) -W .github/workflows/docs-ci.yml -j link-check
