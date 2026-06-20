# Firewall do cluster: SSH + tudo entre as maquinas do grupo
resource "aws_security_group" "cluster" {
  name   = "cluster"
  vpc_id = data.aws_vpc.default.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# Firewall do balanceador: so a porta 80 publica
resource "aws_security_group" "lb" {
  name   = "lb"
  vpc_id = data.aws_vpc.default.id
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# Deixa o balanceador alcancar a porta 30080 dos nos
resource "aws_security_group" "app_from_lb" {
  name   = "app-from-lb"
  vpc_id = data.aws_vpc.default.id
 
  ingress {
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
