locals {
  create_target_groups_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_values in try(lambda_config.triggers, {}) :
      {
        "${lambda_name}" = {
          alb_name                           = try(trigger_values.alb_name, null)
          port                               = try(trigger_values.listener_port, null)
          lambda_multi_value_headers_enabled = try(trigger_values.lambda_multi_value_headers_enabled, false)
        }
      } if((length(lookup(lambda_config, "triggers", [])) > 0) && try(lambda_config.create, true) && (trigger_values.trigger_type == "alb" ? true : false))
    ]
  ]
  create_target_groups = merge(flatten(local.create_target_groups_tmp)...)

  create_listener_rules_tmp = [
    for lambda_name, lambda_config in var.lambda_parameters :
    [
      for triggers, trigger_config in try(lambda_config.triggers, {}) :
      [
        for listener_rule, listener_rule_values in try(trigger_config.listener_rules, {}) :
        {
          "${lambda_name}-${listener_rule}" = {
            target_group_key = lambda_name
            priority         = try(listener_rule_values.priority, null)
            conditions       = try(listener_rule_values.conditions, null)

            actions = can(listener_rule_values) && can(listener_rule_values.actions) ? listener_rule_values.actions : [
              {
                type = "forward"
              }
            ]
          }
        } if((length(lookup(listener_rule_values, "conditions", {})) > 0) && try(lambda_config.create, true))
      ]
    ]
  ]
  create_listener_rules = merge(flatten(local.create_listener_rules_tmp)...)
}

resource "aws_lb_target_group" "this" {
  for_each = local.create_target_groups

  name        = substr("${local.common_name}-${each.key}", 0, 32)
  target_type = "lambda"

  lambda_multi_value_headers_enabled = each.value.lambda_multi_value_headers_enabled

  tags = merge(local.common_tags, { workload = each.key }, try(each.value.tags, var.lambda_defaults.tags, null))

}

data "aws_lb" "this" {
  for_each = local.create_target_groups
  name     = try(each.value.alb_name, "${local.common_name}-internal-00")
}

