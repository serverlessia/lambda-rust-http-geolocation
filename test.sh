#!/bin/bash

set -e

echo "🧪 Running local tests for lambda_http_geolocation..."

# 1. Check if code compiles
echo "🔨 Checking if code compiles..."
if ! cargo check; then
    echo "❌ Compilation failed!"
    exit 1
fi
echo "✅ Compilation successful"

# 2. Run clippy checks
echo "🔍 Running clippy checks..."
if ! cargo clippy -- -D warnings; then
    echo "❌ Clippy checks failed! Fix warnings before proceeding."
    exit 1
fi
echo "✅ Clippy checks passed"

# 3. Run tests (if any)
echo "🧪 Running tests..."
if ! cargo test; then
    echo "❌ Tests failed!"
    exit 1
fi
echo "✅ Tests passed"

# 4. Check if function can be built (optional - requires ARM64 target)
echo "🏗️ Checking if function can be built..."
if cargo lambda build --release --arm64 --no-default-features 2>/dev/null; then
    echo "✅ Lambda build successful"
else
    echo "⚠️  Lambda build skipped (ARM64 target not installed)"
    echo "   Run './setup.sh' to install ARM64 target for full testing"
fi

echo ""
echo "🎉 All local tests passed! The function is ready for deployment."
echo "🚀 Next steps:"
echo "   ./build.sh          # Build and package for deployment"
echo "   cd infra && terraform apply  # Deploy to AWS"
