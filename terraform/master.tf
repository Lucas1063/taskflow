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

resource "null_resource" "deploy_k8s" {
  depends_on = [aws_instance.master, aws_sqs_queue.events]

  triggers = {
    master_id          = aws_instance.master.id
    sqs_url            = aws_sqs_queue.events.url
    jwt_secret         = var.jwt_secret
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
      "echo 'Aguardando o k3s ficar pronto...'",
      "until sudo k3s kubectl get nodes >/dev/null 2>&1; do echo 'k3s ainda nao respondeu, aguardando 5s...'; sleep 5; done",
      "echo 'k3s pronto!'",
      "echo 'Criando o Namespace taskflow...'",
      "sudo k3s kubectl create namespace taskflow || true",
      "echo 'Aplicando os arquivos YAML...'",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/databases.yaml",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/backend.yaml",
      "sudo k3s kubectl apply -f /home/ubuntu/k8s/frontend.yaml",
      "echo 'Deploy finalizado com sucesso!'"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo k3s kubectl create secret generic taskflow-config -n taskflow --from-literal=MONGO_URL='mongodb://mongo:27017/taskflow' --from-literal=JWT_SECRET='${var.jwt_secret}' --from-literal=SQS_URL='${aws_sqs_queue.events.url}' --dry-run=client -o yaml | sudo k3s kubectl apply -f -",
      "echo 'Secret taskflow-config aplicado com sucesso!'"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo k3s kubectl rollout restart deployment/backend -n taskflow || true",
      "sudo k3s kubectl rollout status deployment/backend -n taskflow --timeout=120s || true"
    ]
  }
}