# Retrieve the availability zones in the target region
data "aws_availability_zones" "available" {
  state = "available"
}

# Retrieve information about the target region
data "aws_region" "current" {}

# Retrieve information about the user and account
data "aws_caller_identity" "current" {}

# look up latest ubuntu image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  private_subnets = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}


# k8s controlplane node config
resource "aws_instance" "k8s_controlplane" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type_control
  iam_instance_profile        = aws_iam_instance_profile.k8s_node.name
  key_name                    = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  user_data                   = file("${path.module}/k8s-boot.sh")
  user_data_replace_on_change = true
  depends_on                  = [aws_route.private_default]
  count                       = 3
  subnet_id                   = local.private_subnets[count.index % 2]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "Controlplane-${count.index + 1}" }

}

# k8s worker node config
resource "aws_instance" "k8s_worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  iam_instance_profile        = aws_iam_instance_profile.k8s_node.name
  key_name                    = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  depends_on                  = [aws_route.private_default]
  count                       = 2
  subnet_id                   = local.private_subnets[count.index % 2]
  user_data                   = file("${path.module}/k8s-boot.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "worker-node-${count.index + 1}" }
}

#ssh key pair
resource "aws_key_pair" "k8s_lab" {
  key_name   = "k8s_lab"
  public_key = var.ssh_public_key #public key in HCP terraform
}

# network load balancer config
resource "aws_lb" "k8s_loadbalancer" {
  name               = "k8s-nlb"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_k8s_sg.id]


  subnets = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  enable_cross_zone_load_balancing = true


  tags = { Name = "k8s-nlb" }
}
