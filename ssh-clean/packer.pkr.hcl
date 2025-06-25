packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = ">= 1.0.8"
    }
  }
}

variable "image_tag" {
  type    = string
  default = "latest"
}

# This tells Packer to use your Dockerfile as the build context
source "docker" "ssh_clean" {
  commit      = true
  build_args  = {}
  # Directory containing your Dockerfile (e.g., ".")
  dockerfile  = "Dockerfile"
  context     = "."
  tag         = ["repping/ssh-clean:${var.image_tag}"]
}

build {
  name    = "ssh-clean-build"
  sources = ["source.docker.ssh_clean"]

  # Optionally upload to HCP Packer Registry (remove if not needed)
  hcp_packer_registry {
    bucket_name   = "ssh-clean"
    description   = "SSH-enabled Ubuntu image with tini entrypoint"
    bucket_labels = {
      "project" = "sportclub"
    }
    build_labels = {
      "tag" = var.image_tag
    }
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "repping/ssh-clean"
      tags       = [var.image_tag, "latest"]
    }

    post-processor "docker-push" {
      login = false
    }
  }
}
