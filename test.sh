#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Test runner script

set -euo pipefail

echo "🧪 Building test container..."
docker-compose build

echo ""
echo "🚀 Running BATS test suite..."
docker-compose run --rm test

echo ""
echo "✅ All tests complete!"
