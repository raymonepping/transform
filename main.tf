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

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx" {
  name  = "demo-nginx"
  image = docker_image.nginx.latest
  ports {
    internal = 80
    external = 8080
  }
}
