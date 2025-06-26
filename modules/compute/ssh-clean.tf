resource "docker_container" "ssh-clean" {
  name  = "ssh-clean"
  image = "repping/ssh-clean:1.4.14"
  ports {
    internal = 22
    external = 2222
  }
  networks_advanced {
    name = "transform"
  }
}
