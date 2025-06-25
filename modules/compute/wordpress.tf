resource "aws_instance" "wordpress" {
  ami           = "ami-0c55b159cbfafe1f0" # Example AMI
  instance_type = "t2.micro"

  tags = {
    Name = "wordpress"
  }
}
