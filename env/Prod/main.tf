module "aws-prod" {
  aplication_name = "App Prod"
  source          = "../../infra"
  chave           = "IaC-Prod"
  region_aws      = "us-west-2" # Oregon
  instancia       = "t2.micro"
  ami_aws         = "ami-04dd23e62ed049936"
  security_group  = "sg_prod"
  minimo          = 1
  maximo          = 10
  nomeGrupo       = "producao"
  producao        = true
}
