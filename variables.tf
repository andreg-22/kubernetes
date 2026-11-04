variable "ssh_public_key" {
  description = "Public key for ssh"
  type        = string
}

variable "instance_type_master" {
  description = "controlplane instance type"
  type        = string
  default     = "t3.medium"
}


variable "vpc_k8s" {
  description = "k8s_vpc"
  type        = string
  default     = "172.16.0.0/16"
}


locals {
  k8s_controlplane_instance_ids = {
    controlplane-1 = aws_instance.k8s_controlplane_1.id
    controlplane-2 = aws_instance.k8s_controlplane_2.id
    controlplane-3 = aws_instance.k8s_controlplane_3.id
  }
}