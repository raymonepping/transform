resource "docker_container" "ssh-clean" {
  name  = "ssh-clean"
  image = docker_image.ssh-clean.latest
  ports {
    internal = 22
    external = 2222
  }
  networks_advanced {
    name = "transform"
  }
}
