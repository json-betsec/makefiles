# DOCKER_REPO is the fully-qualified Docker repository name.
ifndef DOCKER_REPO
$(error "DOCKER_REPO must be defined in the project's Makefile.")
endif

# DOCKER_TAGS is a space-separated list of tag names used when building a Docker
# image. The list defaults to just 'dev'. Note that the 'dev' tag cannot be
# pushed to the registry.
DOCKER_TAGS ?= dev

# DOCKER_BUILD_REQ is a space separated list of prerequisites needed to build
# the Docker image.
DOCKER_BUILD_REQ +=

# DOCKER_BUILD_ARGS is a space separate list of additional arguments to pass to
# the "docker build" command.
DOCKER_BUILD_ARGS +=

################################################################################

# _DOCKER_TAG_TOUCH_FILES is a list of touch files for tagging Docker builds.
# The list is automatically generated from DOCKER_TAGS.
_DOCKER_TAG_TOUCH_FILES := $(foreach TAG,$(DOCKER_TAGS),artifacts/docker/tag/$(TAG).touch)

# _DOCKER_PUSH_TOUCH_FILES is a list of touch files for pushing Docker tags. The
# list is automatically generated from DOCKER_TAGS.
_DOCKER_PUSH_TOUCH_FILES := $(foreach TAG,$(DOCKER_TAGS),artifacts/docker/push/$(TAG).touch)

################################################################################

# docker --- Builds a docker image from the Dockerfile in the root of the
# repository.
.PHONY: docker
docker: $(_DOCKER_TAG_TOUCH_FILES)

# docker-build --- Builds a docker image from the Dockerfile in the root of the
# repository and pushes it to the registry.
.PHONY: docker-push
docker-push: $(_DOCKER_PUSH_TOUCH_FILES)

################################################################################

# Treat any dependencies of the Docker build as secondary build targets so that
# they are not deleted after a successful build.
.SECONDARY: $(DOCKER_BUILD_REQ)

.dockerignore:
	@echo .makefiles > "$@"
	@echo .git >> "$@"

artifacts/docker/image-id: Dockerfile .dockerignore $(DOCKER_BUILD_REQ)
	@mkdir -p "$(@D)"

	docker build \
		--pull \
		--build-arg "VERSION=$(GIT_HEAD_COMMITTISH)" \
		--iidfile "$@" \
		$(DOCKER_BUILD_ARGS) \
		.

artifacts/docker/tag/%.touch: artifacts/docker/image-id
	docker tag "$(shell cat "$<")" "$(DOCKER_REPO):$*"
	@mkdir -p "$(@D)"
	@touch "$@"

.PHONY: artifacts/docker/push/dev.touch
artifacts/docker/push/dev.touch:
	@echo "The 'dev' tag can not be pushed to the registry!"
	@exit 1

artifacts/docker/push/%.touch: artifacts/docker/tag/%.touch
	docker push "$(DOCKER_REPO):$*"
	@mkdir -p "$(@D)"
	@touch "$@"
