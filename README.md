# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Lambda Function Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-lambda/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-lambda.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-lambda.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-lambda/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
The Terraform Wrapper for the Lambda functions service simplifies the execution of code in the AWS cloud. It works as a predefined template, facilitating the creation and management of Lambda functions by handling all the technical details.

### ✨ Features

- 🚀 [Zip deployment](#zip-deployment) - Deploys a Lambda function from a zip file

- 🔄 [Simplification of triggers - Load Balancer](#simplification-of-triggers---load-balancer) - Deploys a Lambda function triggered by an Application Load Balancer

- 🔧 [Simplification of triggers - EventBridge](#simplification-of-triggers---eventbridge) - Deploys Lambda with EventBridge trigger, creating rule and target

- 🔔 [Simplification of triggers - SNS](#simplification-of-triggers---sns) - Deploys a Lambda function triggered by an existing SNS topic

- 🔧 [Simplification of triggers - S3](#simplification-of-triggers---s3) - Deploys an S3-triggered Lambda function with configurable event types

- 🔍 [Simplification of triggers - HTTP APIGateway](#simplification-of-triggers---http-apigateway) - Deploys a Lambda function with an HTTP API Gateway trigger

- 🔧 [Simplification of triggers - SQS and DynamoDB](#simplification-of-triggers---sqs-and-dynamodb) - Deploys Lambda with DynamoDB or SQS triggers and event mappings



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-lambda" target="_blank">terraform-aws-modules/lambda/aws</a> | 8.0.1 |



## 🚀 Quick Start
```hcl
lambda_parameters = {
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
}
```


## 🔧 Additional Features Usage

### Zip deployment
Deploy a lambda function with a zip file. This avoids having to version the source code of the function in Terraform.<br/>
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
> **⚠️ Warning:** It is required that the SNS topic is deployed beforehand.


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
> **⚠️ Warning:** It is required that the S3 bucket is deployed beforehand.


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
> **⚠️ Warning:** It is required that the APIGateway on which the endpoint will be created is deployed beforehand.


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
> **⚠️ Warning:** It is required that the SQS queue or the DynamoDB table stream be deployed beforehand.


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




## 📑 Inputs
| Name                                         | Description                                                                                                                                                                                                                                                                    | Type     | Default                  | Required |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ------------------------ | -------- |
| allowed_triggers                             | Map of allowed triggers to create Lambda permissions                                                                                                                                                                                                                           | `map`    | `{}`                     | no       |
| architectures                                | Instruction set architecture for your Lambda function. Valid values are ["x86_64"] and ["arm64"].                                                                                                                                                                              | `list`   | `null`                   | no       |
| artifacts_dir                                | Directory name where artifacts should be stored                                                                                                                                                                                                                                | `string` | `"builds"`               | no       |
| assume_role_policy_statements                | Map of dynamic policy statements for assuming Lambda Function role (trust relationship)                                                                                                                                                                                        | `any`    | `{}`                     | no       |
| attach_async_event_policy                    | Controls whether async event policy should be added to IAM role for Lambda Function                                                                                                                                                                                            | `bool`   | `false`                  | no       |
| attach_cloudwatch_logs_policy                | Controls whether CloudWatch Logs policy should be added to IAM role for Lambda Function                                                                                                                                                                                        | `bool`   | `true`                   | no       |
| attach_create_log_group_permission           | Controls whether to add the create log group permission to the CloudWatch logs policy                                                                                                                                                                                          | `bool`   | `true`                   | no       |
| attach_dead_letter_policy                    | Controls whether SNS/SQS dead letter notification policy should be added to IAM role for Lambda Function                                                                                                                                                                       | `bool`   | `false`                  | no       |
| attach_network_policy                        | Controls whether VPC/network policy should be added to IAM role for Lambda Function                                                                                                                                                                                            | `bool`   | `false`                  | no       |
| attach_policies                              | Controls whether list of policies should be added to IAM role for Lambda Function                                                                                                                                                                                              | `bool`   | `false`                  | no       |
| attach_policy                                | Controls whether policy should be added to IAM role for Lambda Function                                                                                                                                                                                                        | `bool`   | `false`                  | no       |
| attach_policy_json                           | Controls whether policy_json should be added to IAM role for Lambda Function                                                                                                                                                                                                   | `bool`   | `false`                  | no       |
| attach_policy_jsons                          | Controls whether policy_jsons should be added to IAM role for Lambda Function                                                                                                                                                                                                  | `bool`   | `false`                  | no       |
| attach_policy_statements                     | Controls whether policy_statements should be added to IAM role for Lambda Function                                                                                                                                                                                             | `bool`   | `false`                  | no       |
| attach_tracing_policy                        | Controls whether X-Ray tracing policy should be added to IAM role for Lambda Function                                                                                                                                                                                          | `bool`   | `false`                  | no       |
| authorization_type                           | The type of authentication that the Lambda Function URL uses. Set to 'AWS_IAM' to restrict access to authenticated IAM users only. Set to 'NONE' to bypass IAM authentication and create a public endpoint.                                                                    | `string` | `"NONE"`                 | no       |
| build_in_docker                              | Whether to build dependencies in Docker                                                                                                                                                                                                                                        | `bool`   | `false`                  | no       |
| cloudwatch_logs_kms_key_id                   | The ARN of the KMS Key to use when encrypting log data.                                                                                                                                                                                                                        | `string` | `null`                   | no       |
| cloudwatch_logs_log_group_class              | Specifies the log class of the log group. Possible values are: `STANDARD` or `INFREQUENT_ACCESS`.                                                                                                                                                                              | `string` | `null`                   | no       |
| cloudwatch_logs_retention_in_days            | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.                                                                                     | `number` | `null`                   | no       |
| cloudwatch_logs_skip_destroy                 | Whether to keep the log group (and any logs it may contain) at destroy time.                                                                                                                                                                                                   | `bool`   | `false`                  | no       |
| cloudwatch_logs_tags                         | A map of tags to assign to the resource.                                                                                                                                                                                                                                       | `map`    | `{}`                     | no       |
| code_signing_config_arn                      | Amazon Resource Name (ARN) for a Code Signing Configuration                                                                                                                                                                                                                    | `string` | `null`                   | no       |
| compatible_architectures                     | A list of Architectures Lambda layer is compatible with. Currently x86_64 and arm64 can be specified.                                                                                                                                                                          | `list`   | `null`                   | no       |
| compatible_runtimes                          | A list of Runtimes this layer is compatible with. Up to 5 runtimes can be specified.                                                                                                                                                                                           | `list`   | `[]`                     | no       |
| cors                                         | CORS settings to be used by the Lambda Function URL                                                                                                                                                                                                                            | `any`    | `{}`                     | no       |
| create                                       | Controls whether resources should be created                                                                                                                                                                                                                                   | `bool`   | `true`                   | no       |
| create_async_event_config                    | Controls whether async event configuration for Lambda Function/Alias should be created                                                                                                                                                                                         | `bool`   | `false`                  | no       |
| create_current_version_allowed_triggers      | Whether to allow triggers on current version of Lambda Function (this will revoke permissions from previous version because Terraform manages only current resources)                                                                                                          | `bool`   | `true`                   | no       |
| create_current_version_async_event_config    | Whether to allow async event configuration on current version of Lambda Function (this will revoke permissions from previous version because Terraform manages only current resources)                                                                                         | `bool`   | `true`                   | no       |
| create_function                              | Controls whether Lambda Function resource should be created                                                                                                                                                                                                                    | `bool`   | `true`                   | no       |
| create_lambda_function_url                   | Controls whether the Lambda Function URL resource should be created                                                                                                                                                                                                            | `bool`   | `false`                  | no       |
| create_layer                                 | Controls whether Lambda Layer resource should be created                                                                                                                                                                                                                       | `bool`   | `false`                  | no       |
| create_package                               | Controls whether Lambda package should be created                                                                                                                                                                                                                              | `bool`   | `true`                   | no       |
| create_role                                  | Controls whether IAM role for Lambda Function should be created                                                                                                                                                                                                                | `bool`   | `true`                   | no       |
| create_sam_metadata                          | Controls whether the SAM metadata null resource should be created                                                                                                                                                                                                              | `bool`   | `false`                  | no       |
| create_unqualified_alias_allowed_triggers    | Whether to allow triggers on unqualified alias pointing to $LATEST version                                                                                                                                                                                                     | `bool`   | `true`                   | no       |
| create_unqualified_alias_async_event_config  | Whether to allow async event configuration on unqualified alias pointing to $LATEST version                                                                                                                                                                                    | `bool`   | `true`                   | no       |
| create_unqualified_alias_lambda_function_url | Whether to use unqualified alias pointing to $LATEST version in Lambda Function URL                                                                                                                                                                                            | `bool`   | `true`                   | no       |
| dead_letter_target_arn                       | The ARN of an SNS topic or SQS queue to notify when an invocation fails.                                                                                                                                                                                                       | `string` | `null`                   | no       |
| description                                  | Description of your Lambda Function (or Layer)                                                                                                                                                                                                                                 | `string` | `""`                     | no       |
| destination_on_failure                       | Amazon Resource Name (ARN) of the destination resource for failed asynchronous invocations                                                                                                                                                                                     | `string` | `null`                   | no       |
| destination_on_success                       | Amazon Resource Name (ARN) of the destination resource for successful asynchronous invocations                                                                                                                                                                                 | `string` | `null`                   | no       |
| docker_additional_options                    | Additional options to pass to the docker run command (e.g. to set environment variables, volumes, etc.)                                                                                                                                                                        | `list`   | `[]`                     | no       |
| docker_build_root                            | Root dir where to build in Docker                                                                                                                                                                                                                                              | `string` | `""`                     | no       |
| docker_entrypoint                            | Path to the Docker entrypoint to use                                                                                                                                                                                                                                           | `string` | `null`                   | no       |
| docker_file                                  | Path to a Dockerfile when building in Docker                                                                                                                                                                                                                                   | `string` | `""`                     | no       |
| docker_image                                 | Docker image to use for the build                                                                                                                                                                                                                                              | `string` | `""`                     | no       |
| docker_pip_cache                             | Whether to mount a shared pip cache folder into docker environment or not                                                                                                                                                                                                      | `any`    | `null`                   | no       |
| docker_with_ssh_agent                        | Whether to pass SSH_AUTH_SOCK into docker environment or not                                                                                                                                                                                                                   | `bool`   | `false`                  | no       |
| environment_variables                        | A map that defines environment variables for the Lambda Function.                                                                                                                                                                                                              | `map`    | `{}`                     | no       |
| ephemeral_storage_size                       | Amount of ephemeral storage (/tmp) in MB your Lambda Function can use at runtime. Valid value between 512 MB to 10,240 MB (10 GB).                                                                                                                                             | `number` | `512`                    | no       |
| event_source_mapping                         | Map of event source mapping.                                                                                                                                                                                                                                                   | `any`    | `{}`                     | no       |
| file_system_arn                              | The Amazon Resource Name (ARN) of the Amazon EFS Access Point that provides access to the file system.                                                                                                                                                                         | `string` | `null`                   | no       |
| file_system_local_mount_path                 | The path where the function can access the file system, starting with /mnt/.                                                                                                                                                                                                   | `string` | `null`                   | no       |
| function_name                                | A unique name for your Lambda Function.                                                                                                                                                                                                                                        | `string` | `""`                     | no       |
| function_tags                                | A map of tags to assign only to the lambda function.                                                                                                                                                                                                                           | `map`    | `{}`                     | no       |
| handler                                      | Lambda Function entrypoint in your code.                                                                                                                                                                                                                                       | `string` | `"index.lambda_handler"` | no       |
| hash_extra                                   | The string to add into hashing function. Useful when building same source path for different functions.                                                                                                                                                                        | `string` | `""`                     | no       |
| ignore_source_code_hash                      | Whether to ignore changes to the function's source code hash. Set to true if you manage infrastructure and code deployments separately.                                                                                                                                        | `bool`   | `false`                  | no       |
| image_config_command                         | The CMD for the docker image.                                                                                                                                                                                                                                                  | `list`   | `[]`                     | no       |
| image_config_entry_point                     | The ENTRYPOINT for the docker image.                                                                                                                                                                                                                                           | `list`   | `[]`                     | no       |
| image_config_working_directory               | The working directory for the docker image.                                                                                                                                                                                                                                    | `string` | `null`                   | no       |
| image_uri                                    | The ECR image URI containing the function's deployment package.                                                                                                                                                                                                                | `string` | `null`                   | no       |
| include_default_tag                          | Set to false to not include the default tag in the tags map.                                                                                                                                                                                                                   | `string` | `null`                   | no       |
| invoke_mode                                  | Invoke mode of the Lambda Function URL. Valid values are BUFFERED (default) and RESPONSE_STREAM.                                                                                                                                                                               | `bool`   | `true`                   | no       |
| ipv6_allowed_for_dual_stack                  | Allows outbound IPv6 traffic on VPC functions that are connected to dual-stack subnets.                                                                                                                                                                                        | `bool`   | `null`                   | no       |
| kms_key_arn                                  | The ARN of KMS key to use by your Lambda Function.                                                                                                                                                                                                                             | `string` | `null`                   | no       |
| lambda_at_edge                               | Set this to true if using Lambda@Edge, to enable publishing, limit the timeout, and allow edgelambda.amazonaws.com to invoke the function.                                                                                                                                     | `bool`   | `false`                  | no       |
| lambda_at_edge_logs_all_regions              | Whether to specify a wildcard in IAM policy used by Lambda@Edge to allow logging in all regions.                                                                                                                                                                               | `bool`   | `true`                   | no       |
| lambda_role                                  | IAM role ARN attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources your Lambda Function has access to. See Lambda Permission Model for more details.                                                        | `string` | `""`                     | no       |
| layer_name                                   | Name of Lambda Layer to create.                                                                                                                                                                                                                                                | `string` | `""`                     | no       |
| layer_skip_destroy                           | Whether to retain the old version of a previously deployed Lambda Layer.                                                                                                                                                                                                       | `bool`   | `false`                  | no       |
| layers                                       | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function.                                                                                                                                                                                            | `list`   | `null`                   | no       |
| license_info                                 | License info for your Lambda Layer. Eg, MIT or full url of a license.                                                                                                                                                                                                          | `string` | `""`                     | no       |
| local_existing_package                       | The absolute path to an existing zip-file to use.                                                                                                                                                                                                                              | `string` | `null`                   | no       |
| logging_application_log_level                | The application log level of the Lambda Function. Valid values are "TRACE", "DEBUG", "INFO", "WARN", "ERROR", or "FATAL".                                                                                                                                                      | `string` | `"INFO"`                 | no       |
| logging_log_format                           | The log format of the Lambda Function. Valid values are "JSON" or "Text".                                                                                                                                                                                                      | `string` | `"Text"`                 | no       |
| logging_log_group                            | The CloudWatch log group to send logs to.                                                                                                                                                                                                                                      | `string` | `null`                   | no       |
| logging_system_log_level                     | The system log level of the Lambda Function. Valid values are "DEBUG", "INFO", or "WARN".                                                                                                                                                                                      | `string` | `"INFO"`                 | no       |
| maximum_event_age_in_seconds                 | Maximum age of a request that Lambda sends to a function for processing in seconds. Valid values between 60 and 21600.                                                                                                                                                         | `number` | `null`                   | no       |
| maximum_retry_attempts                       | Maximum number of times to retry when the function returns an error. Valid values between 0 and 2. Defaults to 2.                                                                                                                                                              | `number` | `null`                   | no       |
| memory_size                                  | Amount of memory in MB your Lambda Function can use at runtime. Valid value between 128 MB to 10,240 MB (10 GB), in 64 MB increments.                                                                                                                                          | `number` | `128`                    | no       |
| number_of_policies                           | Number of policies to attach to IAM role for Lambda Function.                                                                                                                                                                                                                  | `number` | `0`                      | no       |
| number_of_policy_jsons                       | Number of policies JSON to attach to IAM role for Lambda Function.                                                                                                                                                                                                             | `number` | `0`                      | no       |
| package_type                                 | The Lambda deployment package type. Valid options: Zip or Image.                                                                                                                                                                                                               | `string` | `"Zip"`                  | no       |
| policies                                     | List of policy statements ARN to attach to Lambda Function role.                                                                                                                                                                                                               | `list`   | `[]`                     | no       |
| policy                                       | An additional policy document ARN to attach to the Lambda Function role.                                                                                                                                                                                                       | `string` | `null`                   | no       |
| policy_json                                  | An additional policy document as JSON to attach to the Lambda Function role.                                                                                                                                                                                                   | `string` | `null`                   | no       |
| policy_jsons                                 | List of additional policy documents as JSON to attach to Lambda Function role.                                                                                                                                                                                                 | `list`   | `[]`                     | no       |
| policy_name                                  | IAM policy name. It overrides the default value, which is the same as role_name.                                                                                                                                                                                               | `string` | `null`                   | no       |
| policy_statements                            | Map of dynamic policy statements to attach to Lambda Function role.                                                                                                                                                                                                            | `any`    | `{}`                     | no       |
| provisioned_concurrent_executions            | Amount of capacity to allocate. Set to 1 or greater to enable, or set to 0 to disable provisioned concurrency.                                                                                                                                                                 | `number` | `-1`                     | no       |
| publish                                      | Whether to publish creation/change as new Lambda Function Version.                                                                                                                                                                                                             | `bool`   | `false`                  | no       |
| putin_khuylo                                 | Configuration flag for archive processing behavior. Controls whether to enable verbose logging during archive operations.                                                                                                                                                      | `bool`   | `true`                   | no       |
| quiet_archive_local_exec                     | Whether to disable archive local execution output.                                                                                                                                                                                                                             | `bool`   | `true`                   | no       |
| recreate_missing_package                     | Whether to recreate missing Lambda package if it is missing locally or not.                                                                                                                                                                                                    | `bool`   | `true`                   | no       |
| recursive_loop                               | Lambda function recursion configuration. Valid values are Allow or Terminate.                                                                                                                                                                                                  | `string` | `null`                   | no       |
| region                                       | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration.                                                                                                                                                                        | `string` | `null`                   | no       |
| replace_security_groups_on_destroy           | (Optional) When true, all security groups defined in vpc_security_group_ids will be replaced with the default security group after the function is destroyed. Set the replacement_security_group_ids variable to use a custom list of security groups for replacement instead. | `bool`   | `null`                   | no       |
| replacement_security_group_ids               | (Optional) List of security group IDs to assign to orphaned Lambda function network interfaces upon destruction. replace_security_groups_on_destroy must be set to true to use this attribute.                                                                                 | `list`   | `null`                   | no       |
| reserved_concurrent_executions               | The amount of reserved concurrent executions for this Lambda Function. A value of 0 disables Lambda Function from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1.                                                    | `number` | `-1`                     | no       |
| role_description                             | Description of IAM role to use for Lambda Function                                                                                                                                                                                                                             | `string` | `null`                   | no       |
| role_force_detach_policies                   | Specifies to force detaching any policies the IAM role has before destroying it.                                                                                                                                                                                               | `bool`   | `true`                   | no       |
| role_maximum_session_duration                | Maximum session duration, in seconds, for the IAM role                                                                                                                                                                                                                         | `number` | `3600`                   | no       |
| role_name                                    | Name of IAM role to use for Lambda Function                                                                                                                                                                                                                                    | `string` | `null`                   | no       |
| role_path                                    | Path of IAM role to use for Lambda Function                                                                                                                                                                                                                                    | `string` | `null`                   | no       |
| role_permissions_boundary                    | The ARN of the policy that is used to set the permissions boundary for the IAM role used by Lambda Function                                                                                                                                                                    | `string` | `null`                   | no       |
| role_tags                                    | A map of tags to assign to IAM role                                                                                                                                                                                                                                            | `map`    | `{}`                     | no       |
| runtime                                      | Lambda Function runtime                                                                                                                                                                                                                                                        | `string` | `"python3.9"`            | no       |
| s3_acl                                       | The canned ACL to apply. Valid values are private, public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, and bucket-owner-full-control. Defaults to private.                                                                                   | `string` | `"private"`              | no       |
| s3_bucket                                    | S3 bucket to store artifacts                                                                                                                                                                                                                                                   | `string` | `null`                   | no       |
| s3_existing_package                          | The S3 bucket object with keys bucket, key, version pointing to an existing zip-file to use                                                                                                                                                                                    | `map`    | `null`                   | no       |
| s3_kms_key_id                                | Specifies a custom KMS key to use for S3 object encryption.                                                                                                                                                                                                                    | `string` | `null`                   | no       |
| s3_object_override_default_tags              | Whether to override the default_tags from provider? NB: S3 objects support a maximum of 10 tags.                                                                                                                                                                               | `bool`   | `false`                  | no       |
| s3_object_storage_class                      | Specifies the desired Storage Class for the artifact uploaded to S3. Can be either STANDARD, REDUCED_REDUNDANCY, ONEZONE_IA, INTELLIGENT_TIERING, or STANDARD_IA.                                                                                                              | `string` | `"ONEZONE_IA"`           | no       |
| s3_object_tags                               | A map of tags to assign to S3 bucket object.                                                                                                                                                                                                                                   | `map`    | `{}`                     | no       |
| s3_object_tags_only                          | Set to true to not merge tags with s3_object_tags. Useful to avoid breaching S3 Object 10 tag limit.                                                                                                                                                                           | `bool`   | `false`                  | no       |
| s3_prefix                                    | Directory name where artifacts should be stored in the S3 bucket. If unset, the path from artifacts_dir is used                                                                                                                                                                | `string` | `null`                   | no       |
| s3_server_side_encryption                    | Specifies server-side encryption of the object in S3. Valid values are "AES256" and "aws:kms".                                                                                                                                                                                 | `string` | `null`                   | no       |
| skip_destroy                                 | Set to true if you do not wish the function to be deleted at destroy time, and instead just remove the function from the Terraform state. Useful for Lambda@Edge functions attached to CloudFront distributions.                                                               | `bool`   | `null`                   | no       |
| snap_start                                   | (Optional) Snap start settings for low-latency startups                                                                                                                                                                                                                        | `bool`   | `false`                  | no       |
| source_path                                  | The absolute path to a local file or directory containing your Lambda source code                                                                                                                                                                                              | `any`    | `null`                   | no       |
| store_on_s3                                  | Whether to store produced artifacts on S3 or locally.                                                                                                                                                                                                                          | `bool`   | `false`                  | no       |
| timeout                                      | The amount of time your Lambda Function has to run in seconds.                                                                                                                                                                                                                 | `number` | `3`                      | no       |
| timeouts                                     | Define maximum timeout for creating, updating, and deleting Lambda Function resources                                                                                                                                                                                          | `map`    | `{}`                     | no       |
| tracing_mode                                 | Tracing mode of the Lambda Function. Valid value can be either PassThrough or Active.                                                                                                                                                                                          | `string` | `null`                   | no       |
| trigger_on_package_timestamp                 | Whether to recreate the Lambda package if the timestamp changes                                                                                                                                                                                                                | `bool`   | `true`                   | no       |
| trusted_entities                             | List of additional trusted entities for assuming Lambda Function role (trust relationship)                                                                                                                                                                                     | `any`    | `[]`                     | no       |
| use_existing_cloudwatch_log_group            | Whether to use an existing CloudWatch log group or create new                                                                                                                                                                                                                  | `bool`   | `false`                  | no       |
| vpc_security_group_ids                       | List of security group ids when Lambda Function should run in the VPC.                                                                                                                                                                                                         | `list`   | `null`                   | no       |
| vpc_subnet_ids                               | List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets.                                                                                                                                                                               | `list`   | `null`                   | no       |
| tags                                         | A map of tags to assign to resources.                                                                                                                                                                                                                                          | `map`    | `{}`                     | no       |








---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 