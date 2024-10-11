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
  # Utilizando operador ternario.
  user_data = var.producao ? ("ansible.sh") : ""
}

resource "aws_key_pair" "chaveSSH" {
  key_name   = var.chave
  public_key = file("${var.chave}.pub")
}


resource "aws_autoscaling_group" "grupo" {
  availability_zones = ["${var.region_aws}a", "${var.region_aws}b"]
  name               = var.nomeGrupo
  max_size           = var.maximo
  min_size           = var.minimo
  target_group_arns  = var.producao ? [aws_lb_target_group.loadBalancer_alvo[0].arn] : []
  launch_template {
    id      = aws_launch_template.maquina.id
    version = "$Latest"
  }
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
  # Count é utilizado para definir quantos recursos o terraform irá criar.
  count = var.producao ? 1 : 0
}

resource "aws_default_vpc" "default" {

}

resource "aws_lb_target_group" "loadBalancer_alvo" {
  name     = "maquinasAlvo"
  port     = "8000"
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
  # Count é utilizado para definir quantos recursos o terraform irá criar.
  count = var.producao ? 1 : 0
}

resource "aws_lb_listener" "entrada" {
  load_balancer_arn = aws_lb.loadBalancer[0].arn
  port              = "8000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loadBalancer_alvo[0].arn
  }
  # Count é utilizado para definir quantos recursos o terraform irá criar.
  count = var.producao ? 1 : 0
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
  # Count é utilizado para definir quantos recursos o terraform irá criar.
  count = var.producao ? 1 : 0
}
