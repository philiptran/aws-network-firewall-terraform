resource "aws_api_gateway_rest_api" "it_test_api" {
  name = "it_test_api"
  endpoint_configuration {
    types = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway_endpoint.id]
  }
}

resource "aws_api_gateway_resource" "it_test_api" {
  parent_id = aws_api_gateway_rest_api.it_test_api.root_resource_id
  path_part = "ext1"
  rest_api_id = aws_api_gateway_rest_api.it_test_api.id
}

resource "aws_api_gateway_method" "it_test_api_method" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = aws_api_gateway_resource.it_test_api.id
  rest_api_id = aws_api_gateway_rest_api.it_test_api.id
}

resource "aws_api_gateway_integration" "it_test_lambda_integration" {
  http_method = aws_api_gateway_method.it_test_api_method.http_method
  resource_id = aws_api_gateway_resource.it_test_api.id
  rest_api_id = aws_api_gateway_rest_api.it_test_api.id
  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.it_test_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.it_test_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.it_test_api.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api_policy" "it_test_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.it_test_api.id
  policy      = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.it_test_api.execution_arn}/*"
        },
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.it_test_api.execution_arn}/*",
            "Condition": {
                "StringNotEquals": {
                    "aws:SourceVpce": "${aws_vpc_endpoint.api_gateway_endpoint.id}"
                }
            }
        }
    ]
}
EOF
}

resource "aws_api_gateway_deployment" "default_deployment" {
  rest_api_id = aws_api_gateway_rest_api.it_test_api.id
  triggers = {
    redeloyment = sha1(jsonencode([
      aws_api_gateway_resource.it_test_api.id,
      aws_api_gateway_method.it_test_api_method.id,
      aws_api_gateway_integration.it_test_lambda_integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_deployment" {
  deployment_id = aws_api_gateway_deployment.default_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.it_test_api.id
  stage_name    = "default"
}
