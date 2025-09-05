locals {

  create_s3_bucket_notification_configuration_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}-${triggers}" = {
          lambda_name   = "${lambda_name}"
          bucket_name   = trigger_values.bucket_name
          events        = try(trigger_values.events, null)
          filter_prefix = try(trigger_values.filter_prefix, null)
          filter_suffix = try(trigger_values.filter_suffix, null)
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "s3_notification" ? true : false))
    ]
  ]
  create_s3_bucket_notification_configuration = merge(flatten(local.create_s3_bucket_notification_configuration_tmp)...)

}

data "aws_s3_bucket" "this" {
  for_each = local.create_s3_bucket_notification_configuration

  bucket = each.value.bucket_name
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = local.create_s3_bucket_notification_configuration

  bucket = data.aws_s3_bucket.this["${each.key}"].id

  lambda_function {
    lambda_function_arn = module.lambda["${each.value.lambda_name}"].lambda_function_arn
    events              = each.value.events
    filter_prefix       = each.value.filter_prefix
    filter_suffix       = each.value.filter_suffix
  }
}