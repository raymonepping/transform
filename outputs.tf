output "ssh_clean_ip" {
  value = module.compute.ssh-clean.network_data[0].ip_address
}
