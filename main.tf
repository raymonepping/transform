provider "docker" {}

module "network" {
  source = "./modules/network"
  providers = {
    docker = docker
  }
}

module "storage" {
  source = "./modules/storage"
  providers = {
    docker = docker
  }  
}

module "compute" {
  source = "./modules/compute"
  providers = {
    docker = docker
  }  
}
