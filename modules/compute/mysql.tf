resource "docker_container" "mysql" {
  name  = "mysql"
  image = var.mysql_image
  ports {
    internal = 3306
    external = 3306
  }
  env = [
    "MYSQL_ROOT_PASSWORD=rootpassword",
    "MYSQL_DATABASE=wp",
  ]
  volumes {
    volume_name    = "mysql_data"
    container_path = "/var/lib/mysql"
  }
  networks_advanced {
    name = "transform"
  }
}
