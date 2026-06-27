# agent-container

Ubuntu 24.04 LTS Docker container with [oh-my-pi](https://github.com/can1357/oh-my-pi) (`omp`) pre-installed, designed for interactive agent use.

> **Ubuntu note:** This image targets Ubuntu 24.04 (Noble Numbat), the latest available LTS.  
> Update the `FROM` line in `Dockerfile` to `ubuntu:26.04` once that release ships.

## What's inside

| Component | Details |
|-----------|---------|
| Base image | `ubuntu:24.04` |
| User | `agent` (non-root, passwordless `sudo`) |
| Home directory | `/home/agent` (`$HOME` inside the container) |
| Host `$HOME` | Bind-mounted at `/home/agent/host` at run time |
| Shell | `zsh` (default) |
| [oh-my-pi](https://omp.sh) | Installed to `/home/agent/.local/bin/omp` |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) 24+
- `make` (optional — you can invoke Docker directly)

## Quick start

```sh
# Build and launch an interactive shell (builds on first run)
make

# Or equivalently with docker compose
docker compose run --rm agent
```

The host `$HOME` is available inside the container at `/home/agent/host`.

## Usage

### Makefile targets

| Target | Description |
|--------|-------------|
| `make` / `make run` | Build image (if needed) and launch an interactive `zsh` session |
| `make build` | Build (or rebuild) the image only |
| `make exec` | Open a shell inside an already-running container |
| `make clean` | Remove the local image |

Override `IMAGE` or `CONTAINER` on the command line if needed:

```sh
make run IMAGE=my-agent CONTAINER=my-agent-1
```

### docker compose

```sh
docker compose up --build   # build + start
docker compose run --rm agent  # one-off interactive session
docker compose down         # stop
```

### Plain Docker

```sh
docker build -t agent-container .
docker run --rm -it -v "$HOME:/home/agent/host" agent-container
```

## oh-my-pi (`omp`)

`omp` is available on `$PATH` immediately:

```sh
omp --help
omp chat          # interactive coding agent session
```

Shell completions are loaded automatically from `~/.zshrc`.  
See the [oh-my-pi documentation](https://github.com/can1357/oh-my-pi) for the full feature set.

## Accessing host files

The host `$HOME` is mounted read-write at `/home/agent/host`:

```sh
# inside the container
ls ~/host           # your host home directory
omp ~/host/myproject
```

## Customisation

- **Add system packages:** extend the `apt-get install` block in `Dockerfile`.
- **Persist the container:** remove `--rm` from the `docker run` / Makefile `run` target.
- **Additional mounts:** add `-v` flags to the `docker run` command or extra `volumes:` entries in `docker-compose.yml`.
- **Named image/container:** set `IMAGE` and `CONTAINER` in the `make` invocation or override defaults at the top of `Makefile`.

## Rebuilding

Re-run `make build` (or `docker compose build`) after any change to `Dockerfile`.
