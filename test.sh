#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Test runner script

set -euo pipefail

if [[ "${1:-}" == "--build" ]]; then
  echo "🧪 Building test container (forced)..."
  docker-compose build test
else
  # Build only if image missing
  if ! docker image inspect totally-legal-bro_test:latest >/dev/null 2>&1; then
    echo "🧪 Building test container (no cached image)..."
    docker-compose build test
  else
    echo "🧪 Using cached test image"
  fi
fi

echo ""
echo "🚀 Running BATS test suite..."
docker-compose run --rm test

echo ""
echo "✅ All tests complete!"
