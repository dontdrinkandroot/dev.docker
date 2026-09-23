# dev.docker

Generic development base image (`ghcr.io/dontdrinkandroot/dev:latest`, Ubuntu
26.04 LTS): apt toolchain (build-essential, git, ripgrep, shellcheck, jq, ...),
Node.js LTS, Go (latest stable), Python 3 + uv, PHP 8.5 + composer, OpenJDK 25,
Kotlin (kotlinc, latest stable), pnpm. Built for standalone interactive use
*and* as the base for project images such as `ghcr.io/dontdrinkandroot/acp-agent`.

## Image

- Published by GitHub Actions on pushes to `main`, manually, and on a weekly
  schedule so apt security patches and rolling toolchain installs stay current.
- `linux/amd64` only; `:latest` only (old untagged package versions are pruned,
  the 5 newest are kept).
- Ships a non-root user `dev` (build args `DEV_UID`/`DEV_GID`, default 1000),
  home `/home/dev`, workdir `/workspace`, and a git config with
  `init.defaultBranch = main` and `safe.directory = *` — no baked-in identity.

## Standalone use

```sh
docker run --rm -it -v "$PWD:/workspace" -w /workspace ghcr.io/dontdrinkandroot/dev:latest
```

## Local build

```sh
./build-docker
```

Builds the image from the checked-out directory and tags it
`ghcr.io/dontdrinkandroot/dev:latest`, matching what dependent builds pull.

## Visibility

The ghcr package must be switched to public once in the package settings after
the first push (workflow tokens cannot change package visibility).