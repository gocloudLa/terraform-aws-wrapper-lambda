module "wrapper_lambda" {
  source = "../../"

  metadata = local.metadata

  lambda_parameters = {
    # Lambda function triggered by a REST (v1) API Gateway endpoint
    "ExApiGwRest" = {
      create = true

      description             = "REST API Gateway trigger example"
      handler                 = "index.lambda_handler"
      runtime                 = "python3.9"
      ignore_source_code_hash = true
      create_package          = false
      local_existing_package  = "./lambda_functions/python_hello.zip"

      memory_size = 256
      timeout     = 10

      create_current_version_allowed_triggers = false
      triggers = {
        "trigger-rest-get" = {
          trigger_type = "apigateway_rest"
          # Assumed to already exist, created separately via terraform-aws-wrapper-apigateway
          # (see that repo's examples/complete) with apigateway_rest_parameters = { "rest-00" = {} }.
          rest_api_name = "${local.common_name}-rest-00"
          resource_path = "example"
          http_method   = "GET"
          # integration_type        = "AWS_PROXY" # Default
          # integration_http_method = "POST"      # Default
          # authorization           = "NONE"      # Default
          # stage_name              = "lab"        # Default: metadata.key.env
        }
      }

      environment_variables = {}
    }

    # Second Lambda function, attached to a different (nested, parameterized) path on the same
    # REST API, showcasing the more advanced trigger options.
    "ExApiGwRestAdvanced" = {
      create = true

      description             = "REST API Gateway trigger example - nested path + advanced options"
      handler                 = "index.lambda_handler"
      runtime                 = "python3.9"
      ignore_source_code_hash = true
      create_package          = false
      local_existing_package  = "./lambda_functions/python_hello.zip"

      memory_size = 256
      timeout     = 10

      create_current_version_allowed_triggers = false
      triggers = {
        "trigger-rest-get-by-id" = {
          trigger_type  = "apigateway_rest"
          rest_api_name = "${local.common_name}-rest-00"
          # Nested path: creates the "example" and "example/{id}" resources under the same REST API
          # used by ApiGwRestEndpoint above (shared ancestor resources are only created once).
          resource_path = "example/{id}"
          http_method   = "GET"

          # Require the {id} path parameter on every request hitting this method.
          request_parameters = {
            "method.request.path.id" = true
            # "method.request.querystring.debug" = false # Optional query string param example
          }
          # Forward that same path parameter into the Lambda proxy integration.
          integration_request_parameters = {
            "integration.request.path.id" = "method.request.path.id"
          }

          # integration_type        = "AWS_PROXY" # Default. Use "MOCK" for endpoints with no backend
          #                                        # (e.g. CORS preflight); MOCK integrations don't need
          #                                        # Lambda invoke permissions.
          # integration_http_method = "POST"      # Default. Method APIGateway uses to call the integration
          # content_handling_strategy = "CONVERT_TO_TEXT" # Or "CONVERT_TO_BINARY"; default: passthrough
          # passthrough_behavior      = "WHEN_NO_MATCH"   # Default when unset; also: WHEN_NO_TEMPLATES, NEVER
          # request_templates         = { "application/json" = "{\"id\": \"$input.params('id')\"}" }
          # timeout_milliseconds      = 5000      # Default: 29000 (API Gateway's own hard cap)

          # authorization        = "NONE"    # Default. Also: "CUSTOM" (Lambda authorizer), "COGNITO_USER_POOLS", "AWS_IAM"
          # authorizer_id        = module.wrapper_apigateway.apigateway_rest["rest-00"].authorizers["lambda-authorizer"].id
          # authorization_scopes = ["read:example"] # Only used with COGNITO_USER_POOLS authorization
          # api_key_required     = true # Require the x-api-key header (needs a usage plan + API key, configured separately)

          # connection_type = "VPC_LINK" # Default: null (public integration). Use with an existing VPC Link
          # connection_id   = aws_api_gateway_vpc_link.this.id
          # credentials     = aws_iam_role.apigateway_invoke.arn # IAM role APIGateway assumes to call the integration

          # stage_name = "lab" # Default: metadata.key.env. Shares the stage with every other trigger
          #                     # targeting the same rest_api_name unless overridden (see important_notes
          #                     # in the root README.yml about shared stages across workloads).
          # source_arn = "arn:aws:execute-api:us-east-2:123456789012:abcdef1234/*/GET/example/*" # Override the auto-derived permission source_arn
        }
      }

      environment_variables = {}
    }
  }
  lambda_defaults = var.lambda_defaults

}
