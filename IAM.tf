data "aws_iam_role" "k8s_node_ssm" {
  name = "K8s_node_ssm"
}

# The managed policy 
resource "aws_iam_role_policy_attachment" "k8s_node_ssm_core" {
  role       = data.aws_iam_role.k8s_node_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 can't use a role directly. It needs an instance profile wrapping it
resource "aws_iam_instance_profile" "k8s_node" {
  name = "k8s-node-profile"
  role = data.aws_iam_role.k8s_node_ssm.name
}