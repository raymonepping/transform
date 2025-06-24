output "instance_ids" {
  description = "List of instance IDs"
  value       = module.compute.instance_ids
}

output "public_ips" {
  description = "List of public IPs"
  value       = module.compute.public_ips
}
