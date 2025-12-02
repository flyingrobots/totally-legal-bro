# Test environment for totally-legal-bro
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    jq \
    curl \
    bats \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Copy the tool
COPY totally-legal-bro /app/totally-legal-bro
COPY lib /app/lib
COPY licenses /app/licenses

# Make CLI executable
RUN chmod +x /app/totally-legal-bro

# Add to PATH
ENV PATH="/app:${PATH}"

# Set up git for testing
RUN git config --global user.email "test@example.com" && \
    git config --global user.name "Test User"

# Copy tests
COPY test /app/test

# Default command runs tests
CMD ["bats", "/app/test"]
