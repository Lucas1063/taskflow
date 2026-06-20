variable "docker_user" {
  default = "lucasw1063"
}
variable "image_tag" {
  default = "1.0"
}
variable "key_name" {
  default = "vockey"
}
variable "instance_profile" {
  default = "LabInstanceProfile"
}
variable "notification_email" {
  default = "lucas.weige@unidavi.edu.br"
}
variable "master_type" {
  default = "t3.medium"
}
variable "worker_type" {
  default = "t3.small"
}
