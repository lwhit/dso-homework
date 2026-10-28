.DEFAULT_GOAL := help
PODINFO_REPO := https://stefanprodan.github.io/podinfo
PODINFO_CHART := podinfo/podinfo
PODINFO_NAMESPACE := podinfo
NGINX_NAMESPACE := nginx


.PHONY: deploy_podinfo
deploy_podinfo: ## Deploy podinfo application
	$(MAKE) _check_helm
	helm repo add podinfo $(PODINFO_REPO) --force-update
	helm upgrade --install pod-r1 \
		--namespace $(PODINFO_NAMESPACE) \
		--create-namespace \
		--values values.yaml \
		--wait --timeout 120s \
		$(PODINFO_CHART)
 
.PHONY: update_podinfo
update_podinfo: ## Update pod replicas
	$(MAKE) _check_helm
	$(MAKE) _validate_config
	helm upgrade --install pod-r1 \
		--namespace $(PODINFO_NAMESPACE) \
		--values values.yaml \
		--wait --timeout 120s \
		$(PODINFO_CHART)

.PHONY: deploy_backend
deploy_backend: ## Deploy backend services
	$(MAKE) _check_kubectl
	[ -d "./manifests" ] || (echo "manifests/ directory not found" && exit 1)
	kubectl get namespace nginx >/dev/null 2>&1 || kubectl create namespace nginx

	kubectl apply \
		--namespace $(NGINX_NAMESPACE) \
		-f ./manifests
	kubectl rollout status deployment/nginx \
		--namespace $(NGINX_NAMESPACE) \
		--timeout=120s

	$(MAKE) deploy_podinfo
	$(MAKE) update_podinfo

	kubectl run podinfo-echo-test \
		--namespace $(PODINFO_NAMESPACE) \
		--image=curlimages/curl:8.12.1 \
		--restart=Never --rm -i \
		--command -- sh -ec '\
			response=$$(curl --fail --silent --show-error \
				-X POST http://pod-r1-podinfo:5050/echo \
				-H "Content-Type: text/plain" \
				--data "echo-test"); \
			echo -e "echo-test response:\n$$response"; \
			echo "$$response" | grep -q "hello world" '


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
