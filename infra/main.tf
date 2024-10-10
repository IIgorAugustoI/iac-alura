terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region_aws
}

resource "aws_launch_template" "maquina" {
  # AMI do Ubuntu us-west-1
  image_id      = var.ami_aws
  instance_type = var.instancia
  key_name      = var.chave
  tags = {
    Name = var.aplication_name
  }
  security_group_names = [var.security_group]
  user_data            = filebase64("ansible.sh")
}

resource "aws_key_pair" "chaveSSH" {
  key_name   = var.chave
  public_key = file("${var.chave}.pub")
}

# Pegar o IP público sem precisar acessar o painel da AWS
# OBS: É possível utilizar essa mesma lógica para pegar outras informações, como o DNS da máquina.

resource "aws_autoscaling_group" "grupo" {
  availability_zones = ["${var.region_aws}a", "${var.region_aws}b"]
  name               = var.nomeGrupo
  max_size           = var.maximo
  min_size           = var.minimo
  launch_template {
    id      = aws_launch_template.maquina.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.loadBalancer_alvo.arn]
}

resource "aws_default_subnet" "subnet_1" {
  availability_zone = "${var.region_aws}a"
}

resource "aws_default_subnet" "subnet_2" {
  availability_zone = "${var.region_aws}b"
}

resource "aws_lb" "loadBalancer" {
  internal        = false
  subnets         = [aws_default_subnet.subnet_1.id, aws_default_subnet.subnet_2.id]
  security_groups = [aws_security_group.acesso_geral.id]
}

resource "aws_default_vpc" "default" {

}

resource "aws_lb_target_group" "loadBalancer_alvo" {
  name     = "maquinasAlvo"
  port     = "8000"
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_listener" "entrada" {
  load_balancer_arn = aws_lb.loadBalancer.arn
  port              = "8000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loadBalancer_alvo.arn
  }
}

resource "aws_autoscaling_policy" "escalaDeProducao" {
  name                   = "terraform-escala"
  autoscaling_group_name = var.nomeGrupo
  # Definindo o escalonamento pela CPU
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
