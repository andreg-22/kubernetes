# Role that EC2 is allowed to assume
resource "aws_iam_role" "k8s_node_ssm" {
  name = "k8s-node-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# The managed policy 
resource "aws_iam_role_policy_attachment" "k8s_node_ssm_core" {
  role       = aws_iam_role.k8s_node_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 can't use a role directly. It needs an instance profile wrapping it
resource "aws_iam_instance_profile" "k8s_node" {
  name = "k8s-node-profile"
  role = aws_iam_role.k8s_node_ssm.name
}