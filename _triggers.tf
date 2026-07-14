## triggers
locals {

  create_lb_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "elasticloadbalancing.amazonaws.com"
        source_arn = aws_lb_target_group.this[lambda_name].arn
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "alb"
      )
    }
  }

  create_eventbridge_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "events.amazonaws.com"
        source_arn = aws_cloudwatch_event_rule.this["${lambda_name}-${trigger_name}"].arn
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "eventbridge"
      )
    }
  }

  create_sns_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "sns.amazonaws.com"
        source_arn = try(trigger_values.sns_topic_arn, null)
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "sns"
      )
    }
  }

  create_sqs_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "sqs.amazonaws.com"
        source_arn = try(trigger_values.source_arn, null)
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "sqs"
      )
    }
  }

  create_s3_notification_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "s3.amazonaws.com"
        action     = "lambda:InvokeFunction"
        source_arn = try(data.aws_s3_bucket.this["${lambda_name}-${trigger_name}"].arn, null) #trigger_values.bucket_name, null)
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "s3_notification"
      )
    }
  }

  create_dynamodb_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "dynamodb.amazonaws.com"
        source_arn = try(trigger_values.source_arn, null)
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "dynamodb"
      )
    }
  }

  create_apigw_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal  = "apigateway.amazonaws.com"
        source_arn = try(trigger_values.source_arn, null)
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "apigateway"
      )
    }
  }

  # REST API Gateway (v1). source_arn defaults to "<execution_arn>/*/<HTTP_METHOD>/<resource_path>",
  # scoped to the exact method+resource created in _apigw_rest.tf. MOCK integrations do not invoke
  # the Lambda function, so no permission is required for them.
  create_apigw_rest_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        principal = "apigateway.amazonaws.com"
        source_arn = try(
          trigger_values.source_arn,
          "${data.aws_api_gateway_rest_api.this[trigger_values.rest_api_name].execution_arn}/*/${upper(try(trigger_values.http_method, "POST"))}/${trim(try(trigger_values.resource_path, ""), "/")}"
        )
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
        trigger_values.trigger_type == "apigateway_rest" &&
        try(trigger_values.integration_type, "AWS_PROXY") != "MOCK"
      )
    }
  }

  custom_allowed_triggers_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    lambda_name => merge(
      lookup(local.create_lb_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_eventbridge_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_sns_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_sqs_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_apigw_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_apigw_rest_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_s3_notification_allowed_triggers_calculated, lambda_name, {}),
      lookup(local.create_dynamodb_allowed_triggers_calculated, lambda_name, {})
    ) if(try(lambda_config.create, true))
  }
}