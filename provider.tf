# Auto-generated provider configurations

provider "docker" {
  region = var.region
}

terraform {
  required_providers {
    docker = {
      source  = "null/docker"
      version = "~> null"
    }
  }
}
