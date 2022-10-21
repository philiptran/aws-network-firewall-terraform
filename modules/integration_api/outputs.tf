output "api_gw_endpoint" {
  value = aws_vpc_endpoint.api_gateway_endpoint.id
}

output "it_test_api_endpoint" {
  value = aws_api_gateway_stage.default_deployment.invoke_url
}

output "it_test_api_endpoint_R53alias" {
  value = "https://${aws_api_gateway_stage.default_deployment.rest_api_id}-${aws_vpc_endpoint.api_gateway_endpoint.id}.execute-api.ap-southeast-1.amazonaws.com/default/ext1?url=https://www.amazon.com"
}
