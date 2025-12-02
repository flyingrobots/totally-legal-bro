# Test environment for totally-legal-bro
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    jq \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install bats-core from official release with checksum
ENV BATS_VERSION=1.11.0
ENV BATS_SHA256=5f50e9c4a2e7a39979f68de7975cdc8e90d518d04279314f0b0ec98c024aaa99
RUN curl -L "https://github.com/bats-core/bats-core/archive/v${BATS_VERSION}.tar.gz" -o /tmp/bats.tar.gz \
    && echo "${BATS_SHA256}  /tmp/bats.tar.gz" | sha256sum -c - \
    && tar -xf /tmp/bats.tar.gz -C /tmp \
    && /tmp/bats-core-${BATS_VERSION}/install.sh /usr/local \
    && rm -rf /tmp/bats.tar.gz /tmp/bats-core-${BATS_VERSION}

# Set up working directory
WORKDIR /app

# Copy the tool
COPY totally-legal-bro /app/totally-legal-bro
COPY lib /app/lib
COPY licenses /app/licenses

# Make CLI executable
RUN chmod +x /app/totally-legal-bro

# Ensure library scripts are executable (needed when git loses exec bits)
RUN find /app/lib -type f \( -name '*.sh' -o -perm -u=x -o -perm -g=x -o -perm -o=x \) -exec chmod +x {} \;

# Add to PATH
ENV PATH="/app:${PATH}"

# Set up git for testing
RUN git config --global user.email "test@example.com" && \
    git config --global user.name "Test User"

# Copy tests
COPY test /app/test

# Default command runs tests
CMD ["bats", "/app/test"]
