output "docs_api_arn" {
  value = "${aws_api_gateway_stage.production.execution_arn}/${aws_api_gateway_method.get_docs.http_method}/${aws_api_gateway_resource.docs.path_part}"
}

output "integration_webhook_api_arn" {
  value = "${aws_api_gateway_stage.production.execution_arn}/${aws_api_gateway_method.post_webhook.http_method}/${aws_api_gateway_resource.integration.path_part}/${aws_api_gateway_resource.webhook.path_part}"
}