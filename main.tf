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

  ssh_clean_image = module.images.ssh_clean_image

}
