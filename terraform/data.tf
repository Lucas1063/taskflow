# Rede padrao (usamos a que ja existe, nao criamos uma nova)
data "aws_vpc" "default" {
  default = true
}
 
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
 
# Imagem do Ubuntu mais recente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
 
# Papel pronto do AWS Academy (NAO criamos IAM aqui)
data "aws_iam_role" "lab" {
  name = "LabRole"
}
