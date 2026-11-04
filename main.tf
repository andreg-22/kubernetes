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

resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_k8s
}


resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    name = "private-subnet-b"
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s_cluster"
  description = "Allow SSH from RHEL"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["100.51.236.6/32"]
  }

  ingress {
    description = "connectivity to nlb"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
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

# secuirty group for network load balancer
resource "aws_security_group" "nlb_k8s_sg" {
  name        = "nlb_k8s_sg"
  description = "security group for nlb api"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description     = "Node to nlb connectivity"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_sg.id]
  }


  egress {
    description     = "Node to nlb connectivity"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_sg.id]
  }

  tags = {
    name = "security-group-nlb"
  }

}

# k8s master node config
resource "aws_instance" "k8s_controlplane_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_master
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data              = file("${path.module}/k8s-boot.sh")

  tags = {
    name = "Controlplane-1"
  }

}
# 2nd master node config
resource "aws_instance" "k8s_controlplane_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_master
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data              = file("${path.module}/k8s-boot.sh")
  tags = {
    name = "Controlplane-2"
  }
}

# 3rd master node config
resource "aws_instance" "k8s_controlplane_3" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_master
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data              = file("${path.module}/k8s-boot.sh")
  tags = {
    name = "Controlplane-3"
  }
}


# k8s worker node config
resource "aws_instance" "k8s_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.k8s_lab.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  count     = 2
  user_data = file("${path.module}/k8s-boot.sh")

  tags = {
    name = "worker-node"
  }
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


  tags = {
    name = "k8s-nlb"
  }
}



# target group for network load balancer
resource "aws_lb_target_group" "k8s_nlb_tg" {
  name        = "nlb-tg-k8s"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.k8s_vpc.id

  health_check {
    enabled  = true
    protocol = "TCP"
    port     = 6443
  }

  tags = {
    name = "target-group-nlb"
  }
}


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.k8s_loadbalancer.arn
  port              = "6443"
  protocol          = "tcp"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_nlb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "controlplane_nodes" {
  for_each = local.k8s_controlplane_instance_ids

  target_group_arn = aws_lb_target_group.k8s_nlb_tg.arn
  target_id        = each.value
  port             = 6443
}