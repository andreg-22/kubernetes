# target group for network load balancer
resource "aws_lb_target_group" "k8s_nlb_tg" {
  name               = "nlb-tg-k8s"
  port               = 6443
  protocol           = "TCP"
  target_type        = "instance"
  preserve_client_ip = false
  vpc_id             = aws_vpc.k8s_vpc.id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 6443
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "target-group-nlb"
  }
}

# load balancer listener -- references target group
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.k8s_loadbalancer.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_nlb_tg.arn
  }
}

# target group attachement for controlplane nodes -- can use count or for each
resource "aws_lb_target_group_attachment" "controlplane_nodes" {
  count = length(aws_instance.k8s_controlplane)

  target_group_arn = aws_lb_target_group.k8s_nlb_tg.arn
  target_id        = aws_instance.k8s_controlplane[count.index].id
  port             = 6443
}