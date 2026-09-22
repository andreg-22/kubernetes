output "controlplane_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "controlplane_2_ip" {
  value = aws_instance.k8s_master_2.public_ip
}

output "worker_node_ip" {
  value = aws_instance.k8s_worker.public_ip
}