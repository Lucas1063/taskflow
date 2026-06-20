# Balanceador classico: porta 80 publica -> porta 30080 dos nos
resource "aws_elb" "app" {
  name            = "taskflow-lb"
  subnets         = data.aws_subnets.default.ids
  security_groups = [aws_security_group.lb.id]
 
  listener {
    instance_port     = 30080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
 
  health_check {
    target              = "HTTP:30080/"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}
 
# Liga o balanceador ao GRUPO (assim todo no novo entra sozinho)
resource "aws_autoscaling_attachment" "lb" {
  autoscaling_group_name = aws_autoscaling_group.workers.name
  elb                    = aws_elb.app.id
}

