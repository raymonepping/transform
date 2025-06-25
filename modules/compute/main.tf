resource "aws_instance" "docker_host" {
  ami                         = "ami-042b4708b1d05f512"
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  user_data = <<-EOF2
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d --name ssh-clean repping/ssh-clean:1.4.4
              EOF2

  tags = {
    Name = "${var.project_name}-docker-host"
  }
}
