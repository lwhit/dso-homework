.DEFAULT_GOAL := help

# Main targets that candidates should implement
.PHONY: deploy_podinfo
deploy_podinfo: ## Deploy podinfo application
	$(MAKE) _check_helm
	helm repo add podinfo https://stefanprodan.github.io/podinfo
	helm upgrade --install --wait pod-r1 \
		--namespace podinfo \
		--create-namespace \
		podinfo/podinfo
 
.PHONY: update_podinfo
update_podinfo: ## Update pod replicas
	$(MAKE) _validate_config
	helm upgrade pod-r1 \
		--namespace podinfo \
		podinfo/podinfo \
		-f values.yaml

.PHONY: deploy_backend
deploy_backend: ## Deploy backend services
	$(MAKE) _check_kubectl
	[ -d "./manifests" ] || (echo "manifests/ directory not found" && exit 1)
	kubectl get namespace nginx >/dev/null 2>&1 || kubectl create namespace nginx
	kubectl apply \
		--namespace nginx \
		-f ./manifests
	$(MAKE) deploy_podinfo
	$(MAKE) update_podinfo
	

# Internal helper targets (prefixed with _)
.PHONY: _check_kubectl
_check_kubectl: ## Verify kubectl is installed
	which kubectl > /dev/null || (echo "kubectl not found" && exit 1)

.PHONY: _check_helm
_check_helm: ## Verify helm is installed
	which helm > /dev/null || (echo "helm not found" && exit 1)

.PHONY: _validate_config
_validate_config: ## Validate configuration files
	[ -f values.yaml ] || (echo "values.yaml not found" && exit 1)

# Help targets
.PHONY: help
help: ## Show available main targets
	echo "Available targets:"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		grep -v '^_' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	echo ""
	echo "Run 'make internal-help' to see internal helper targets"

.PHONY: internal-help
internal-help: ## Show internal helper targets
	echo "Internal helper targets:"
	grep -E '^_[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-20s\033[0m %s\n", $$1, $$2}'
