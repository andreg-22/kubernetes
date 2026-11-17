variable "ssh_public_key" {
  description = "Public key for ssh"
  type        = string
}

variable "instance_type_control" {
  description = "controlplane instance type"
  type        = string
  default     = "t3.medium"
}


variable "vpc_k8s" {
  description = "k8s_vpc"
  type        = string
  default     = "172.16.0.0/16"
}

