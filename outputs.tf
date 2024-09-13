output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.project_rds.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.project_rds.port
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.project_rds.username
  sensitive   = true
}

output "test" {
  value = data.aws_subnets.private_subnet_ids.ids
}

output "Test_Output" {
  value = <<EOF

The Vaule of Private_subnet : data.aws_subnet.private_subnet.ids
The Vaule of Private_Subnet Cidr: data.aws_subnet.private_subnet.ids[*].cidr_block

  EOF
}




output "endpoints" {
  value = <<EOF

AWS RDS Endpoint:  ${aws_db_instance.project_rds.endpoint}

For example:
    mysql -h ${aws_db_instance.project_rds.id} -P ${aws_db_instance.project_rds.port} -u ${aws_db_instance.project_rds.username} -p

Jump Server IP (public):  ${aws_instance.jump.public_ip}
Jump Server IP (private): ${aws_instance.jump.private_ip}

For example:
   ssh -i ${aws_key_pair.main.key_name}.pem ubuntu@${aws_instance.jump.public_ip}

APP Client IP (private): ${aws_instance.app.private_ip}

For example:
   ssh -i ${aws_key_pair.main.key_name}.pem ubuntu@${aws_instance.app.private_ip}

APP Client IAM Role ARN: ${data.aws_iam_role.vault-client.arn}

EOF

}