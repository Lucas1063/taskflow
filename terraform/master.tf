resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_type
  key_name               = var.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.cluster.id]
  iam_instance_profile   = var.instance_profile
  user_data              = file("${path.module}/scripts/master.sh")
 
  tags = {
    Name = "k3s-master"
    role = "infra"
  }
}
