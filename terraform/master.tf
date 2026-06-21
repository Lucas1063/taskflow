resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_type
  key_name               = var.key_name
  subnet_id              = data.aws_subnets.default.ids[1]
  iam_instance_profile   = var.instance_profile
  user_data              = file("${path.module}/scripts/master.sh")
  vpc_security_group_ids = [
    aws_security_group.cluster.id,
    aws_security_group.app_from_lb.id
  ]

  tags = {
    Name = "k3s-master"
    role = "infra"
  }
}

# --- Bloco de Automação do Kubernetes ---
resource "null_resource" "deploy_k8s" {
  # O Terraform só tenta rodar isso DEPOIS que o master e a fila existirem
  depends_on = [aws_instance.master, aws_sqs_queue.events]

  # Re-roda automaticamente se algum desses valores mudar
  triggers = {
    master_id  = aws_instance.master.id
    sqs_url    = aws_sqs_queue.events.url
    jwt_secret = var.jwt_secret
    k8s_manifests_hash = sha1(join("", [for f in fileset("${path.module}/../k8s", "*.yaml") : filesha1("${path.module}/../k8s/${f}")]))
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/vockey.pem")
    host        = aws_instance.master.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/../k8s"
    destination = "/home/ubuntu/k8s"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Aguardando o K3s iniciar (45 segundos)...'",
      "sleep 45",
      "echo 'Criando o Namespace taskflow...'",
      "sudo k3s kubectl create namespace taskflow || true",
      "echo 'Criando/atualizando o secret taskflow-config...'",
      "sudo k3s kubectl create secret generic taskflow-config -n taskflow \\",
      "  --from-literal=MONGO_URL='mongodb://mongo:27017/taskflow' \\",
      "  --from-literal=JWT_SECRET='${var.jwt_secret}' \\",
      "  --from-literal=SQS_URL='${aws_sqs_queue.events.url}' \\",
      "  --dry-run=client -o yaml | sudo k3s kubectl apply -f -",
      "echo 'Aplicando os arquivos YAML...'",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/databases.yaml",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/backend.yaml",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/frontend.yaml",
      "echo 'Deploy finalizado com sucesso!'"
    ]
  }
}