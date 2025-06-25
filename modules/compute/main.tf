resource "aws_instance" "example" {
  ami                    = "ami-06dd92ecc74fdfb36"  # Ubuntu 22.04 for eu-north-1
  instance_type          = "t3.micro"
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-vm"
  }
}