data "aws_lb_listener" "this" {
  for_each          = local.create_target_groups
  load_balancer_arn = data.aws_lb.this["${each.key}"].arn
  port              = try(each.value.port, 443)
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.create_listener_rules

  listener_arn = data.aws_lb_listener.this[each.value.target_group_key].arn
  priority     = try(each.value.priority, null)

  # authenticate-cognito actions
  dynamic "action" {
    for_each = [
      for action_rule in each.value.actions :
      action_rule
      if action_rule.type == "authenticate-cognito"
    ]

    content {
      type = action.value["type"]
      authenticate_cognito {
        authentication_request_extra_params = lookup(action.value, "authentication_request_extra_params", null)
        on_unauthenticated_request          = lookup(action.value, "on_authenticated_request", null)
        scope                               = lookup(action.value, "scope", null)
        session_cookie_name                 = lookup(action.value, "session_cookie_name", null)
        session_timeout                     = lookup(action.value, "session_timeout", null)
        user_pool_arn                       = action.value["user_pool_arn"]
        user_pool_client_id                 = action.value["user_pool_client_id"]
        user_pool_domain                    = action.value["user_pool_domain"]
      }
    }
  }

  # authenticate-oidc actions
  dynamic "action" {
    for_each = [
      for action_rule in each.value.actions :
      action_rule
      if action_rule.type == "authenticate-oidc"
    ]

    content {
      type = action.value["type"]
      authenticate_oidc {
        # Max 10 extra params
        authentication_request_extra_params = lookup(action.value, "authentication_request_extra_params", null)
        authorization_endpoint              = action.value["authorization_endpoint"]
        client_id                           = action.value["client_id"]
        client_secret                       = action.value["client_secret"]
        issuer                              = action.value["issuer"]
        on_unauthenticated_request          = lookup(action.value, "on_unauthenticated_request", null)
        scope                               = lookup(action.value, "scope", null)
        session_cookie_name                 = lookup(action.value, "session_cookie_name", null)
        session_timeout                     = lookup(action.value, "session_timeout", null)
        token_endpoint                      = action.value["token_endpoint"]
        user_info_endpoint                  = action.value["user_info_endpoint"]
      }
    }
  }

  # redirect actions
  dynamic "action" {
    for_each = [
      for action_rule in each.value.actions :
      action_rule
      if action_rule.type == "redirect"
    ]

    content {
      type = action.value["type"]
      redirect {
        host        = lookup(action.value, "host", null)
        path        = lookup(action.value, "path", null)
        port        = lookup(action.value, "port", null)
        protocol    = lookup(action.value, "protocol", null)
        query       = lookup(action.value, "query", null)
        status_code = action.value["status_code"]
      }
    }
  }

  # fixed-response actions
  dynamic "action" {
    for_each = [
      for action_rule in each.value.actions :
      action_rule
      if action_rule.type == "fixed-response"
    ]

    content {
      type = action.value["type"]
      fixed_response {
        message_body = lookup(action.value, "message_body", null)
        status_code  = lookup(action.value, "status_code", null)
        content_type = action.value["content_type"]
      }
    }
  }

  # forward actions
  dynamic "action" {
    for_each = [
      for action_rule in each.value.actions :
      action_rule
      if action_rule.type == "forward"
    ]

    content {
      type             = action.value["type"]
      target_group_arn = aws_lb_target_group.this[each.value.target_group_key].id
    }
  }

  # Host header condition
  dynamic "condition" {
    for_each = [
      for condition_rule in each.value.conditions :
      condition_rule
      if length(lookup(condition_rule, "host_headers", [])) > 0
    ]

    content {
      host_header {
        values = condition.value["host_headers"]
      }
    }
  }

  # Path Pattern condition
  dynamic "condition" {
    for_each = [
      for condition_rule in each.value.conditions :
      condition_rule
      if length(lookup(condition_rule, "path_patterns", [])) > 0
    ]

    content {
      path_pattern {
        values = condition.value["path_patterns"]
      }
    }
  }

  # Http header condition
  dynamic "condition" {
    for_each = [
      for condition_rule in each.value.conditions :
      condition_rule
      if length(lookup(condition_rule, "http_headers", [])) > 0
    ]

    content {
      dynamic "http_header" {
        for_each = condition.value["http_headers"]

        content {
          http_header_name = http_header.value["http_header_name"]
          values           = http_header.value["values"]
        }
      }
    }
  }

  # Http request method condition
  dynamic "condition" {
    for_each = [
      for condition_rule in each.value.conditions :
      condition_rule
      if length(lookup(condition_rule, "http_request_methods", [])) > 0
    ]

    content {
      http_request_method {
        values = condition.value["http_request_methods"]
      }
    }
  }

  # Query string condition
  dynamic "condition" {
    for_each = [
      for condition_rule in each.value.conditions :
      condition_rule
      if length(lookup(condition_rule, "query_strings", [])) > 0
    ]

    content {
      dynamic "query_string" {
        for_each = condition.value["query_strings"]

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value["value"]
        }
      }
    }
  }

  # Source IP address condition
  dynamic "condition" {
    for_each = [
      for condition_rule in each.value.conditions :
      condition_rule
      if length(lookup(condition_rule, "source_ips", [])) > 0
    ]

    content {
      source_ip {
        values = condition.value["source_ips"]
      }
    }
  }

  tags = merge(local.common_tags, { workload = each.key.target_group_key }, try(each.value.tags, var.lambda_defaults.tags, null))
}

resource "aws_lb_target_group_attachment" "this" {
  for_each         = local.create_target_groups
  target_group_arn = aws_lb_target_group.this["${each.key}"].arn
  target_id        = module.lambda["${each.key}"].lambda_function_arn

}