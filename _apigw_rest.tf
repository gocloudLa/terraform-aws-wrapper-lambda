## REST API Gateway (v1) triggers.
## Unlike the "alb" or "apigateway" (HTTP APIGWv2) trigger types, the REST API itself is not
## created here: it is expected to already exist (created by terraform-aws-wrapper-apigateway)
## and is looked up by name. This module only attaches the resource/method/integration needed
## to invoke the Lambda function, and owns the deployment/stage for the resources it creates.
locals {

  create_apigateway_rest_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}-${triggers}" = {
          lambda_name          = lambda_name
          rest_api_name        = try(trigger_values.rest_api_name, null)
          resource_path        = trim(try(trigger_values.resource_path, ""), "/")
          http_method          = try(trigger_values.http_method, "POST")
          authorization        = try(trigger_values.authorization, "NONE")
          authorizer_id        = try(trigger_values.authorizer_id, null)
          authorization_scopes = try(trigger_values.authorization_scopes, null)
          api_key_required     = try(trigger_values.api_key_required, false)
          request_parameters   = try(trigger_values.request_parameters, {})

          integration_type               = try(trigger_values.integration_type, "AWS_PROXY")
          integration_http_method        = try(trigger_values.integration_http_method, "POST")
          integration_request_parameters = try(trigger_values.integration_request_parameters, {})
          connection_type                = try(trigger_values.connection_type, null)
          connection_id                  = try(trigger_values.connection_id, null)
          credentials                    = try(trigger_values.credentials, null)
          content_handling_strategy      = try(trigger_values.content_handling_strategy, null)
          passthrough_behavior           = try(trigger_values.passthrough_behavior, null)
          request_templates              = try(trigger_values.request_templates, {})
          timeout_milliseconds           = try(trigger_values.timeout_milliseconds, 29000)

          stage_name = try(trigger_values.stage_name, local.metadata.key.env)
          source_arn = try(trigger_values.source_arn, null)
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "apigateway_rest" ? true : false))
    ]
  ]
  create_apigateway_rest = merge(flatten(local.create_apigateway_rest_tmp)...)

  # Unique REST APIs referenced by name across all lambda triggers
  apigateway_rest_names = toset([for key, value in local.create_apigateway_rest : value.rest_api_name])

  # Every unique ancestor path segment needed to build the resource tree, e.g. "wallet/{id}/balance"
  # requires resources for "wallet", "wallet/{id}" and "wallet/{id}/balance". "depth" (1-based) is
  # the number of path segments up to and including this entry.
  apigw_rest_resource_tree_tmp = [
    for key, value in local.create_apigateway_rest :
    value.resource_path != "" ? [
      for i in range(1, length(split("/", value.resource_path)) + 1) :
      {
        "${value.rest_api_name}//${join("/", slice(split("/", value.resource_path), 0, i))}" = {
          rest_api_name = value.rest_api_name
          path_part     = element(split("/", value.resource_path), i - 1)
          parent_path   = i > 1 ? join("/", slice(split("/", value.resource_path), 0, i - 1)) : null
          depth         = i
        }
      }
    ] : []
  ]
  apigw_rest_resource_tree = merge(flatten(local.apigw_rest_resource_tree_tmp)...)

  # Terraform forbids a for_each resource from referencing its own instances (even under a
  # different key) inside its own configuration ("Self-referential block"), so the tree can't be
  # built with a single self-referencing aws_api_gateway_resource block. Instead it is split into
  # one resource block per depth level, each level's parent_id pointing at the previous level's
  # resource block. This supports up to 6 nested path segments (e.g. "a/b/c/d/e/f"); extend
  # apigw_rest_max_depth and add a matching "level_N" resource block below if a deeper path is needed.
  apigw_rest_max_depth = 6
  apigw_rest_resource_tree_by_depth = {
    for depth in range(1, local.apigw_rest_max_depth + 1) :
    depth => { for k, v in local.apigw_rest_resource_tree : k => v if v.depth == depth }
  }

  # Every "level_N" resource block merged back together, keyed like apigw_rest_resource_tree.
  apigw_rest_resource_all = merge(
    aws_api_gateway_resource.level_1,
    aws_api_gateway_resource.level_2,
    aws_api_gateway_resource.level_3,
    aws_api_gateway_resource.level_4,
    aws_api_gateway_resource.level_5,
    aws_api_gateway_resource.level_6,
  )

  # Resolved resource_id per trigger: the deepest resource in the tree, or the API's root resource
  apigw_rest_resource_id = {
    for key, value in local.create_apigateway_rest :
    key => value.resource_path != "" ? local.apigw_rest_resource_all["${value.rest_api_name}//${value.resource_path}"].id : data.aws_api_gateway_rest_api.this[value.rest_api_name].root_resource_id
  }
}

