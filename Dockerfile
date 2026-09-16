# syntax=docker/dockerfile:1
FROM ubuntu:26.04

ARG DEV_UID=1000
ARG DEV_GID=1000

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && sed -i \
        -e 's#http://archive.ubuntu.com/ubuntu/#http://ftp.halifax.rwth-aachen.de/ubuntu/#' \
        /etc/apt/sources.list.d/ubuntu.sources \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        dnsutils \
        file \
        git \
        git-lfs \
        iputils-ping \
        jq \
        netcat-openbsd \
        openssh-client \
        passwd \
        pkg-config \
        postgresql-client \
        ripgrep \
        rsync \
        shellcheck \
        sqlite3 \
        tree \
        unzip \
        xz-utils \
        zip \
        openjdk-25-jdk \
        python3 \
        python3-pip \
        python3-venv \
        php8.5-cli \
        php8.5-xdebug \
        php8.5-curl \
        php8.5-mbstring \
        php8.5-xml \
        php8.5-zip \
        php8.5-intl \
        php8.5-sqlite3 \
        php8.5-pgsql \
        php8.5-bcmath \
        php8.5-gd \
        php8.5-ldap \
        composer \
    && if [ ! -e /usr/bin/php ]; then ln -s php8.5 /usr/bin/php; fi \
    && printf '%s\n' 'zend_extension=xdebug.so' 'xdebug.mode=off' > /etc/php/8.5/mods-available/xdebug.ini

RUN set -eu; \
    node_arch="$(uname -m)"; \
    case "$node_arch" in \
        x86_64|amd64) node_arch=x64 ;; \
        aarch64|arm64) node_arch=arm64 ;; \
        *) echo "unsupported architecture: $node_arch" >&2; exit 1 ;; \
    esac; \
    node_version=$(curl -fsSL https://nodejs.org/dist/index.json 2>/dev/null \
        | grep -oE '"version":"v[0-9.]+"[^}]*"lts":"[^"]+"' \
        | head -n1 \
        | sed -E 's/.*"version":"(v[0-9.]+)".*/\1/'); \
    curl -fsSL "https://nodejs.org/dist/${node_version}/node-${node_version}-linux-${node_arch}.tar.xz" -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.xz

RUN set -eu; \
    curl -LsSf https://astral.sh/uv/install.sh | sh \
    && install -m 0755 /root/.local/bin/uv /usr/local/bin/uv \
    && install -m 0755 /root/.local/bin/uvx /usr/local/bin/uvx \
    && rm -rf /root/.local

RUN set -eu; \
    export SHELL=/bin/bash \
    && export HOME=/tmp/pnpm-home \
    && export PNPM_HOME=/usr/local/pnpm \
    && mkdir -p "$HOME" \
    && curl -fsSL https://get.pnpm.io/install.sh | sh - \
    && ln -s "$PNPM_HOME/bin/pnpm" /usr/local/bin/pnpm \
    && ln -s "$PNPM_HOME/bin/pnpx" /usr/local/bin/pnpx \
    && pnpm --version \
    && rm -rf "$HOME"

RUN set -eu; \
    go_arch="$(uname -m)"; \
    case "$go_arch" in \
        x86_64|amd64) go_arch=amd64 ;; \
        aarch64|arm64) go_arch=arm64 ;; \
        *) echo "unsupported architecture: $go_arch" >&2; exit 1 ;; \
    esac; \
    go_version=$(curl -fsSL https://go.dev/VERSION?m=text | sed -n '1s/^go//p'); \
    curl -fsSL "https://go.dev/dl/go${go_version}.linux-${go_arch}.tar.gz" -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && ln -s /usr/local/go/bin/go /usr/local/bin/go \
    && ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt \
    && rm -f /tmp/go.tar.gz

RUN groupadd -o --gid "${DEV_GID}" dev \
    && useradd -o \
        --uid "${DEV_UID}" \
        --gid "${DEV_GID}" \
        --create-home \
        --shell /bin/bash \
        dev \
    && mkdir -p \
        /home/dev/.config \
        /home/dev/.local/share \
        /home/dev/.local/state \
        /home/dev/.cache \
        /workspace \
    && printf '%s\n' '[init]' '	defaultBranch = main' '[safe]' '	directory = *' > /etc/gitconfig \
    && chown -R "${DEV_UID}:${DEV_GID}" /home/dev \
    && chmod -R a+rwX /home/dev /workspace

ENV HOME=/home/dev \
    PATH=/home/dev/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    XDG_CONFIG_HOME=/home/dev/.config \
    XDG_DATA_HOME=/home/dev/.local/share \
    XDG_STATE_HOME=/home/dev/.local/state \
    XDG_CACHE_HOME=/home/dev/.cache \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /workspace
USER dev
