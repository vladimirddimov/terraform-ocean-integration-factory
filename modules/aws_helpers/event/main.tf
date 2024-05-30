locals {
  # This is used in order to omit some of the properties that are not needed in the event pattern
  event_pattern_processed = {
    for event_pattern_key, event_pattern_value in var.event_pattern :
    event_pattern_key => event_pattern_value if event_pattern_value != null
  }
}


resource "aws_cloudwatch_event_rule" "port_ocean_live_events_rule" {
  name          = var.name
  description   = var.description
  event_pattern = jsonencode(local.event_pattern_processed)
}

resource "aws_cloudwatch_event_target" "port_ocean_event_bridge_target" {
  rule = aws_cloudwatch_event_rule.port_ocean_live_events_rule.name
  arn  = var.target_arn

  http_target {
    header_parameters = {
      "Content-Type"             = "application/json"
      "x-port-aws-ocean-api-key" = var.api_key_param
    }
  }
  input_transformer {
    input_paths = {
      accountId  = var.input_paths.account_id
      awsRegion  = var.input_paths.aws_region
      eventName  = var.input_paths.event_name
      identifier = var.input_paths.identifier
    }
    input_template = <<EOF
{
  "resource_type": "${var.input_paths.resource_type}",
  "accountId": "<accountId>",
  "awsRegion": "<awsRegion>",
  "eventName": "<eventName>",
  "identifier": "<identifier>"
}
EOF
  }
}
