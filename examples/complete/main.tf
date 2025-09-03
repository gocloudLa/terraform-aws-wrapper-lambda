module "wrapper_lambda" {
  source = "../../"

  metadata = local.metadata

  lambda_parameters = {
    # Simple lambda
    "ExSimple" = {
      # create = false

      description             = "Simple example of functon"
      handler                 = "index.lambda_handler"
      runtime                 = "python3.9"
      create_package          = false
      ignore_source_code_hash = true
      ## If only attach_vpc is enabled, it uses the default values from datasources
      attach_vpc = true
      ## Filter by VPC name modifying datasources
      #vpc_name = "dmc-prd"
      #subnet_name = "dmc-prd-public*"
      #security_group = "dmc-prd-default"
      ## Using IDs as variables
      #vpc_subnet_ids = ["subnet-0816f01da43f4f564"]
      #vpc_security_group_ids  = ["sg-0281b2c2fff506cea"]
      memory_size              = 256
      timeout                  = 10
      attach_policy_statements = true
      policy_statements = {
        s3 = {
          effect    = "Allow",
          actions   = ["s3:List*"]
          resources = ["arn:aws:s3:::*"]
        }
      }
      environment_variables = {}
    }

    #  Lambda function with ALB triggers
    "ExBalancer" = {
      # create = false

      description                             = "Load Balancer Example"
      handler                                 = "index.lambda_handler"
      runtime                                 = "python3.9"
      ignore_source_code_hash                 = true
      create_package                          = false
      local_existing_package                  = "./lambda_functions/python_hello.zip"
      memory_size                             = 128
      timeout                                 = 10
      create_current_version_allowed_triggers = false
      triggers = {
        "trigger-01" = {
          trigger_type  = "alb"
          alb_name      = "dmc-prd-core-external-00"
          listener_port = 443
          # lambda_multi_value_headers_enabled = false # Default: false
          listener_rules = {
            "redirect" = {
              priority = 100
              actions = [{
                type        = "redirect"
                host        = "google.com"
                port        = 443
                status_code = "HTTP_301"
              }]
              conditions = [{
                host_headers = ["redirect.${local.zone_public}"]
              }]
            }
            "forward" = {
              #actions = [{
              #  type = "forward"
              #}]
              conditions = [{
                host_headers = ["ExBalancer.${local.zone_public}"]
              }]
            }
          }
        }
      }
      environment_variables = {}
    }

    # Lambda function mounted in VPC
    "ExTriggers" = {
      # create = false

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
        # "trigger-apiv2-get" = {
        #   trigger_type  = "apigateway"
        #   api_id = module.api_gateway.apigatewayv2_api_id
        #   integration_type = "AWS_PROXY"
        #   connection_type           = "INTERNET"
        #   #content_handling_strategy = "CONVERT_TO_TEXT"
        #   description               = "Lambda example"
        #   integration_method        = "ANY"
        #   #integration_uri           = aws_lambda_function.example.invoke_arn
        #   #passthrough_behavior      = "WHEN_NO_MATCH"
        #   payload_format_version = "2.0"
        #   timeout_milliseconds   = 12000
        #   route_key = "ANY /example/{proxy+}"
        # }

        # "trigger-01" = {
        #   trigger_type  = "sns"
        #   sns_topic_arn = data.aws_sns_topic.base-alerts.arn
        # }
        # "trigger-03" = {
        #   trigger_type = "eventbridge"
        #   schedule     = "cron(0 0 ? * * 0)"
        # }

        ## First create the resources and then enable the triggers
        # "trigger-05" = {
        #   trigger_type            = "sqs"
        #   source_arn              = aws_sqs_queue.example.arn
        #   function_response_types = ["ReportBatchItemFailures"]
        #   scaling_config = {
        #     maximum_concurrency = 20
        #   }
        # }
        # "trigger-06" = {
        #   trigger_type      = "dynamodb"
        #   source_arn        = aws_dynamodb_table.example.stream_arn
        #   starting_position = "LATEST"
        # }
        # "trigger-02" = {
        #   trigger_type  = "s3_notification"
        #   bucket_name   = "lambda-notification-${local.common_name}"
        #   events        = ["s3:ObjectCreated:Put"]
        #   filter_prefix = "prefix/"
        #   filter_suffix = ".json"
        # }

      }
      ## Enables interaction between lambda and triggers that have EventMappings like SQS and DynamoDB
      # attach_policies    = true
      # number_of_policies = 2
      # policies = [
      #   "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
      #   "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
      # ]

      environment_variables = {}
    }
  }
  lambda_defaults = var.lambda_defaults

}

##### SNS TOPIC DATA #####
# data "aws_sns_topic" "base-alerts" {
#   name = "name-example"
# }

# ##### SQS Trigger testing #####
# resource "aws_sqs_queue" "example" {
#   name                        = "terraform-example-queue.fifo"
#   fifo_queue                  = true
#   content_based_deduplication = true

#   tags = {
#     company     = local.metadata.key.company
#     provisioner = "terraform"
#     environment = local.metadata.environment
#     project     = local.metadata.project
#     created-by  = "GoCloud.la"
#   }

# }

# data "aws_iam_policy_document" "example" {
#   statement {
#     sid    = "First"
#     effect = "Allow"

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     actions   = ["sqs:*"]
#     resources = [aws_sqs_queue.example.arn]

#   }
# }

# resource "aws_sqs_queue_policy" "example" {
#   queue_url = aws_sqs_queue.example.id
#   policy    = data.aws_iam_policy_document.example.json
# }
# ################################

# ##### DynamoDB Stream Testing ####
# resource "aws_dynamodb_table" "example" {
#   billing_mode     = "PAY_PER_REQUEST"
#   name             = "example"
#   hash_key         = "tokenId"
#   table_class      = "STANDARD"
#   stream_enabled   = true
#   stream_view_type = "NEW_IMAGE"
#   attribute {
#     name = "tokenId"
#     type = "N"
#   }

#   tags = {
#     company     = local.metadata.key.company
#     provisioner = "terraform"
#     environment = local.metadata.environment
#     project     = local.metadata.project
#     created-by  = "GoCloud.la"
#   }
# }
# ##############################

# ##### S3 Notification Testing ####
# module "s3_bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "4.1.2"

#   bucket        = "lambda-notification-${local.common_name}"
#   force_destroy = true
# }
# ##############################

# ##### APIGW Testing ####
# module "s3_bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "4.1.2"

#   bucket        = "lambda-notification-${local.common_name}"
#   force_destroy = true
# }
# ##############################

##### APIGWV2 Testing ####
# module "api_gateway" {
#   source  = "terraform-aws-modules/apigateway-v2/aws"
#   version = "4.0.0"

#   name          = "${local.common_name}-http"
#   description   = "My HTTP API Gateway V2"
#   protocol_type = "HTTP"

#   cors_configuration = {
#     allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
#     allow_methods = ["*"]
#     allow_origins = ["*"]
#   }

#   create_api_domain_name = false
#   create_default_stage_access_log_group = true
# }
##############################