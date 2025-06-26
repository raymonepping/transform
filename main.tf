terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

module "network" {
  source = "./modules/network"
}

module "storage" {
  source = "./modules/storage"
}

module "images" {
  source = "./modules/images"
}

module "compute" {
  source = "./modules/compute"
}