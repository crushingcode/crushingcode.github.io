.PHONY: help serve build post update-theme tidy

help:
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

serve: ## Serve the site locally with hot-reload
	./scripts/serve_local.sh

build: ## Build the site for production
	hugo

post: ## Create a new blog post
	./scripts/create_post.sh

update-theme: ## Update the Hugo theme to the latest version
	./scripts/update_theme.sh

tidy: ## Tidy Hugo module dependencies
	hugo mod tidy
