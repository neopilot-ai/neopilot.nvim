# syntax=docker/dockerfile:1.6
# Build stage for Neovim with all build dependencies
FROM alpine:3.19 as builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    gettext-dev \
    libtool \
    automake \
    autoconf \
    pkgconf \
    unzip \
    curl \
    xz \
    g++ \
    gcc \
    make \
    nodejs \
    npm \
    python3 \
    python3-dev \
    py3-pip \
    py3-pynvim

# Build and install Neovim
ARG NEOVIM_VERSION=stable
WORKDIR /tmp/neovim
RUN git clone --depth 1 --branch ${NEOVIM_VERSION} https://github.com/neovim/neovim . \
    # Create and activate virtual environment for Python dependencies
    && python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir pynvim \
    # Build and install Neovim
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/neovim

# Final stage
FROM alpine:3.19

# Create non-root user first
RUN adduser -D -u 1000 neovim

# Install runtime dependencies
RUN apk add --no-cache \
    git \
    nodejs \
    npm \
    python3 \
    py3-pip \
    py3-pynvim \
    ripgrep \
    fzf \
    && npm install -g neovim

# Create necessary directories with correct permissions
RUN mkdir -p /home/neovim/.local/share/nvim \
    && mkdir -p /home/neovim/.local/state/nvim \
    && mkdir -p /home/neovim/.cache/nvim \
    && mkdir -p /home/neovim/.config/nvim \
    && chown -R neovim:neovim /home/neovim

# Copy Neovim from builder
COPY --from=builder /usr/local/ /usr/local/

# Switch to non-root user
USER neovim
WORKDIR /home/neovim

# Set up Neovim configuration
COPY --chown=neovim:neovim init.lua /home/neovim/.config/nvim/init.lua
COPY --chown=neovim:neovim lua /home/neovim/.config/nvim/lua

# Default command
CMD ["nvim"]
