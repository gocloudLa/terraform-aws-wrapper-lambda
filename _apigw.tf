locals {
  create_apigateway_v2_integration_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}-${triggers}" = {
          api_id                    = try(trigger_values.api_id, null)
          integration_type          = "AWS_PROXY"
          connection_id             = try(trigger_values.connection_id, null)
          connection_type           = try(trigger_values.connection_type, "INTERNET")
          content_handling_strategy = try(trigger_values.content_handling_strategy, null)
          credentials_arn           = try(trigger_values.credentials_arn, null)
          description               = try(trigger_values.description, null)
          integration_method        = try(trigger_values.integration_method, try(trigger_values.integration_subtype, null) == null ? "POST" : null)
          integration_subtype       = try(trigger_values.integration_subtype, null)
          integration_uri           = module.lambda["${lambda_name}"].lambda_function_arn
          passthrough_behavior      = try(trigger_values.passthrough_behavior, null)
          payload_format_version    = try(trigger_values.payload_format_version, null)
          request_parameters        = try(jsondecode(trigger_values["request_parameters"]), trigger_values["request_parameters"], null)
          timeout_milliseconds      = try(trigger_values.timeout_milliseconds, null)
          response_parameters       = try(trigger_values.response_parameters, [])
          tls_config                = try(trigger_values.tls_config, [])
          #request_templates
          #template_selection_expression
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "apigateway" ? true : false))
    ]
  ]
  create_apigateway_v2_integration = merge(flatten(local.create_apigateway_v2_integration_tmp)...)

  create_apigateway_v2_routes_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}-${triggers}" = {
          api_id                              = try(trigger_values.api_id, null)
          route_key                           = try(trigger_values.route_key, "$default")
          api_key_required                    = try(trigger_values.api_key_required, null)
          authorization_scopes                = try(split(",", trigger_values.authorization_scopes), null)
          authorization_type                  = try(trigger_values.authorization_type, "NONE")
          authorizer_id                       = try(trigger_values.authorizer_id, null)
          model_selection_expression          = try(trigger_values.model_selection_expression, null)
          operation_name                      = try(trigger_values.operation_name, null)
          route_response_selection_expression = try(trigger_values.route_response_selection_expression, null)
          target                              = "integrations/${aws_apigatewayv2_integration.this["${lambda_name}-${triggers}"].id}"
          #request_models
          #request_parameter
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "apigateway" ? true : false))
    ]
  ]
  create_apigateway_v2_routes = merge(flatten(local.create_apigateway_v2_routes_tmp)...)

}

resource "aws_apigatewayv2_integration" "this" {
  for_each = local.create_apigateway_v2_integration

  api_id                    = each.value.api_id
  description               = each.value.description
  integration_type          = each.value.integration_type
  integration_subtype       = each.value.integration_subtype
  integration_method        = each.value.integration_method
  integration_uri           = each.value.integration_uri
  connection_type           = each.value.connection_type
  connection_id             = each.value.connection_id
  payload_format_version    = each.value.payload_format_version
  timeout_milliseconds      = each.value.timeout_milliseconds
  passthrough_behavior      = each.value.passthrough_behavior
  content_handling_strategy = each.value.content_handling_strategy
  credentials_arn           = each.value.credentials_arn
  request_parameters        = each.value.request_parameters

  dynamic "tls_config" {
    for_each = flatten([try(jsondecode(each.value["tls_config"]), each.value["tls_config"], [])])

    content {
      server_name_to_verify = tls_config.value["server_name_to_verify"]
    }
  }
  dynamic "response_parameters" {
    for_each = flatten([try(jsondecode(each.value["response_parameters"]), each.value["response_parameters"], [])])

    content {
      status_code = response_parameters.value["status_code"]
      mappings    = response_parameters.value["mappings"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Routes and integrations
resource "aws_apigatewayv2_route" "this" {
  for_each = local.create_apigateway_v2_routes

  api_id                              = each.value.api_id
  route_key                           = each.value.route_key
  api_key_required                    = each.value.api_key_required
  authorization_scopes                = each.value.authorization_scopes
  authorization_type                  = each.value.authorization_type
  authorizer_id                       = each.value.authorizer_id
  model_selection_expression          = each.value.model_selection_expression
  operation_name                      = each.value.operation_name
  route_response_selection_expression = each.value.route_response_selection_expression
  target                              = each.value.target

  # Have been added to the docs. But is WEBSOCKET only(not yet supported)
  # request_models  = try(each.value.request_models, null)
}