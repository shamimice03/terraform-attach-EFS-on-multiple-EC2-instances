################## Create VPC  ################## 
module "vpc" {

  source  = "shamimice03/vpc/aws"
  version = "1.0.1"

  vpc_name = "efs_vpc"
  cidr     = "192.168.0.0/16"

  azs                = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnet_cidr = ["192.168.0.0/20", "192.168.16.0/20"]

  enable_dns_hostnames      = true
  enable_dns_support        = true
  enable_single_nat_gateway = false

  tags = {
    "Team" = "platform-team"
    "Env"  = "efs-test"
  }

}

################## Local Variables  ################## 
locals {
  public_subnets = module.vpc.public_subnet_id
  vpc_id         = module.vpc.vpc_id
  file_system_id = aws_efs_file_system.file_system_1.id
}

################## Create Security Group for Public Instances  ################## 
resource "aws_security_group" "instance_sg" {
  name        = "allow_public_access"
  description = "Allow Traffic from Anywhere"
  vpc_id      = local.vpc_id

  dynamic "ingress" {

    for_each = var.public_instance_sg_ports
    content {
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "instance_sg"
  }
}

################## Create Security Group for Private Instances  ################## 
resource "aws_security_group" "efs_sg" {
  name        = "allow_from_public_instances"
  description = "Allow traffice from public instance sg only"
  vpc_id      = local.vpc_id

  dynamic "ingress" {

    for_each = var.efs_sg_ports
    content {
      from_port       = ingress.value["port"]
      to_port         = ingress.value["port"]
      protocol        = ingress.value["protocol"]
      security_groups = [aws_security_group.instance_sg.id]
    }
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.instance_sg.id]
  }

  tags = {
    "Name" = "efs_sg"
  }
}

################## Create EFS File system ################ 
resource "aws_efs_file_system" "file_system_1" {
  creation_token   = "efs-test"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    Name = "efs-test"
  }
}

################## Create EFS mount targets ################ 
resource "aws_efs_mount_target" "mount_targets" {
  count           = 2
  file_system_id  = aws_efs_file_system.file_system_1.id
  subnet_id       = local.public_subnets[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

################## Generating Script for Mounting EFS ################## 
resource "null_resource" "generate_efs_mount_script" {

  provisioner "local-exec" {
    command = templatefile("efs_mount.tpl", {
      efs_mount_point = var.efs_mount_point
      file_system_id  = local.file_system_id
    })
    interpreter = [
      "bash",
      "-c"
    ]
  }
}

################## SSH key generation ################## 
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

################## Extracting private key ################## 
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = var.private_key_location
  file_permission = "0400"
}

################## Create AWS key pair ################## 
resource "aws_key_pair" "aws_ec2_access_key" {
  key_name_prefix = var.key_name
  public_key      = tls_private_key.ssh.public_key_openssh
}

################## Create AWS EC2 Instance on Public Subnet ################ 
resource "aws_instance" "public_hosts" {

  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux_ami.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.aws_ec2_access_key.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  subnet_id              = local.public_subnets[count.index]

  tags = {
    "Name" = "public-instance-${count.index + 1}"
  }

  depends_on = [
    null_resource.generate_efs_mount_script,
    aws_efs_mount_target.mount_targets
  ]

  provisioner "file" {
    source      = "efs_mount.sh"
    destination = "efs_mount.sh"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location) # Location of the Private Key
    timeout     = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "bash efs_mount.sh",
    ]
  }
}

################## Clean Up Existing Script ################## 
resource "null_resource" "clean_up" {

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf efs_mount.sh"
  }
}

