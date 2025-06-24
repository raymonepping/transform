module "compute" {
  source       = "./modules/compute"
  region       = var.region
  project_name = var.project_name
}
