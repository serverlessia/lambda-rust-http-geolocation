# Lambda HTTP Geolocation

A minimal AWS Lambda example in Rust that provides geolocation information for IP addresses via API Gateway, with developer-friendly Devcontainer setup.

## 🚀 Quick Start

### Prerequisites

- Docker Desktop
- VS Code with Dev Containers extension
- AWS CLI configured with appropriate credentials

### 1. Open in Dev Container

1. Clone this repository
2. Open in VS Code
3. When prompted, click "Reopen in Container"
4. Wait for the container to build and install dependencies

The devcontainer automatically includes:

- ✅ Rust toolchain (1.70+)
- ✅ AWS CLI
- ✅ Terraform
- ✅ Zig (for ARM64 cross-compilation)
- ✅ zip utilities
- ✅ cargo-lambda (installed automatically)

### 2. Setup Development Environment

```bash
# Run the setup script to install Rust targets
./setup.sh
```

### 3. Local Development

```bash
# Run all local tests (compilation, clippy, tests)
./test.sh

# Watch for changes and run locally
cargo lambda watch

# In another terminal, test locally (Lambda runtime format)
curl "http://localhost:9000/2015-03-31/functions/lambda_http_geolocation/invocations" \
  -X POST \
  -d '{"version":"2.0","routeKey":"GET /geo","rawPath":"/geo","rawQueryString":"ip=8.8.8.8","queryStringParameters":{"ip":"8.8.8.8"},"requestContext":{"http":{"method":"GET","path":"/geo"}},"body":"","isBase64Encoded":false}'

# After deployment, the API is much simpler:
# curl "https://your-api-gateway-url/prod/geo?ip=8.8.8.8"
```

### 4. Build for Production

```bash
# Build ARM64 binary for AWS Lambda
./build.sh

# The binary will be created at:
# target/lambda/lambda_http_geolocation/bootstrap
```

### 5. Deploy to AWS

```bash
# Navigate to infrastructure directory
cd infra

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply

# Get the API Gateway URL
terraform output api_gateway_url
```

### 6. Test the Deployed Function

```bash
# Test with the URL from terraform output
curl "https://<api-id>.execute-api.<region>.amazonaws.com/prod/geo?ip=8.8.8.8"
# Response: {"country":"United States","city":"Mountain View",...}
```

## 🏗️ Project Structure

```plaintext
lambda_http_geolocation/
├── .devcontainer/          # VS Code Dev Container config
│   └── devcontainer.json   # Container settings with pre-built image
├── src/
│   └── main.rs            # Lambda function code
├── infra/                  # Terraform infrastructure
│   ├── main.tf            # Main infrastructure config
│   ├── variables.tf       # Variable definitions
│   └── outputs.tf         # Output values
├── setup.sh               # Development environment setup
├── build.sh               # Build and package script
├── Cargo.toml             # Rust dependencies
└── README.md              # This file
```

## 🌐 API Endpoints

- **Help**: `GET /` → Shows API usage information and examples
- **Geolocation**: `GET /geo` → Returns geolocation data for IP address
- **Query Parameters**:
  - `ip` (optional): Specific IP address to lookup. If not provided, uses the client's IP from API Gateway.
- **Invalid Endpoints**: Any non-existent endpoint will return the help information

**Response Format:**

```json
{
  "country": "United States",
  "country_code": "US",
  "region": "CA",
  "city": "Mountain View",
  "lat": 37.4056,
  "lon": -122.0775,
  "timezone": "America/Los_Angeles",
  "isp": "Google LLC",
  "org": "Google Public DNS"
}
```

## 🔧 Development Workflow

1. **Setup**: Run `./setup.sh` to install Rust targets
2. **Local Development**: Use `cargo lambda watch` for hot reloading
3. **Testing**: Test locally before deploying
4. **Build**: Use `./build.sh` for production build
5. **Deploy**: Use Terraform to deploy infrastructure
6. **Test**: Verify the deployed function works

## 📦 Build Artifacts

The build process creates:

- **Binary**: `target/lambda/lambda_http_geolocation/bootstrap` (ARM64)
- **Package**: `target/lambda/lambda_http_geolocation/lambda_http_geolocation.zip` (for Terraform)

## 🛠️ Technologies Used

- **Rust**: Programming language
- **lambda_http**: AWS Lambda HTTP runtime
- **cargo-lambda**: Build tool for Rust Lambda functions
- **reqwest**: HTTP client for external API calls
- **serde**: JSON serialization/deserialization
- **Terraform**: Infrastructure as Code
- **Dev Containers**: Consistent development environment with pre-built image
- **Zig**: Cross-compilation tool for ARM64 builds (included in devcontainer)

## 📚 Reference

This implementation provides geolocation services using the free [ip-api.com](http://ip-api.com/) API and follows AWS Lambda best practices. The infrastructure uses API Gateway REST API with proxy integration for flexible routing.

## 🔍 Troubleshooting

### Common Issues

1. **Build fails**: Ensure you're using the Dev Container with Rust 1.70+
2. **Terraform errors**: Check AWS credentials and region configuration
3. **Lambda cold start**: First invocation may be slower
4. **Geolocation API errors**: Check if ip-api.com is accessible

### Useful Commands

```bash
# Check Rust version
rustc --version

# Check cargo-lambda installation
cargo lambda --version

# Check AWS CLI
aws --version

# Check Terraform
terraform --version

# Check Zig
zig version

# Setup and build
./setup.sh
./build.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
