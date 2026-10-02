output "controlplane_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "controlplane_2_ip" {
  value = aws_instance.k8s_master_2.public_ip
}

output "worker_node_ip" {
  value = aws_instance.k8s_worker[0].public_ip
}

output "worker_node2_ip" {
  value = aws_instance.k8s_worker[1].public_ip
}