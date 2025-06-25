module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source       = "./modules/compute"
  project_name = var.project_name
  environment  = var.environment
  key_name     = var.key_name   
  subnet_id    = module.network.subnet_id
  sg_id        = module.network.sg_id
}
