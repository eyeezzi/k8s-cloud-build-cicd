# The environment this Makefile runs in must have:
# - make, bash, openssl, kubectl
PROJECT_ID := k8s-cicd-251209
SERVICE_SHORT_NAME := polite
SERVICE_LONG_NAME := ${PROJECT_ID}/${SERVICE_SHORT_NAME}
IMAGE_URL := gcr.io/${SERVICE_LONG_NAME}
COMMIT_SHA := $(shell echo $${SHORT_SHA:-$$(git rev-parse --short HEAD)})

K8S_YAMLS_LOCATION := ./k8s

.PHONY: update-deployment-image
update-deployment-image: CONTAINER=polite
update-deployment-image:
	@files=$$(find ${K8S_YAMLS_LOCATION} -type f \( -name "*.yml" -or -name "*.yaml" \) | grep deployment); \
	for i in $$files; do \
		patched=`openssl rand -hex 8`; \
		kubectl patch -f $$i -p '{"spec":{"template":{"spec":{"containers":[{"name":"${CONTAINER}","image":"${IMAGE_URL}:${COMMIT_SHA}"}]}}}}' --local -o yaml > $$patched; \
		mv -f $$patched $$i; \
	done

.PHONY: apply-staging-files
apply-staging-files: KUBECONFIG:=${K8S_YAMLS_LOCATION}/polite.deployer.staging.kubeconfig.yml
apply-staging-files:
	files=$$(find ${K8S_YAMLS_LOCATION} -type f \( -name "*.yml" -or -name "*.yaml" \) | grep staging); \
	echo "$$files" | xargs -I {} kubectl --kubeconfig=${KUBECONFIG} --token=${DEPLOYER_TOKEN} apply -f {}

.PHONY: cat
cat:
	cat ${K8S_YAMLS_LOCATION}/staging-deployment.yaml