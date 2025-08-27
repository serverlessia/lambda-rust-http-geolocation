# Quick Start Guide

## Prerequisites

- Docker and Docker Compose
- VS Code with Dev Containers extension
- AWS CLI configured (optional for local development)

## Getting Started

### 1. Open in Dev Container

1. Clone this repository
2. Open in VS Code
3. When prompted, click "Reopen in Container"
4. Wait for the container to build (this may take a few minutes)

### 2. Verify Setup

The devcontainer automatically includes:

- ✅ Rust toolchain (1.70+)
- ✅ AWS CLI
- ✅ Terraform
- ✅ Zig (for ARM64 cross-compilation)
- ✅ zip utilities
- ✅ cargo-lambda (installed automatically)

### 3. Build and Test

```bash
# Setup Rust targets
./setup.sh

# Build the Lambda function
./build.sh

# Test locally
cargo lambda watch

# In another terminal, test the API
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod": "GET", "path": "/geo", "queryStringParameters": {"ip": "8.8.8.8"}}'
```

### 4. Deploy to AWS

```bash
# Deploy everything (builds + infrastructure)
cd infra
terraform init
terraform apply
```

## Project Structure

```plaintext
lambda_http_geolocation/
├── .devcontainer/          # VS Code devcontainer config
│   └── devcontainer.json   # Container settings with pre-built image
├── src/                    # Rust source code
│   └── main.rs            # Lambda function
├── infra/                  # Terraform infrastructure
│   ├── main.tf            # Main configuration
│   ├── variables.tf       # Variables
│   └── outputs.tf         # Outputs
├── setup.sh               # Development environment setup
├── build.sh               # Build and package script
├── Cargo.toml             # Rust dependencies
└── README.md              # Full documentation
```

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Customize the Lambda function in `src/main.rs`
- Modify infrastructure in `infra/` directory
- Add tests and CI/CD pipelines

## Troubleshooting

- **Container won't start**: Ensure Docker is running and has enough resources
- **Build fails**: Check that cargo-lambda is installed in the container
- **Deployment fails**: Verify AWS credentials and permissions
