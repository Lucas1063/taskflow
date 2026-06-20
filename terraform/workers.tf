# Modelo (receita) de cada worker
resource "aws_launch_template" "worker" {
  name          = "lt-k3s-worker"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.worker_type
  key_name      = var.key_name
 
  iam_instance_profile {
    name = var.instance_profile
  }
 
  vpc_security_group_ids = [
    aws_security_group.cluster.id,
    aws_security_group.app_from_lb.id
  ]
 
  user_data = base64encode(file("${path.module}/scripts/worker.sh"))
 
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k3s-worker"
    }
  }
}
 
# O grupo que cria e remove maquinas sozinho
resource "aws_autoscaling_group" "workers" {
  name                = "asg-k3s-workers"
  min_size            = 1
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = data.aws_subnets.default.ids
 
  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }
 
  tag {
    key                 = "Name"
    value               = "k3s-worker"
    propagate_at_launch = true
  }
 
  depends_on = [aws_instance.master]
}
 
# Regra: passou de 40% de CPU media, cria maquina; abaixou, remove
resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-target-40"
  autoscaling_group_name = aws_autoscaling_group.workers.name
  policy_type            = "TargetTrackingScaling"
 
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}
