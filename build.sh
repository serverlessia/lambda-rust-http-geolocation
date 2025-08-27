#!/bin/bash

set -e

echo "🚀 Building Lambda HTTP Geolocation function..."

# Check if cargo-lambda is installed
if ! command -v cargo-lambda &> /dev/null; then
    echo "❌ cargo-lambda not found. Installing..."
    cargo install cargo-lambda
fi

# Run clippy checks first
echo "🔍 Running clippy checks..."
if ! cargo clippy -- -D warnings; then
    echo "❌ Clippy checks failed! Fix warnings before building."
    exit 1
fi
echo "✅ Clippy checks passed"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cargo clean

# Build the release binary
echo "🔨 Building ARM64 binary..."
cargo lambda build --release --arm64

# Check if binary was created
if [ ! -f "target/lambda/lambda_http_geolocation/bootstrap" ]; then
    echo "❌ Binary not found at target/lambda/lambda_http_geolocation/bootstrap"
    exit 1
fi

echo "✅ Build successful!"
echo "📦 Binary location: target/lambda/lambda_http_geolocation/bootstrap"
echo "📏 Binary size: $(du -h target/lambda/lambda_http_geolocation/bootstrap | cut -f1)"

# Create deployment package
echo "📦 Creating deployment package..."
cd target/lambda/lambda_http_geolocation
zip -r lambda_http_geolocation.zip bootstrap
cd ../../..

echo "🎉 Deployment package ready at: target/lambda/lambda_http_geolocation/lambda_http_geolocation.zip"
echo "📏 Package size: $(du -h target/lambda/lambda_http_geolocation/lambda_http_geolocation.zip | cut -f1)"
echo ""
echo "🚀 Ready to deploy with Terraform!"
echo "   cd infra && terraform apply"
