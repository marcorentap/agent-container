# syntax=docker/dockerfile:1
###############################################################################
# agent-container — Ubuntu 24.04 LTS base with oh-my-pi and a non-root agent
#
# NOTE: Ubuntu 26.04 LTS does not exist yet; this image targets 24.04 (Noble
# Numbat), the latest available LTS.  Switch the FROM line to ubuntu:26.04
# when that release ships.
#
# Build:
#   docker build -t agent-container .
#
# Run (bind-mounts $HOME → /home/agent/host):
#   docker run --rm -it -v "$HOME:/home/agent/host" agent-container
###############################################################################
FROM ubuntu:24.04

# ── Environment ────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ── System packages ────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        locales \
        sudo \
        unzip \
        zsh \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ── Non-root user ──────────────────────────────────────────────────────────
# UID/GID are not pinned; they do not need to match the host.
RUN useradd --create-home --shell /usr/bin/zsh agent \
    && echo 'agent ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent \
    && chmod 0440 /etc/sudoers.d/agent

# ── Switch to agent user for all subsequent steps ─────────────────────────
USER agent
WORKDIR /home/agent

ENV HOME=/home/agent \
    PATH="/home/agent/.local/bin:${PATH}"

# ── Install oh-my-pi ───────────────────────────────────────────────────────
# The install script defaults to the prebuilt binary when bun is absent.
# Passing --binary makes the choice explicit and keeps the image small.
RUN curl -fsSL https://omp.sh/install | sh -s -- --binary

# ── Shell configuration ────────────────────────────────────────────────────
RUN printf '%s\n' \
    '# ~/.zshrc — agent container' \
    '' \
    '# oh-my-pi completions' \
    'if command -v omp >/dev/null 2>&1; then' \
    '  eval "$(omp completions zsh)"' \
    'fi' \
    > /home/agent/.zshrc

# ── Runtime ────────────────────────────────────────────────────────────────
# Host $HOME is expected to be bind-mounted at /home/agent/host at run time.
VOLUME ["/home/agent/host"]

CMD ["zsh"]
