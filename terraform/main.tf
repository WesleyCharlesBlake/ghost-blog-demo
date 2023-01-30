#---------------------------------------------------------------
# EKS Blueprints
#---------------------------------------------------------------
module "eks_blueprints" {
  source  = "app.terraform.io/stratotechnology/eks-blueprints/aws"
  version = "4.22.0"

  # insert required variables here
  cluster_name    = local.name
  cluster_version = local.cluster_version

  vpc_id             = module.aws-vpc.vpc_id
  private_subnet_ids = module.aws-vpc.private_subnets

  managed_node_groups = {

    ghost_ng = {
      node_group_name = "ghost-ng"
      instance_types  = ["t3.medium"]
      min_size        = 1
      max_size        = 3
      desired_size    = 1
      subnet_ids      = module.aws-vpc.private_subnets

      k8s_labels = {
        Application = "blog"
        Name        = "ghost-ng"
      }

      additional_tags = {
        Name        = "blog"
        subnet_type = "private"
      }
    }

  }

  platform_teams = {
    sso-administrators = {
      users = data.aws_iam_roles.eks-admin-sso.arns
    }
  }

  # List of map_roles
  map_roles = []

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source  = "app.terraform.io/stratotechnology/eks-blueprints/aws//modules/kubernetes-addons"
  version = "4.22.0"

  # insert required variables here

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version
  eks_cluster_domain   = "demo.stratotechnology.com"

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni = true
  amazon_eks_vpc_cni_config = {
    most_recent       = true
    resolve_conflicts = "OVERWRITE"
  }

  enable_amazon_eks_coredns = true
  amazon_eks_coredns_config = {
    most_recent = true
  }

  enable_amazon_eks_kube_proxy = true
  amazon_eks_kube_proxy_config = {
    most_recent = true
  }

  # Add-ons
  enable_argocd        = true
  enable_argo_rollouts = false

  enable_metrics_server     = true
  enable_cluster_autoscaler = true
  enable_ingress_nginx      = true
  ingress_nginx_helm_config = {
    create_namespace = true
  }

  enable_self_managed_aws_ebs_csi_driver = true
  self_managed_aws_ebs_csi_driver_helm_config = {
    values = [file("${path.module}/helm_values/aws-ebs-csi-driver-values.yaml")]
  }

  enable_external_secrets = true
  external_secrets_helm_config = {
    create_namespace = true
  }

  enable_cert_manager            = true
  cert_manager_letsencrypt_email = "devops@stratotechnology.com"
  cert_manager_domain_names      = ["demo.stratotechnology.com"]

  enable_external_dns = true



  tags = local.tags
}

#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------
module "aws-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
    "Name"                                        = "${local.name}-public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    "Name"                                        = "${local.name}-private"
  }

  tags = local.tags
}
