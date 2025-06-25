# Placeholder for volume if needed
resource "aws_ebs_volume" "mysql_data" {
  availability_zone = "eu-north-1a"
  size              = 10
  tags = {
    Name = "mysql_data_volume"
  }
}
