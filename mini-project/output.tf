
# outputs from loadbalancer resources
output "elb_target_group_arn" {
  value = aws_lb_target_group.Project-target-group.arn
}

output "elb_load_balancer_dns_name" {
  value = aws_lb.Project-lb.dns_name
}

output "elastic_load_balancer_zone_id" {
  value = aws_lb.Project-lb.zone_id
}
