locals {

  create_sqs_event_source_mapping_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        for key, value in {
          service                            = "sqs"
          batch_size                         = try(trigger_values.batch_size, 10)
          destination_arn_on_failure         = try(trigger_values.destination_arn_on_failure, null)
          enabled                            = try(trigger_values.enabled, true)
          event_source_arn                   = try(trigger_values.source_arn, null)
          filter_criteria                    = try(trigger_values.filter_criteria, null)
          function_response_types            = try(trigger_values.function_response_types, null)
          maximum_batching_window_in_seconds = try(trigger_values.maximum_batching_window_in_seconds, null)
          metrics_config                     = try(trigger_values.metrics_config, null)
          scaling_config                     = try(trigger_values.scaling_config, null)
        } : key => value if value != null
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
      trigger_values.trigger_type == "sqs")
    }
  }

  create_dynamodb_event_source_mapping_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    "${lambda_name}" => {
      for trigger_name, trigger_values in try(lambda_config.triggers, {}) :
      "${trigger_name}" => {
        for key, value in {
          service                            = "dynamodb"
          batch_size                         = try(trigger_values.batch_size, 100)
          bisect_batch_on_function_error     = try(trigger_values.bisect_batch_on_function_error, false)
          enabled                            = try(trigger_values.enabled, true)
          event_source_arn                   = try(trigger_values.source_arn, null)
          destination_arn_on_failure         = try(trigger_values.destination_arn_on_failure, null)
          filter_criteria                    = try(trigger_values.filter_criteria, null)
          function_response_types            = try(trigger_values.function_response_types, null)
          maximum_batching_window_in_seconds = try(trigger_values.maximum_batching_window_in_seconds, null)
          maximum_record_age_in_seconds      = try(trigger_values.maximum_record_age_in_seconds, null)
          maximum_retry_attempts             = try(trigger_values.maximum_retry_attempts, null)
          metrics_config                     = try(trigger_values.metrics_config, null)
          starting_position                  = try(trigger_values.starting_position, null)
          starting_position_timestamp        = try(trigger_values.starting_position_timestamp, null)
          parallelization_factor             = try(trigger_values.parallelization_factor, 1)
        } : key => value if value != null
        } if(
        (length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) &&
      trigger_values.trigger_type == "dynamodb")
    }

  }

  custom_event_source_mapping_calculated = {
    for lambda_name, lambda_config in var.lambda_parameters :
    lambda_name => merge(
      lookup(local.create_sqs_event_source_mapping_calculated, lambda_name, {}) != {} ? local.create_sqs_event_source_mapping_calculated["${lambda_name}"] : {},
      lookup(local.create_dynamodb_event_source_mapping_calculated, lambda_name, {}) != {} ? local.create_dynamodb_event_source_mapping_calculated["${lambda_name}"] : {}
    ) if(try(lambda_config.create, true))
  }
}