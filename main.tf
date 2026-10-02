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

resource "aws_security_group" "k8s_sg" {
  name        = "k8s_cluster"
  description = "Allow SSH from RHEL"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["100.51.236.6/32"]
  }

  ingress {
    description = "intra-node connectivity"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# k8s master node config
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_master
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data              = <<-EOF
  #!/bin/bash
  set -euxo pipefail

  swapoff -a
  sed -ri '/\s+swap\s+/s/^/#/' /etc/fstab

  cat <<'MODULES' > /etc/modules-load.d/k8.conf
  br_netfilter
  MODULES

  modprobe br_netfilter

  cat <<'SYSCTL' > /etc/sysctl.d/99-kubernetes-networking.conf
  net.bridge.bridge-nf-call-iptables = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.ipv4.ip_forward = 1

  sysctl --system
  EOF

  tags = {
    name = "Master node"
  }
}
# 2nd master node config
resource "aws_instance" "k8s_master_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_master
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data              = <<-EOF
  #!/bin/bash
  set -euxo pipefail

  swapoff -a
  sed -ri '/\s+swap\s+/s/^/#/' /etc/fstab

  cat <<'MODULES' > /etc/modules-load.d/k8.conf
  br_netfilter
  MODULES

  modprobe br_netfilter

  cat <<'SYSCTL' > /etc/sysctl.d/99-kubernetes-networking.conf
  net.bridge.bridge-nf-call-iptables = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.ipv4.ip_forward = 1

  sysctl --system
  EOF
  tags = {
    name = "Master node 2"
  }
}


# k8s worker node config
resource "aws_instance" "k8s_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  count     = 2
  user_data = <<-EOF
  #!/bin/bash
  set -euxo pipefail

  swapoff -a
  sed -ri '/\s+swap\s+/s/^/#/' /etc/fstab

  cat <<'MODULES' > /etc/modules-load.d/k8.conf
  br_netfilter
  MODULES

  modprobe br_netfilter

  cat <<'SYSCTL' > /etc/sysctl.d/99-kubernetes-networking.conf
  net.bridge.bridge-nf-call-iptables = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.ipv4.ip_forward = 1

  sysctl --system
  EOF

  tags = {
    name = "worker-node"
  }
}
#ssh key pair
resource "aws_key_pair" "k8s_lab" {
  key_name   = "k8s_lab"
  public_key = var.ssh_public_key #public key in HCP terraform
}

