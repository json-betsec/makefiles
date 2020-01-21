export MF_PROJECT_ROOT := $(realpath $(dir $(word 1,$(MAKEFILE_LIST))))
export MF_ROOT := $(MF_PROJECT_ROOT)/.makefiles
export PATH := $(MF_ROOT)/lib/core/bin:$(PATH)

# MF_CI is the name of any detected continuous integration system. If no CI
# system is detected, MF_CI will be empty.
export MF_CI ?= $(shell PATH="$(PATH)" ci-system-name)

# MF_NON_INTERACTIVE will be non-empty when make is not running under an
# interactive shell.
ifeq ($(MF_CI),)
export MF_NON_INTERACTIVE ?= $(shell [ -t 0 ] || echo true)
else
export MF_NON_INTERACTIVE ?= true
endif

# Run tests by default unless the project's main Makefile has already defined a
# default goal.
ifeq ($(.DEFAULT_GOAL),)
.DEFAULT_GOAL := test
endif

.SECONDEXPANSION:

# PROJECT_NAME is a short name for the project. It defaults to the name of the
# directory that the project is in.
PROJECT_NAME ?= $(notdir $(MF_PROJECT_ROOT))

# GENERATED_FILES is a space separated list of files that are generated by
# the Makefile and are intended to be committed to the repository.
GENERATED_FILES +=

# CI_VERIFY_GENERATED_FILES, if non-empty, causes the "ci" target to check that
# the files in GENERATED_FILES are up-to-date.
CI_VERIFY_GENERATED_FILES ?= true

# GIT_HEAD_HASH is the full-length hash of the HEAD commit.
GIT_HEAD_HASH_FULL ?= $(shell git rev-parse --verify HEAD)

# GIT_HEAD_HASH is the abbreviated (7-digit) hash of the HEAD commit.
GIT_HEAD_HASH ?= $(shell git rev-parse --short --verify HEAD)

# GIT_HEAD_BRANCH is the name of the current branch. It is empty if the HEAD is
# detached (that is, no specific branch is checked out).
GIT_HEAD_BRANCH ?= $(shell git symbolic-ref --short HEAD 2>/dev/null)

# GIT_HEAD_BRANCH is the name of the current tag. It is empty if the HEAD is
# not pointed to by a tag.
GIT_HEAD_TAG ?= $(if $(GIT_HEAD_BRANCH),,$(shell git describe --exact-match HEAD 2>/dev/null))

# GIT_HEAD_COMMITTISH is the "best" representation of the HEAD commit. If HEAD
# is a branch or tag, this will be the branch or tag name. Otherwise it will be
# the commit hash.
GIT_HEAD_COMMITTISH	?= $(or $(GIT_HEAD_BRANCH),$(GIT_HEAD_TAG),$(GIT_HEAD_HASH))

# clean --- Removes all generated and ignored files. Individual language
# Makefiles should also remove any build artifacts that aren't already ignored.
.PHONY: clean
clean::
ifneq ($(GENERATED_FILES),)
	$(MAKE) --no-print-directory clean-generated
endif
	$(MAKE) --no-print-directory clean-ignored

# clean-generated --- Removes all files in the GENERATED_FILES list.
.PHONY: clean-generated
clean-generated::
ifneq ($(GENERATED_FILES),)
	rm -f -- $(GENERATED_FILES)
endif

# clean-ignored --- Removes all files ignored by .gitignore files within the
# repository. It does not remove any files that are ignored due to rules in
# global ignore configurations.
.PHONY: clean-ignored
clean-ignored::
	git-find-ignored '*' | xargs -t -n1 rm -rf --

# regenerate --- Removes and regenerates all files in the GENERATED_FILES list.
.PHONY: regenerate
regenerate:: clean-generated
ifneq ($(GENERATED_FILES),)
	$(MAKE) --no-print-directory -- $(GENERATED_FILES)
endif

# test --- Executes all tests.
# Individual language Makefiles are expected to add additional recipies for this
# target.
.PHONY: test
test::

# lint --- Check for syntax, configuration, code style and/or formatting issues.
# Individual language Makefiles are expected to add additional recipies for this
# target.
.PHONY: lint
lint::

# precommit --- Perform tasks that need to be executed before committing.
# Individual language Makefiles are expected to add additional recipies for this
# target.
.PHONY: precommit
precommit:: $(GENERATED_FILES)

# ci --- Perform tasks that need to be executed within a continuous integration
# environment. Individual language Makefiles are expected to add additional
# recipies for this target.
.PHONY: ci
ci::
ifneq ($(CI_VERIFY_GENERATED_FILES),)
ifneq ($(GENERATED_FILES),)
	@echo "--- checking for out-of-date generated files"
	@$(MAKE) --no-print-directory regenerate
	@git diff -- $(GENERATED_FILES)
	@!(git status --porcelain -- $(GENERATED_FILES) | grep .)
endif
endif
