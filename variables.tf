variable "ssh_public_key" {
  description = "Public key for ssh"
  type        = string
}

variable "instance_type_master" {
  description = "controlplane instance type"
  type = string
  default = "t3.medium"
}