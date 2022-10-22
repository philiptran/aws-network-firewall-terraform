data "aws_availability_zones" "available" {
  state = "available"
  exclude_names = ["ap-southeast-1c"]
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}