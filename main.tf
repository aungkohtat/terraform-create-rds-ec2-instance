data "aws_availability_zones" "azs" {
  state = "available"
}

####################################################################
# VPC Security Group
####################################################################

resource "aws_security_group" "security_group_rds" {
  name   = var.rds_security_group_name
  vpc_id = var.vpc_id

  tags = {
    Name = var.rds_security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "db" {
  for_each = data.aws_subnet.private_subnet
  security_group_id = aws_security_group.security_group_rds.id

  cidr_ipv4   = each.value.cidr_block
  from_port   = var.db_from_port
  ip_protocol = "tcp"
  to_port     = var.db_to_port
}

resource "aws_vpc_security_group_ingress_rule" "vault_db" {
  security_group_id = aws_security_group.security_group_rds.id

  cidr_ipv4   = var.vault_cluster_cidr
  from_port   = var.db_from_port
  ip_protocol = "tcp"
  to_port     = var.db_to_port
}

resource "aws_security_group" "security_group_private_ssh" {
  name   = var.private_ssh_security_group_name
  vpc_id = var.vpc_id

  tags = {
    Name = var.private_ssh_security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "private" {
  for_each = data.aws_subnet.private_subnet
  security_group_id = aws_security_group.security_group_private_ssh.id

  cidr_ipv4   = each.value.cidr_block
  from_port   = var.ssh_from_port
  ip_protocol = "tcp"
  to_port     = var.ssh_to_port
}

resource "aws_security_group" "security_group_public_ssh" {
  name   = var.public_ssh_security_group_name
  vpc_id = var.vpc_id

  tags = {
    Name = var.public_ssh_security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "public" {
  security_group_id = aws_security_group.security_group_public_ssh.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = var.ssh_from_port
  ip_protocol = "tcp"
  to_port     = var.ssh_to_port
}

####################################################################
# AWS DB Instance
####################################################################

resource "aws_db_instance" "project_rds" {
  engine                 = var.engine
  engine_version         = var.engine_version
  identifier             = var.identifier
  username               = var.username
  password               = var.password
  instance_class         = var.instance_class
  storage_type           = var.storage_type
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  db_subnet_group_name   = var.db_subnet_group_name
  publicly_accessible    = var.publicly_accessible
  vpc_security_group_ids = [aws_security_group.security_group_rds.id]
  availability_zone      = data.aws_availability_zones.azs.names[0]
  port                   = var.mysql_port
  db_name                = var.db_name
}

####################################################################
# AWS EC2 Instance
####################################################################
//---------------------------------------------------------
//-App Server 
//---------------------------------------------------------
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.private_subnet_ids.ids[0]
  key_name                    = "ssh-key-${random_pet.env.id}"
  vpc_security_group_ids      = [aws_security_group.security_group_private_ssh.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.vault-client.id

  tags = {
    Name = "{var.environment_name}-app"
  }
  lifecycle {
    ignore_changes = [
      ami,
      tags,
    ]
  }
}

//---------------------------------------------------------
//-Jump Server 
//---------------------------------------------------------
resource "aws_instance" "jump" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.public_subnet_ids.ids[0]
  key_name                    = "ssh-key-${random_pet.env.id}"
  vpc_security_group_ids      = [aws_security_group.security_group_public_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "{var.environment_name}-jump"
  }
  lifecycle {
    ignore_changes = [
      ami,
      tags,
    ]
  }
}