data "aws_api_gateway_rest_api" "this" {
  for_each = local.apigateway_rest_names

  name = each.value
}

resource "aws_api_gateway_resource" "level_1" {
  for_each = local.apigw_rest_resource_tree_by_depth[1]

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  parent_id   = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level_2" {
  for_each = local.apigw_rest_resource_tree_by_depth[2]

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  parent_id   = aws_api_gateway_resource.level_1["${each.value.rest_api_name}//${each.value.parent_path}"].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level_3" {
  for_each = local.apigw_rest_resource_tree_by_depth[3]

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  parent_id   = aws_api_gateway_resource.level_2["${each.value.rest_api_name}//${each.value.parent_path}"].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level_4" {
  for_each = local.apigw_rest_resource_tree_by_depth[4]

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  parent_id   = aws_api_gateway_resource.level_3["${each.value.rest_api_name}//${each.value.parent_path}"].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level_5" {
  for_each = local.apigw_rest_resource_tree_by_depth[5]

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  parent_id   = aws_api_gateway_resource.level_4["${each.value.rest_api_name}//${each.value.parent_path}"].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level_6" {
  for_each = local.apigw_rest_resource_tree_by_depth[6]

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  parent_id   = aws_api_gateway_resource.level_5["${each.value.rest_api_name}//${each.value.parent_path}"].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_method" "this" {
  for_each = local.create_apigateway_rest

  rest_api_id          = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  resource_id          = local.apigw_rest_resource_id[each.key]
  http_method          = each.value.http_method
  authorization        = each.value.authorization
  authorizer_id        = each.value.authorizer_id
  authorization_scopes = each.value.authorization_scopes
  api_key_required     = each.value.api_key_required
  request_parameters   = each.value.request_parameters
}

resource "aws_api_gateway_integration" "this" {
  for_each = local.create_apigateway_rest

  rest_api_id             = data.aws_api_gateway_rest_api.this[each.value.rest_api_name].id
  resource_id             = local.apigw_rest_resource_id[each.key]
  http_method             = aws_api_gateway_method.this[each.key].http_method
  type                    = each.value.integration_type
  integration_http_method = each.value.integration_type == "MOCK" ? null : each.value.integration_http_method
  uri                     = each.value.integration_type == "MOCK" ? null : module.lambda[each.value.lambda_name].lambda_function_invoke_arn
  connection_type         = each.value.connection_type
  connection_id           = each.value.connection_id
  credentials             = each.value.credentials
  content_handling        = each.value.content_handling_strategy
  passthrough_behavior    = each.value.passthrough_behavior
  request_templates       = each.value.request_templates
  request_parameters      = each.value.integration_request_parameters
  timeout_milliseconds    = each.value.timeout_milliseconds

  depends_on = [aws_api_gateway_method.this]
}

locals {
  apigateway_rest_signature = {
    for name in local.apigateway_rest_names :
    name => sha1(jsonencode({
      resources    = { for k, v in local.apigw_rest_resource_all : k => v if startswith(k, "${name}//") }
      methods      = { for k, v in aws_api_gateway_method.this : k => v if local.create_apigateway_rest[k].rest_api_name == name }
      integrations = { for k, v in aws_api_gateway_integration.this : k => v if local.create_apigateway_rest[k].rest_api_name == name }
    }))
  }

  # First non-default stage_name requested among the triggers of a given REST API
  apigateway_rest_stage_name = {
    for name in local.apigateway_rest_names :
    name => try([for key, value in local.create_apigateway_rest : value.stage_name if value.rest_api_name == name][0], local.metadata.key.env)
  }
}

resource "aws_api_gateway_deployment" "this" {
  for_each = local.apigateway_rest_names

  rest_api_id = data.aws_api_gateway_rest_api.this[each.value].id

  triggers = {
    redeployment = local.apigateway_rest_signature[each.value]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
  ]
}

resource "aws_api_gateway_stage" "this" {
  for_each = local.apigateway_rest_names

  rest_api_id   = data.aws_api_gateway_rest_api.this[each.value].id
  deployment_id = aws_api_gateway_deployment.this[each.value].id
  stage_name    = local.apigateway_rest_stage_name[each.value]

  tags = local.common_tags
}