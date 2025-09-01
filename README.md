# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Lambda Function Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-lambda/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-lambda.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-lambda.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-lambda/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
The Terraform Wrapper for the Lambda functions service simplifies the execution of code in the AWS cloud. It works as a predefined template, facilitating the creation and management of Lambda functions by handling all the technical details.

### ✨ Features

- 🚀 [Initial deployment](#initial-deployment) - Deploys a Lambda function from a README.MD zip file

- 🔄 [Simplification of triggers - Load Balancer](#simplification-of-triggers---load-balancer) - Deploys a Lambda function triggered by an Application Load Balancer

- 🔧 [Simplification of triggers - EventBridge](#simplification-of-triggers---eventbridge) - Deploys Lambda with EventBridge trigger, creating rule and target

- 🔔 [Simplification of triggers - SNS](#simplification-of-triggers---sns) - Deploys a Lambda function triggered by an existing SNS topic

- 🔧 [Simplification of triggers - S3](#simplification-of-triggers---s3) - Deploys an S3-triggered Lambda function with configurable event types

- 🔍 [Simplification of triggers - HTTP APIGateway](#simplification-of-triggers---http-apigateway) - Deploys a Lambda function with an HTTP API Gateway trigger

- 🔧 [Simplification of triggers - SQS and DynamoDB](#simplification-of-triggers---sqs-and-dynamodb) - Deploys Lambda with DynamoDB or SQS triggers and event mappings



### 🔗 External Modules
| Name | Version |
|------|------:|
| [terraform-aws-modules/lambda/aws](https://github.com/terraform-aws-modules/lambda-aws) | 8.0.1 |



## 🚀 Quick Start
```hcl
lambda_parameters = {
  "ExBalancer" = {
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
}
```


## 🔧 Additional Features Usage

### Initial deployment
Deploy a lambda function with a zip file that includes a single README.MD. This avoids having to version the source code of the function in Terraform.<br/>
To activate this feature, the following variables must be configured


<details><summary>Configuration Code</summary>

```hcl
create_package          = false
  ignore_source_code_hash = true
```


</details>


### Simplification of triggers - Load Balancer
Deploy a lambda function that has an Application Load Balancer as a trigger. This functionality will automatically create the Target Group and the resources and link them as a trigger for the lambda function.


<details><summary>Configuration Code</summary>

```hcl
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
```


</details>


### Simplification of triggers - EventBridge
Deploy a lambda function that has an EventBridge as a trigger. This functionality will automatically create the Cloudwatch rule and the target of the same; and link them as a trigger for the lambda function.<br/>
A cron job or an event pattern logic can be used as a rule.


<details><summary>Configuration Code</summary>

```hcl
triggers = {
  "trigger-01" = {
    trigger_type = "eventbridge"
    schedule     = "cron(0 0 ? * * 0)"
  }
}
```


</details>


### Simplification of triggers - SNS
Deploy a lambda function that has an SNS as a trigger. This functionality will automatically create the subscription of the lambda function to the SNS topic to use it as a trigger.<br/>
:::warning caution
It is required that the SNS topic is deployed beforehand.<br/>
:::


<details><summary>Configuration Code</summary>

```hcl
triggers = {
  "trigger-01" = {
    trigger_type  = "sns"
    sns_topic_arn = data.aws_sns_topic.base-alerts.arn
  }
}
```


</details>


### Simplification of triggers - S3
Deploy a lambda function that is triggered by an S3 bucket event. This functionality will create an S3 notification resource, which will allow defining the type of event, directory, and object type that will invoke the lambda function.<br/>
:::warning caution
It is required that the S3 bucket is deployed beforehand.<br/>
:::


<details><summary>Configuration Code</summary>

```hcl
triggers = {
  "trigger-02" = {
    trigger_type  = "s3_notification"
    bucket_name   = "lambda-notification-${local.common_name}"
    events        = ["s3:ObjectCreated:Put"]
    filter_prefix = "prefix/"
    filter_suffix = ".json"
  }
}
```


</details>


### Simplification of triggers - HTTP APIGateway
Deploy a lambda function that has an HTTP APIGateway endpoint as a trigger. This functionality will automatically create the necessary resources to register a path/route in APIGateway and link it through an integration with the Lambda function.<br/>
:::warning caution
It is required that the APIGateway on which the endpoint will be created is deployed beforehand.<br/>
:::


<details><summary>Configuration Code</summary>

```hcl
triggers = {
  "trigger-apiv2-get" = {
    trigger_type  = "apigateway"
    api_id = module.api_gateway.apigatewayv2_api_id
    integration_type = "AWS_PROXY"
    connection_type           = "INTERNET"
    #content_handling_strategy = "CONVERT_TO_TEXT"
    description               = "Lambda example"
    integration_method        = "ANY"
    #integration_uri           = aws_lambda_function.example.invoke_arn
    #passthrough_behavior      = "WHEN_NO_MATCH"
    payload_format_version = "2.0"
    timeout_milliseconds   = 12000
    route_key = "ANY /example/{proxy+}"
  }
}
```


</details>


### Simplification of triggers - SQS and DynamoDB
Deploy a lambda function that has DynamoDB or SQS as Trigger and Event Mappings. This functionality allows you to avoid having to separately declare the logic of the triggers and event mappings with which we will link the lambda function to these services.<br/>
:::warning caution
It is required that the SQS queue or the DynamoDB table stream be deployed beforehand.<br/>
:::


<details><summary>Configuration Code</summary>

```hcl
triggers = {
  "trigger-05" = {
    trigger_type            = "sqs"
    source_arn              = aws_sqs_queue.example.arn
    function_response_types = ["ReportBatchItemFailures"]
    scaling_config = {
      maximum_concurrency = 20
    }
  }
  "trigger-06" = {
    trigger_type      = "dynamodb"
    source_arn        = aws_dynamodb_table.example.stream_arn
    starting_position = "LATEST"
  }
}
```


</details>










## ⚠️ Important Notes
- **⚠️ SNS Topic Required:** The SNS topic must be deployed beforehand - set `topic_arn = "arn:aws:sns:us-east-1:123456789:my-topic"`
- **⚠️ Prerequisite S3 Bucket:** The S3 bucket must be deployed beforehand - set `bucket = "my-bucket-name"`
- **⚠️ Existing API Gateway Required:** The API Gateway must be deployed before creating the endpoint - set `depends_on = [aws_api_gateway_rest_api.example]`
- **⚠️ No API Gateway Rest Support:** The Terraform configuration does not currently support the API Gateway Rest parameter - set `api_gateway_rest_enabled = 
- **⚠️ Prerequisite Resources:** The SQS queue or DynamoDB table stream must be deployed prior to using this resource - set `depends_on = [aws_sqs_queue,



---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la
- 🐛 **Issues**: [GitHub Issues](https://github.com/gocloudLa/issues)

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 