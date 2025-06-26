terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
      host = "unix:///Users/raymon.epping/.docker/run/docker.sock"
    }
  }
}


