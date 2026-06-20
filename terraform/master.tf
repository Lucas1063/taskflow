resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_type
  key_name               = var.key_name
  subnet_id              = data.aws_subnets.default.ids[1]
  vpc_security_group_ids = [aws_security_group.cluster.id]
  iam_instance_profile   = var.instance_profile
  user_data              = file("${path.module}/scripts/master.sh")

  tags = {
    Name = "k3s-master"
    role = "infra"
  }
}

# --- Bloco de Automação do Kubernetes ---
resource "null_resource" "deploy_k8s" {
  # O Terraform só tenta rodar isso DEPOIS que o master estiver criado
  depends_on = [aws_instance.master]

  # Configuração de acesso SSH
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/vockey.pem") # Ajuste aqui se a sua chave tiver outro nome
    host        = aws_instance.master.public_ip
  }

  # Passo 1: Copia a pasta k8s (voltando um nível de diretório) para o Ubuntu
  provisioner "file" {
    source      = "${path.module}/../k8s"
    destination = "/home/ubuntu/k8s"
  }

  # Passo 2: Roda os comandos lá dentro
  provisioner "remote-exec" {
    inline = [
      "echo 'Aguardando o K3s iniciar (45 segundos)...'",
      "sleep 45",
      
      "echo 'Aplicando os arquivos YAML...'",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/databases.yaml",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/backend.yaml",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/frontend.yaml",
      
      "echo 'Deploy finalizado com sucesso!'"
    ]
  }
}