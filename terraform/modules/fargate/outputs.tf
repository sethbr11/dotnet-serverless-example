/***********
Outputs
************/
output "lb_dns_name" {
  value       = aws_lb.donut_lb.dns_name
  description = "DNS name of the load balancer"
}