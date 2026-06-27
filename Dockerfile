# syntax=docker/dockerfile:1
###############################################################################
# agent-container — Ubuntu 24.04 LTS development environment for coding agents
#
# ⚠  Ubuntu 26.04 LTS does not exist yet. This image targets Ubuntu 24.04
#    (Noble Numbat), the latest available LTS. To upgrade, replace the FROM
#    line with `FROM ubuntu:26.04` when that release ships; no other changes
#    should be required.
#
# Included tooling:
#   build-essential, common dev utilities, Python 3, Go (latest stable),
#   nvm (Node NOT pre-installed — use .nvmrc per project),
#   oh-my-zsh, oh-my-pi (omp binary)
#
# Build args:
#   DOTFILES_REPO  Git URL for your dotfiles (optional).
#                  Cloned to ~/.dotfiles; runs install.sh or setup.sh if found.
#
# Build:
#   docker build -t agent-container .
#   docker build --build-arg DOTFILES_REPO=https://github.com/you/dotfiles \
#                -t agent-container .
#
# Run (bind-mounts host $HOME → /home/agent/host):
#   docker run --rm -it -v "$HOME:/home/agent/host" agent-container
###############################################################################

# Set before FROM so BuildKit populates it for multi-platform builds.
ARG TARGETARCH=amd64

FROM ubuntu:24.04

# Re-declare after FROM — ARG values don't cross the FROM boundary.
ARG TARGETARCH=amd64
ARG DOTFILES_REPO=""

# ── Environment ────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ── System packages (root) ─────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # TLS / fetching
        ca-certificates \
        curl \
        wget \
        # VCS
        git \
        git-lfs \
        # Archives
        unzip \
        zip \
        xz-utils \
        # Shell
        zsh \
        # Build
        build-essential \
        pkg-config \
        cmake \
        make \
        # Dev utilities
        jq \
        ripgrep \
        fd-find \
        bat \
        htop \
        tmux \
        vim \
        neovim \
        tree \
        less \
        file \
        # Python (scripting / tool dependencies)
        python3 \
        python3-pip \
        python3-venv \
        # Network / auth
        openssh-client \
        gnupg \
        # Admin / locale
        locales \
        sudo \
        man-db \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu ships bat as `batcat` and fd as `fdfind` to avoid naming conflicts.
# Create canonical aliases so tooling that expects `bat`/`fd` works out of the box.
RUN ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd

# ── Go — latest stable, installed system-wide ──────────────────────────────
# TARGETARCH matches Go's naming for common targets (amd64, arm64).
RUN set -eux; \
    GO_VERSION="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)"; \
    echo "Installing ${GO_VERSION} for linux/${TARGETARCH}"; \
    curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
        | tar -C /usr/local -xz; \
    /usr/local/go/bin/go version

# ── Non-root agent user ─────────────────────────────────────────────────────
RUN useradd --create-home --shell /usr/bin/zsh agent \
    && echo 'agent ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent \
    && chmod 0440 /etc/sudoers.d/agent

# ── All remaining steps run as agent ───────────────────────────────────────
USER agent
WORKDIR /home/agent

ENV HOME=/home/agent \
    GOPATH=/home/agent/go \
    NVM_DIR=/home/agent/.nvm \
    PATH="/home/agent/.local/bin:/home/agent/go/bin:/usr/local/go/bin:${PATH}"

# ── nvm — Node Version Manager (Node NOT pre-installed) ────────────────────
# PROFILE=/dev/null stops the installer from patching .bashrc / .profile;
# we add the nvm init block to .zshrc ourselves below.
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh \
        | PROFILE=/dev/null bash

# ── oh-my-zsh ───────────────────────────────────────────────────────────────
# --unattended: skips the interactive prompt, keeps the existing shell.
RUN sh -c "$(curl -fsSL \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended

# ── oh-my-pi (omp) — binary install ─────────────────────────────────────────
RUN curl -fsSL https://omp.sh/install | sh -s -- --binary

# ── Dotfiles (optional) ──────────────────────────────────────────────────────
# Pass --build-arg DOTFILES_REPO=<url> to embed your dotfiles into the image.
# Convention: runs install.sh or setup.sh if either exists at the repo root.
RUN if [ -n "${DOTFILES_REPO}" ]; then \
        git clone "${DOTFILES_REPO}" "${HOME}/.dotfiles" \
        && if [ -f "${HOME}/.dotfiles/install.sh" ]; then \
               sh "${HOME}/.dotfiles/install.sh"; \
           elif [ -f "${HOME}/.dotfiles/setup.sh" ]; then \
               sh "${HOME}/.dotfiles/setup.sh"; \
           fi; \
    fi

# ── .zshrc additions ─────────────────────────────────────────────────────────
# Appended after the optional dotfile install so these blocks are always
# present, even if dotfiles replaced .zshrc with their own version.
RUN printf '%s\n' \
    '' \
    '# ── agent-container ─────────────────────────────────────────────────────' \
    '' \
    '# Go' \
    'export GOPATH="${HOME}/go"' \
    'export PATH="/usr/local/go/bin:${GOPATH}/bin:${PATH}"' \
    '' \
    '# nvm — Node Version Manager (Node itself is NOT pre-installed)' \
    '# Run `nvm install` or add an .nvmrc in your project to get Node.' \
    'export NVM_DIR="${HOME}/.nvm"' \
    '[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"' \
    '[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"' \
    '' \
    '# oh-my-pi completions' \
    'if command -v omp >/dev/null 2>&1; then' \
    '  eval "$(omp completions zsh)"' \
    'fi' \
    >> "${HOME}/.zshrc"

# ── Runtime ─────────────────────────────────────────────────────────────────
# Host $HOME is bind-mounted here at run time; declare as a volume hint.
VOLUME ["/home/agent/host"]

CMD ["zsh"]
