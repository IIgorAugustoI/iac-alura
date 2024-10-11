module "aws-dev" {
  aplication_name = "App Dev"
  source          = "../../infra"
  chave           = "IaC-DEV"
  region_aws      = "us-west-2" # Oregon
  instancia       = "t2.micro"
  ami_aws         = "ami-04dd23e62ed049936"
  security_group  = "sg_dev"
  minimo          = 1
  maximo          = 1
  nomeGrupo       = "Desenvolvimento"
  producao        = false
}
