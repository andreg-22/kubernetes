output "controlplane_ip" {
  value = aws_instance.k8s_controlplane_1.public_ip
}

output "controlplane_2_ip" {
  value = aws_instance.k8s_controlplane_2.public_ip
}

output "controlplane_3_ip" {
  value = aws_instance.k8s_controlplane_3.public_ip
}

output "worker_node_ip" {
  value = aws_instance.k8s_worker[0].public_ip
}

output "worker_node2_ip" {
  value = aws_instance.k8s_worker[1].public_ip
}

output "k8s_nlb_api_dns_name" {
  value = aws_lb.k8s_loadbalancer.dns_name
}