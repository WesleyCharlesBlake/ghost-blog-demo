locals {
  name            = terraform.workspace
  cluster_name    = terraform.workspace
  cluster_version = "1.24"
  region          = var.region
  vpc_cidr        = "10.26.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Blueprint  = local.name
    Env        = var.env
    GithubRepo = "github.com/WesleyCharlesBlake/ghost-blog-demo"
  }
}
