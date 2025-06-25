output "subnet_id" {
  value = aws_subnet.main.id
}

output "sg_id" {
  value = aws_security_group.allow_all.id
}
