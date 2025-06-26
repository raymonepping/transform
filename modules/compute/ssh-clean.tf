resource "docker_container" "ssh-clean" {
  name  = "ssh-clean"
  image = var.ssh_clean_image
  ports {
    internal = 22
    external = 2222
  }
  capabilities {
    add = ["IPC_LOCK"]
  }
  tty = true
  stdin_open = true
  privileged = true
  networks_advanced {
    name = "transform"
  }
}
