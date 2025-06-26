resource "docker_container" "ssh-clean" {
  name  = "ssh-clean"
  image = var.ssh_clean_image
  ports {
    internal = 22
    external = 2222
  }
  networks_advanced {
    name = "transform"
  }
}
