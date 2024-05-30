resource "aws_api_gateway_rest_api" "rest_api" {
  name        = var.rest_api_name
  description = "API Gateway for Port Ocean AWS Exporter"
}

resource "aws_api_gateway_stage" "production" {
  stage_name    = "production"
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.port_ocean_exporter_gateway_deployment.id
}

resource "aws_api_gateway_resource" "docs" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "docs"
}

resource "aws_api_gateway_method" "get_docs" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.docs.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.x-port-aws-ocean-api-key" = true
  }
}

resource "aws_api_gateway_integration" "get_docs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.docs.id
  http_method             = aws_api_gateway_method.get_docs.http_method
  type                    = "HTTP_PROXY"
  uri                     = "${var.webhook_url}/docs"
  passthrough_behavior    = "WHEN_NO_MATCH"
  integration_http_method = "GET"

  request_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_method_response" "get_docs_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.docs.id
  http_method = aws_api_gateway_method.get_docs.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_resource" "integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "integration"
}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.integration.id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "post_webhook" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.x-port-aws-ocean-api-key" = true
  }
}

resource "aws_api_gateway_integration" "post_webhook_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.post_webhook.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "${var.webhook_url}/integration/webhook"
  passthrough_behavior    = "WHEN_NO_MATCH"

  request_parameters = {
    "integration.request.header.x-port-aws-ocean-api-key" = "method.request.header.x-port-aws-ocean-api-key"
  }

  request_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_method_response" "post_webhook_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_webhook.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "port_ocean_exporter_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode([
      var.webhook_url,
      aws_api_gateway_resource.docs.id,
      aws_api_gateway_resource.webhook.id,
      aws_api_gateway_method.get_docs.id,
      aws_api_gateway_method.post_webhook.id,
      aws_api_gateway_integration.get_docs_integration.id,
      aws_api_gateway_integration.post_webhook_integration.id,
    ]))
  }
}
