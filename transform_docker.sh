#!/bin/bash
set -euo pipefail

# Load .env
ENV_FILE="./.env"
if [ -f "$ENV_FILE" ]; then
  echo "📄 Loading environment variables from .env..."
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "❌ .env file not found. Exiting."
  exit 1
fi

# Defaults
PROVIDER="docker"
TYPE=""
BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider) PROVIDER="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --build) BUILD=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Icons
ICON_DOCKER="🐳"
ICON_AWS="☁️"
ICON_COMPUTE="⚙️"
ICON_VOLUME="💾"
ICON_NETWORK="🌐"
ICON_SUCCESS="✅"
ICON_PACKAGE="📦"
ICON_BUILD="🔧"
ICON_ARROW="🔄"
ICON_READY="🎯"
ICON_MODULE="🧱"

echo ""
[[ "$PROVIDER" == "aws" ]] && echo "$ICON_AWS  Provider: $PROVIDER" || echo "$ICON_DOCKER  Provider: $PROVIDER"
[[ -n "$TYPE" ]] && echo "$ICON_PACKAGE Type: $TYPE"
$BUILD && echo "$ICON_BUILD Build enabled: true"
echo "$ICON_ARROW Parsing docker-compose.yml into Terraform modules..."

# Setup
mkdir -p modules/{network,compute,storage}
touch variables.tf outputs.tf main.tf provider.tf locals.tf versions.tf

# Root provider.tf
cat > provider.tf <<EOF
provider "aws" {
  region = var.region
}
EOF

# Root variables.tf
cat > variables.tf <<EOF
variable "project_name" { type = string }
variable "environment"  { type = string }
variable "region"       { 
  type = string  
  default = "eu-north-1" 
}
EOF

# Root main.tf
cat > main.tf <<EOF
module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source       = "./modules/compute"
  project_name = var.project_name
  environment  = var.environment
}
EOF

# Root locals.tf
cat > locals.tf <<EOF
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "raymon.epping"
    ManagedBy   = "Terraform"
  }
}
EOF

# Root versions.tf
cat > versions.tf <<EOF
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99.0"
    }
  }
}
EOF

# ────────────────────────────────────────────────────────────────
# Network Module
# ────────────────────────────────────────────────────────────────
cat > modules/network/main.tf <<EOF
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "\${var.project_name}-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "\${var.project_name}-subnet"
  }
}
EOF

cat > modules/network/variables.tf <<EOF
variable "project_name" { type = string }
variable "environment"  { type = string }
EOF

echo "$ICON_NETWORK Network module created: transform"

# ────────────────────────────────────────────────────────────────
# Storage Module
# ────────────────────────────────────────────────────────────────
cat > modules/storage/main.tf <<EOF
# Placeholder for volume if needed
resource "aws_ebs_volume" "mysql_data" {
  availability_zone = "eu-north-1a"
  size              = 10
  tags = {
    Name = "mysql_data_volume"
  }
}
EOF

cat > modules/storage/variables.tf <<EOF
variable "project_name" { type = string }
variable "environment"  { type = string }
EOF

echo "$ICON_VOLUME Volume module created: mysql_data"

# ────────────────────────────────────────────────────────────────
# Compute Module
# ────────────────────────────────────────────────────────────────
cat > modules/compute/main.tf <<EOF
resource "aws_instance" "docker_host" {
  ami                         = "${AMI_ID}"
  instance_type               = "${INSTANCE_TYPE}"
  subnet_id                   = module.network.aws_subnet_id
  associate_public_ip_address = true

  user_data = <<-EOF2
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d --name ssh-clean ${DOCKER_IMAGE}
              EOF2

  tags = {
    Name = "\${var.project_name}-docker-host"
  }
}
EOF

cat > modules/compute/variables.tf <<EOF
variable "project_name" { type = string }
variable "environment"  { type = string }
EOF

echo "$ICON_COMPUTE Service module created: docker_host EC2"

# ────────────────────────────────────────────────────────────────
# Image build step (if enabled)
# ────────────────────────────────────────────────────────────────
if $BUILD; then
  echo "$ICON_BUILD Building image for ssh-clean from ./ssh-clean ..."
  docker build -t ${DOCKER_IMAGE} ./ssh-clean > /dev/null
  docker push ${DOCKER_IMAGE} > /dev/null
  echo "$ICON_PACKAGE Built and pushed: ${DOCKER_IMAGE}"
fi

echo "$ICON_SUCCESS All modules created!"
echo "$ICON_READY You're ready. Run: terraform init && terraform apply"
