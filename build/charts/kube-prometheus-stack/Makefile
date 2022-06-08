
CRD_IMG ?= reg.docker.alibaba-inc.com/cip/kube-prometheus-stack-crds
CRD_TAG ?= v30.0.1
BUILDX_PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: build-upgrade-crds-image
build-upgrade-crds-image:
	docker buildx build -f dockerfiles/Dockerfile-upgrade-crds --pull --push --platform $(BUILDX_PLATFORMS) -t $(CRD_IMG):$(CRD_TAG) .