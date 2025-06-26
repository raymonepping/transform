#!/usr/bin/env bash
set -euo pipefail

# === Load .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  source "${SCRIPT_DIR}/.env"
  set +a
else
  echo "❌ .env file missing next to transform_docker.sh"
  exit 1
fi

DOCKERHUB_REPO="${DOCKERHUB_REPO:-}"
if [[ -z "$DOCKERHUB_REPO" ]]; then
  echo "❌ DOCKERHUB_REPO not set in .env"
  exit 1
fi

# === Defaults
COMPOSE_FILE="docker-compose.yml"
MODULE_DIR="./modules"
NETWORK_MODULE="$MODULE_DIR/network"
COMPUTE_MODULE="$MODULE_DIR/compute"
STORAGE_MODULE="$MODULE_DIR/storage"

PROVIDER="docker"
TYPE=""
BUILD_ENABLED=false

# === Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider) PROVIDER="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --build) BUILD_ENABLED=true; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

echo "🔧 Provider: $PROVIDER"
[[ "$TYPE" != "" ]] && echo "📦 Type: $TYPE"
echo "🔨 Build enabled: $BUILD_ENABLED"
echo "🔄 Transforming $COMPOSE_FILE into Terraform modules..."

mkdir -p "$NETWORK_MODULE" "$COMPUTE_MODULE" "$STORAGE_MODULE"

# === Provider.tf content based on provider
if [[ "$PROVIDER" == "docker" ]]; then
  MODULE_PROVIDER_TF=$(cat <<EOF
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
EOF
)
elif [[ "$PROVIDER" == "aws" ]]; then
  MODULE_PROVIDER_TF=$(cat <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
)
else
  echo "❌ Unsupported provider: $PROVIDER"
  exit 1
fi

echo "$MODULE_PROVIDER_TF" > "$NETWORK_MODULE/provider.tf"
echo "$MODULE_PROVIDER_TF" > "$COMPUTE_MODULE/provider.tf"
echo "$MODULE_PROVIDER_TF" > "$STORAGE_MODULE/provider.tf"

# === Network
NETWORK_NAME=$(yq '.networks | keys | .[0]' "$COMPOSE_FILE")
NETWORK_FILE="$NETWORK_MODULE/${NETWORK_NAME}_network.tf"

if [[ ! -f "$NETWORK_FILE" ]]; then
  cat > "$NETWORK_FILE" <<EOF
resource "${PROVIDER}_network" "$NETWORK_NAME" {
  name = "$NETWORK_NAME"
}
EOF
  echo "🌐 Network module created: $NETWORK_NAME"
else
  echo "⚠️  Network module for '$NETWORK_NAME' already exists. Skipping."
fi

# === Volumes
yq '.volumes | keys | .[]' "$COMPOSE_FILE" | while read -r VOL; do
  cat > "$STORAGE_MODULE/${VOL}_volume.tf" <<EOF
resource "${PROVIDER}_volume" "$VOL" {
  name = "$VOL"
}
EOF
  echo "✅ Volume module created: $VOL"
done

