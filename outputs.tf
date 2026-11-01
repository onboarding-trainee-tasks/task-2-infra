output "ssh_command" {
  description = "SSH command for Task 2 Bastion"
  value       = "ssh -i ~/.ssh/t2-bastion ubuntu@${module.bastion_instance.public_ip}"
}

output "bastion_public_ip" {
  description = "Current Bastion public IP"
  value       = module.bastion_instance.public_ip
}