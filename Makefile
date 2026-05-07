# crossplane-akeyless regeneration via iac-forge.
#
# This repo is a pure autogen output of the akeyless TOML resource specs
# (`pleme-io/akeyless-terraform-resources/resources/`) + the akeyless
# OpenAPI 3.0 spec (`pleme-io/akeyless-go/api/openapi.yaml`).
#
# `make regenerate` is the single source of truth for every .go / .yaml
# file in the tree (excluding LICENSE, CLAUDE.md, flake.nix, flake.lock,
# Makefile, .envrc, .gitignore — the substrate scaffolding).

SPEC          ?= /tmp/akeyless-openapi.json
RESOURCES_DIR ?= ../akeyless-terraform-resources/resources
PROVIDER_TOML ?= ../akeyless-terraform-resources/provider.toml
OUT_DIR       ?= .forge-gen-out

.PHONY: regenerate verify clean help

help: ## Show this help
	@awk 'BEGIN{FS=":.*?##"} /^[a-zA-Z_-]+:.*?##/{printf "  %-12s %s\n",$$1,$$2}' $(MAKEFILE_LIST)

regenerate: ## Regenerate the entire provider from akeyless-terraform-resources TOML + akeyless OpenAPI
	@if [ ! -f $(SPEC) ]; then \
		echo "Spec missing at $(SPEC) — converting akeyless-go/api/openapi.yaml → JSON"; \
		yq -o json '.' ../akeyless-go/api/openapi.yaml > $(SPEC); \
	fi
	@rm -rf $(OUT_DIR)
	nix shell nixpkgs#openapi-generator-cli --command \
	  iac-forge generate \
	    --backend crossplane \
	    --spec $(SPEC) \
	    --resources $(RESOURCES_DIR) \
	    --provider $(PROVIDER_TOML) \
	    --output $(OUT_DIR)
	@cp -r $(OUT_DIR)/. .
	@rm -rf $(OUT_DIR)
	@echo ""
	@echo "Regeneration complete. Verify with: make verify"

verify: ## Build sanity check
	go mod tidy
	go build ./...
	@echo ""
	@echo "Build clean. Provider compiles end-to-end."

clean: ## Remove regen scratch dir
	rm -rf $(OUT_DIR)
