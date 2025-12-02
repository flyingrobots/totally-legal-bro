#!/usr/bin/env bash
# Test runner script

set -euo pipefail

echo "🧪 Building test container..."
docker-compose build

echo ""
echo "🚀 Running BATS test suite..."
docker-compose run --rm test

echo ""
echo "✅ All tests complete!"
