output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "load_balancer_dns" {
  description = "Paste this into browser to see the web app"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "SSH into this IP to reach the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "web_1_private_ip" {
  description = "Private IP of web server 1 — SSH to this from inside the bastion"
  value       = aws_instance.web_1.private_ip
}

output "web_2_private_ip" {
  description = "Private IP of web server 2 — SSH to this from inside the bastion"
  value       = aws_instance.web_2.private_ip
}

output "db_private_ip" {
  description = "Private IP of the DB server — SSH to this from inside the bastion"
  value       = aws_instance.db.private_ip
}

output "ssh_command" {
  description = "Ready-to-use SSH command for the bastion"
  value       = "ssh -i ~/.ssh/techcorp-key.pem ec2-user@${aws_eip.bastion.public_ip}"
}