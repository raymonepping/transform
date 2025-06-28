
data "hcp_packer_artifact" "ubuntu_hardened" {
  bucket_name  = "ubuntu-hardened"
  channel_name = "latest"
  platform     = "docker"
  region       = "docker"
}

resource "docker_image" "ubuntu_hardened" {
  name = data.hcp_packer_artifact.ubuntu_hardened.external_identifier
}

resource "docker_container" "example" {
  name  = "ubuntu-secure"
  image = docker_image.ubuntu_hardened.name
  ports {
    internal = 80
    external = 8080
  }
}