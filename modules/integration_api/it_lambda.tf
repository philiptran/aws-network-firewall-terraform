resource "aws_iam_role" "it_test_lambda_role" {
  name = "it-test-lambda-role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "it_test_lambda_role_policy" {
  name = "it_test_lambda_role_policy"
  role = aws_iam_role.it_test_lambda_role.id  
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:::log-group:/aws/lambda/*",
        "Effect": "Allow"
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_vpc_access_execution" {
  role = aws_iam_role.it_test_lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
  number  = false
}

# Create a zip file for the lambda function
data "archive_file" "it_test_lambda" {
  type = "zip"
  source_dir = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/it-test-lambda.zip"
}

resource "aws_security_group" "it_test_lambda_sg" {
  name        = "integration-vpc/it_test_lambda_sg"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.super_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "integration-vpc/it_test_lambda_sg"
  }
}

resource "aws_lambda_function" "it_test_lambda" {
  filename = data.archive_file.it_test_lambda.output_path
  function_name = "it_test_lambda-${random_string.random.result}"
  role = aws_iam_role.it_test_lambda_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.9"
  timeout = 300

  vpc_config {
    //subnet_ids = [for s in aws_subnet.integration_vpc_protected_subnet: s.id]
    //security_group_ids = [aws_security_group.integration_vpc_host_sg.id]
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_security_group.it_test_lambda_sg.id]
  }
}
