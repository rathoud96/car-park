# Use the official Elixir image as base (Debian-based)
FROM elixir:1.18-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application code
COPY . .

# Compile the application
RUN mix do compile, release

# Create a new stage for the runtime
FROM debian:bookworm-slim AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    openssl \
    ncurses-base \
    netcat-openbsd \
    bash \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -g 1000 app && \
    useradd -u 1000 -g app -s /bin/bash -m app

# Set working directory
WORKDIR /app

# Copy release from builder stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/car_park ./

# Copy startup script
COPY --chown=app:app docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

# Switch to app user
USER app

# Expose port
EXPOSE 4000

# Set environment variables
ENV PHX_SERVER=true
ENV PORT=4000

# Start the application using the entrypoint script
CMD ["./docker-entrypoint.sh"] 