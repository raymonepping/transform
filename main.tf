terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///Users/raymon.epping/.docker/run/docker.sock"
}

resource "docker_image" "hello" {
  name = "hello-world:latest"
}

resource "docker_container" "hello" {
  name  = "hello-from-terraform"
  image = docker_image.hello.name
  must_run = false
  rm       = true
}