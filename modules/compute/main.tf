resource "aws_instance" "docker_host" {
  ami                         = "ami-042b4708b1d05f512"
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-docker-host"
  }
}
