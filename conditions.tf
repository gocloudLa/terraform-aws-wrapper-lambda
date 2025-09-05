locals {

  vpc_attachment_variables_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    {
      "${lambda_name}" = {
        vpc_security_group_ids = try(lambda_config.vpc_security_group_ids, [data.aws_security_group.default[lambda_name].id], null)
        vpc_subnet_ids         = try(lambda_config.vpc_subnet_ids, data.aws_subnets.this[lambda_name].ids, null)
        attach_network_policy  = true
      }
    } if try(lambda_config.attach_vpc, false) == true
  ]
  vpc_attachment_variables = merge(flatten(local.vpc_attachment_variables_tmp)...)

  local_existing_package_calculated_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    {
      "${lambda_name}" = try(lambda_config.local_existing_package, "${path.module}/lambdas/example.zip", null)

    } if !can(lambda_config.image_uri) && !can(lambda_config.source_path) && !can(lambda_config.s3_existing_package)
  ]
  local_existing_package_calculated = merge(flatten(local.local_existing_package_calculated_tmp)...)

}