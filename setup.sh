#!/bin/bash

# Setup script for Rust Lambda ARM64 builds - lambda_http_geolocation
set -e

echo "🚀 Setting up Rust Lambda development environment for lambda_http_geolocation..."

# Check if ARM64 target is installed
if ! rustup target list --installed | grep -q "aarch64-unknown-linux-gnu"; then
    echo "🎯 Installing ARM64 Rust target..."
    rustup target add aarch64-unknown-linux-gnu
    echo "✅ ARM64 target installed"
else
    echo "✅ ARM64 target already installed"
fi

# Verify cargo-lambda setup
echo "🔍 Verifying cargo-lambda setup..."
cargo lambda system

echo ""
echo "🎉 Setup complete! You can now run:"
echo "   cargo lambda build --release --arm64"
echo ""
echo "🚀 After building, deploy with:"
echo "   cd infra && terraform apply"
