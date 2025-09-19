/*----------------------------------------------------------------------*/
/* Lambda Scheduler                                                     */
/*----------------------------------------------------------------------*/
locals {
  create_schedule_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}-${triggers}" = {
          lambda_name         = "${lambda_name}"
          schedule_expression = try(trigger_values.schedule, null)
          event_bus_name      = try(trigger_values.event_bus_name, null)
          event_pattern       = try(trigger_values.event_pattern, null)
          role_arn            = try(trigger_values.role_arn, null)
          state               = try(trigger_values.state, null)
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "eventbridge" ? true : false))
    ]
  ]
  create_schedule = merge(flatten(local.create_schedule_tmp)...)
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.create_schedule

  name                = each.key
  description         = "Event Rule that triggers ${each.value.lambda_name}"
  event_bus_name      = try(each.value.event_bus_name, null)
  schedule_expression = try(each.value.schedule_expression, null)
  event_pattern       = try(each.value.event_pattern, null)
  role_arn            = try(each.value.role_arn, null)
  state               = try(each.value.state, "ENABLED")

  tags = merge(local.common_tags, { workload = each.key.lambda_name }, try(each.value.tags, var.lambda_defaults.tags, null))
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.create_schedule

  rule = aws_cloudwatch_event_rule.this["${each.key}"].name
  arn  = module.lambda["${each.value.lambda_name}"].lambda_function_arn
}
