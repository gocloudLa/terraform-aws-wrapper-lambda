module "wrapper_lambda" {
  source = "../../"

  metadata = local.metadata

  lambda_parameters = {
    # Lambda function mounted in VPC
    "ApiGwEndpoint" = {
      create = true

      description             = "Multiple trigger example"
      handler                 = "app.py"
      runtime                 = "python3.9"
      ignore_source_code_hash = true
      create_package          = false
      local_existing_package  = "./lambda_functions/python_hello.zip"

      memory_size = 256
      timeout     = 10

      create_current_version_allowed_triggers = false
      triggers = {
        "trigger-apiv2-get" = {
          trigger_type     = "apigateway"
          api_id           = module.api_gateway.apigatewayv2_api_id
          integration_type = "AWS_PROXY"
          connection_type  = "INTERNET"
          #content_handling_strategy = "CONVERT_TO_TEXT"
          description        = "Lambda example"
          integration_method = "ANY"
          #integration_uri           = aws_lambda_function.example.invoke_arn
          #passthrough_behavior      = "WHEN_NO_MATCH"
          payload_format_version = "2.0"
          timeout_milliseconds   = 12000
          route_key              = "ANY /example/{proxy+}"
        }
      }

      environment_variables = {}
    }
  }
  lambda_defaults = var.lambda_defaults

}

##### APIGWV2 Testing ####
module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "4.0.0"

  name          = "${local.common_name}-http"
  description   = "My HTTP API Gateway V2"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  create_api_domain_name = false

}
##############################