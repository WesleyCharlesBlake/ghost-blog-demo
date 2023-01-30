data "aws_availability_zones" "available" {}

data "aws_iam_roles" "eks-admin-sso" {
  name_regex  = "AWSReservedSSO_EKSAdministratorAccess_.+"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_caller_identity" "current" {}
