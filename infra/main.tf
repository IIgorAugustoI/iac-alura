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

resource "aws_instance" "app_server" {
  # AMI do Ubuntu us-west-1
  ami             = var.ami_aws
  instance_type   = var.instancia
  key_name        = var.chave
  security_groups = [aws_security_group.acesso_geral.name]
  tags = {
    Name = var.aplication_name
  }
}

resource "aws_key_pair" "chaveSSH" {
  key_name   = var.chave
  public_key = file("${var.chave}.pub")
}

# Pegar o IP público sem precisar acessar o painel da AWS
# OBS: É possível utilizar essa mesma lógica para pegar outras informações, como o DNS da máquina.
output "IP_publico" {
  value = aws_instance.app_server.public_ip
}
