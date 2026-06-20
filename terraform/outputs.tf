output "load_balancer_dns" {
  value = aws_elb.app.dns_name
}
output "master_public_ip" {
  value = aws_instance.master.public_ip
}
output "sqs_url" {
  value = aws_sqs_queue.events.url
}
output "sns_topic_arn" {
  value = aws_sns_topic.notifications.arn
}

