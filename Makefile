IMAGE   ?= agent-container
CONTAINER ?= agent

# Default target: build then launch an interactive session.
.DEFAULT_GOAL := run

# ── Build ──────────────────────────────────────────────────────────────────
.PHONY: build
build:
	docker build -t $(IMAGE) .

# ── Run ────────────────────────────────────────────────────────────────────
# Starts a fresh interactive container with the host HOME bind-mounted.
# Equivalent to: docker-compose run --rm agent
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
