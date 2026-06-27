IMAGE         ?= agent-container
CONTAINER     ?= agent
DOTFILES_REPO ?=

# Pass --build-arg DOTFILES_REPO=... only when set; avoids an empty-string arg.
_DOTFILES_ARG := $(if $(DOTFILES_REPO),--build-arg DOTFILES_REPO=$(DOTFILES_REPO),)

# Default target: build then launch an interactive session.
.DEFAULT_GOAL := run

# ── Build ──────────────────────────────────────────────────────────────────
.PHONY: build
build:
	docker build $(_DOTFILES_ARG) -t $(IMAGE) .

# ── Run ────────────────────────────────────────────────────────────────────
# Builds if needed, then launches an interactive zsh session.
# Host $HOME is bind-mounted read-write at /home/agent/host inside the container.
.PHONY: run
run: build
	docker run --rm -it \
		--name $(CONTAINER) \
		-v "$(HOME):/home/agent/host" \
		$(IMAGE)

# ── Exec ───────────────────────────────────────────────────────────────────
# Open a shell inside an already-running container.
.PHONY: exec
exec:
	docker exec -it $(CONTAINER) zsh

# ── Clean ──────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	docker rmi $(IMAGE) || true
