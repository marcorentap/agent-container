# agent-container

Ubuntu 24.04 LTS Docker development environment for coding agents — batteries included.

> **Ubuntu note:** This image targets Ubuntu 24.04 (Noble Numbat), the latest available LTS.  
> Ubuntu 26.04 does not exist yet. Update the `FROM` line in `Dockerfile` to `ubuntu:26.04` once it ships.

---

## What's inside

| Component | Details |
|-----------|---------|
| Base image | `ubuntu:24.04` |
| User | `agent` (non-root, passwordless `sudo`) |
| Home | `/home/agent` (`$HOME` inside the container) |
| Shell | `zsh` with oh-my-zsh |
| Host `$HOME` | Bind-mounted (read/write) at `/home/agent/host` at runtime |
| [oh-my-pi](https://omp.sh) (`omp`) | Installed to `/home/agent/.local/bin/omp`; completions wired |
| Go | Latest stable, installed to `/usr/local/go`; `GOPATH=$HOME/go` |
| nvm | Installed; **Node.js is NOT pre-installed** — use `.nvmrc` per project |
| Build tools | `build-essential`, `cmake`, `make`, `pkg-config` |
| Dev utilities | `git`, `git-lfs`, `jq`, `ripgrep` (`rg`), `fd`, `bat`, `tmux`, `vim`, `neovim`, `htop`, `tree` |
| Python | `python3`, `pip`, `venv` |
| LSP binaries | **Not pre-installed** — install per-project as needed |
| Docker-in-Docker | **Not included** |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) 24+
- `make` (optional — you can invoke Docker directly)

---

## Quick start

```sh
# Build and launch an interactive zsh session
make

# With your dotfiles baked into the image
make DOTFILES_REPO=https://github.com/you/dotfiles
```

Host `$HOME` is available inside the container at `/home/agent/host`.

---

## Build args

| Arg | Default | Description |
|-----|---------|-------------|
| `DOTFILES_REPO` | _(empty)_ | Git URL of your dotfiles repository. Cloned to `~/.dotfiles`; `install.sh` or `setup.sh` is run if found at the repo root. |

Build with dotfiles:

```sh
docker build \
  --build-arg DOTFILES_REPO=https://github.com/you/dotfiles \
  -t agent-container .
```

---

## Makefile targets

| Target | Description |
|--------|-------------|
| `make` / `make run` | Build (if needed) and launch an interactive `zsh` session |
| `make build` | Build or rebuild the image |
| `make exec` | Open a shell inside an already-running container |
| `make clean` | Remove the local image |

Override any variable on the command line:

```sh
make run IMAGE=my-agent CONTAINER=my-agent-1 DOTFILES_REPO=https://github.com/you/dotfiles
```

---

## Plain Docker

```sh
# Build
docker build -t agent-container .

# Run
docker run --rm -it -v "$HOME:/home/agent/host" agent-container
```

---

## Node.js / nvm

`nvm` is installed but **no Node version is pre-installed**. To get Node inside the container:

```sh
# Install the version from .nvmrc in the current directory
nvm install

# Or install a specific version
nvm install 22
nvm use 22
```

---

## oh-my-pi (`omp`)

```sh
omp --help
omp chat       # start an interactive agent session
```

zsh completions load automatically on shell start.

---

## Go

Go is available system-wide:

```sh
go version
```

`GOPATH` is set to `~/go`; installed binaries land in `~/go/bin` (on `$PATH`).

---

## Accessing host files

The host `$HOME` is mounted read-write at `/home/agent/host`:

```sh
ls ~/host           # your host home directory
omp ~/host/myproject
```

---

## Customisation

- **Add system packages:** extend the `apt-get install` block in `Dockerfile`.
- **Persist the container:** remove `--rm` from the run command.
- **Additional bind mounts:** add `-v` flags to `docker run`.
- **Bake in dotfiles:** use `--build-arg DOTFILES_REPO=<url>` at build time.
