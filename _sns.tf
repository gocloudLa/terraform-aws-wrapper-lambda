locals {
  create_sns_suscription_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}-${triggers}" = {
          lambda_name = "${lambda_name}"
          source_arn  = try(trigger_values.sns_topic_arn, null)
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "sns" ? true : false))
    ]
  ]
  create_sns_suscription = merge(flatten(local.create_sns_suscription_tmp)...)
}

resource "aws_sns_topic_subscription" "this" {
  for_each = local.create_sns_suscription

  topic_arn = each.value.source_arn
  protocol  = "lambda"
  endpoint  = module.lambda["${each.value.lambda_name}"].lambda_function_arn
}