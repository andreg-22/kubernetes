# Security group for k8s nodes
resource "aws_security_group" "k8s_sg" {
  name        = "k8s_cluster"
  description = "Allow SSH from RHEL"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["100.51.236.6/32"] # ----> RHEL desktop for administration
  }

  ingress {
    description = "intra-node connectivity( kubernetes, CNI)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

  tags = {
    name = "security-group-nlb"
  }

}

# Security group ingress rules for controlplane nodes access from network load balancer
resource "aws_vpc_security_group_ingress_rule" "nodes_from_nlb" {
  security_group_id            = aws_security_group.k8s_sg.id
  referenced_security_group_id = aws_security_group.nlb_k8s_sg.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
}

# Security group ingress rules for network load balancer access from controlplane nodes
resource "aws_vpc_security_group_ingress_rule" "nlb_to_nodes" {
  security_group_id            = aws_security_group.nlb_k8s_sg.id
  referenced_security_group_id = aws_security_group.k8s_sg.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
}

# Security group egress rule for network load balancer to controlplane nodes
resource "aws_vpc_security_group_egress_rule" "nlb_to_nodes" {
  security_group_id            = aws_security_group.nlb_k8s_sg.id
  referenced_security_group_id = aws_security_group.k8s_sg.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
}