data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  vpc_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    lambda_name => {
      "vpc_name"       = try(lambda_config.vpc_name, local.default_vpc_name)
      "subnet_name"    = try(lambda_config.subnet_name, local.default_subnet_name)
      "security_group" = try(lambda_config.security_group, local.default_security_group)
    } if try(lambda_config.attach_vpc, false) == true
  }
}

data "aws_vpc" "this" {
  for_each = local.vpc_calculated

  filter {
    name   = "tag:Name"
    values = [each.value.vpc_name]
  }
}

data "aws_subnets" "this" {
  for_each = local.vpc_calculated

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this[each.key].id]
  }

  tags = {
    Name = each.value.subnet_name
  }
}

data "aws_security_group" "default" {
  for_each = local.vpc_calculated

  vpc_id = data.aws_vpc.this[each.key].id

  tags = {
    Name = each.value.security_group
  }
}