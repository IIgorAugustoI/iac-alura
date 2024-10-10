module "aws-dev" {
  aplication_name     = "App Dev"
  source              = "../../infra"
  chave               = "IaC-DEV"
  region_aws          = "us-west-1" # Norte da California
  instancia           = "t2.micro"
  ami_aws             = "ami-0da424eb883458071"
  security_group_name = "sg_dev"
}

output "IP" {
  value = module.aws_dev.IP_publico
}