# === Services
yq '.services | keys | .[]' "$COMPOSE_FILE" | while read -r SERVICE; do
  SERVICE_FILE="$COMPUTE_MODULE/${SERVICE}.tf"
  IMAGE=$(yq ".services.${SERVICE}.image // \"null\"" "$COMPOSE_FILE")
  BUILD_CONTEXT=$(yq ".services.${SERVICE}.build.context // \"\"" "$COMPOSE_FILE")
  ENV_FILE=$(yq ".services.${SERVICE}.env_file[0] // \"\"" "$COMPOSE_FILE")
  VOLUME_MOUNT=$(yq ".services.${SERVICE}.volumes[0] // \"\"" "$COMPOSE_FILE")
  PORTS=$(yq ".services.${SERVICE}.ports // []" "$COMPOSE_FILE" | yq 'join(", ")')

  # === Build if needed (only for Docker provider)
  if [[ "$BUILD_ENABLED" == "true" && "$BUILD_CONTEXT" != "" ]]; then
    echo "🔧 Building image for $SERVICE from $BUILD_CONTEXT ..."
    VERSION_FILE="${BUILD_CONTEXT}/.image_version"
    if [[ -f "$VERSION_FILE" ]]; then
      VERSION=$(cat "$VERSION_FILE")
      IFS='.' read -r major minor patch <<< "${VERSION:-0.0.0}"
    else
      major=0; minor=1; patch=0
    fi
    patch=$((patch + 1))
    NEW_VERSION="${major}.${minor}.${patch}"
    echo "$NEW_VERSION" > "$VERSION_FILE"

    IMAGE="${DOCKERHUB_REPO}/${SERVICE}:${NEW_VERSION}"
    docker build -t "$IMAGE" -t "${DOCKERHUB_REPO}/${SERVICE}:latest" "$BUILD_CONTEXT"
    docker push "$IMAGE"
    docker push "${DOCKERHUB_REPO}/${SERVICE}:latest"
    echo "✅ Built and pushed: $IMAGE"
  fi

  # === Docker container block (or AWS EC2 placeholder)
  if [[ "$PROVIDER" == "docker" ]]; then
    echo "resource \"docker_container\" \"$SERVICE\" {" > "$SERVICE_FILE"
    echo "  name  = \"$SERVICE\"" >> "$SERVICE_FILE"
    echo "  image = \"$IMAGE\"" >> "$SERVICE_FILE"

    if [[ "$PORTS" != "" ]]; then
      for port in $(echo "$PORTS" | sed 's/, /\n/g'); do
        echo "  ports {" >> "$SERVICE_FILE"
        echo "    internal = ${port##*:}" >> "$SERVICE_FILE"
        echo "    external = ${port%%:*}" >> "$SERVICE_FILE"
        echo "  }" >> "$SERVICE_FILE"
      done
    fi

    if [[ "$ENV_FILE" != "" && -f "$ENV_FILE" ]]; then
      echo "  env = [" >> "$SERVICE_FILE"
      while IFS='=' read -r KEY VALUE; do
        [[ -z "$KEY" || "$KEY" =~ ^# ]] && continue
        echo "    \"$KEY=$VALUE\"," >> "$SERVICE_FILE"
      done < "$ENV_FILE"
      echo "  ]" >> "$SERVICE_FILE"
    fi

    if [[ "$VOLUME_MOUNT" != "" ]]; then
      VOL_SRC=$(echo "$VOLUME_MOUNT" | cut -d':' -f1)
      VOL_DST=$(echo "$VOLUME_MOUNT" | cut -d':' -f2)
      echo "  volumes {" >> "$SERVICE_FILE"
      echo "    volume_name    = \"$VOL_SRC\"" >> "$SERVICE_FILE"
      echo "    container_path = \"$VOL_DST\"" >> "$SERVICE_FILE"
      echo "  }" >> "$SERVICE_FILE"
    fi

    echo "  networks_advanced {" >> "$SERVICE_FILE"
    echo "    name = \"$NETWORK_NAME\"" >> "$SERVICE_FILE"
    echo "  }" >> "$SERVICE_FILE"

    echo "}" >> "$SERVICE_FILE"
  elif [[ "$PROVIDER" == "aws" && "$TYPE" == "ec2" ]]; then
    cat > "$SERVICE_FILE" <<EOF
resource "aws_instance" "${SERVICE}" {
  ami           = "ami-0c55b159cbfafe1f0" # Placeholder
  instance_type = "t2.micro"

  tags = {
    Name = "${SERVICE}"
  }
}
EOF
  fi

  echo "✅ Service module created: $SERVICE"
done

# === Root files
cat > main.tf <<EOF
module "network" {
  source = "./modules/network"
}

module "storage" {
  source = "./modules/storage"
}

module "compute" {
  source = "./modules/compute"
}
EOF

cat > provider.tf <<EOF
$MODULE_PROVIDER_TF

provider "$PROVIDER" {}
EOF

touch variables.tf outputs.tf

echo "✅ Root Terraform files created."
echo "🎉 Done. Run: terraform init && terraform apply"
