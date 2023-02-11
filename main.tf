terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}

# Create a test bucket with a globally unique name
resource "aws_s3_bucket" "demo" {
  bucket = "my-tf-test-bucket-${random_string.name.result}"
}

resource "random_string" "name" {
  length  = 12
  special = false
  upper   = false
  numeric = false
}

# This role must be assumed for data access. The actual lambda role has no access to S3.
resource "aws_iam_role" "data_access_role" {
  name               = "data_access_role"
  assume_role_policy = data.aws_iam_policy_document.access_role_trust.json
}

data "aws_iam_policy_document" "access_role_trust" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"
      # Trust the app role.
      # Also trust _this_ AWS account which is helpful for testing in your dev account.
      identifiers = [
        data.aws_caller_identity.current.id,
        aws_iam_role.app_role.arn
      ]
    }
  }
}

data "aws_iam_policy_document" "data_access_policy" {
  statement {
    actions   = ["s3:Get*"]
    resources = ["${aws_s3_bucket.demo.arn}/*"]
  }
  statement {
    actions   = ["s3:ListBucket*"]
    resources = [aws_s3_bucket.demo.arn]
  }
}

resource "aws_iam_role_policy" "data_access_policy" {
  role   = aws_iam_role.data_access_role.id
  policy = data.aws_iam_policy_document.data_access_policy.json
}

# This is the role our app or service assumes, it will have no data access, but has the ability
# to assume the data_access_role via the resource policy / trust relationship on that role.
resource "aws_iam_role" "app_role" {
  name               = "app_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "app_role" {
  role       = aws_iam_role.app_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

locals {
  test_key_a = "123/data.txt"
  test_key_b = "789/data.txt"
}

module "lambda_demo" {
  source      = "./modules/lambda"
  runtime     = "python3.9"
  name        = "my_lambda_scope_down"
  source_file = "${path.module}/main.py"
  lambda_role = aws_iam_role.app_role.arn
  tags        = {}
  environment_variables = {
    "ROLE_ARN"   = aws_iam_role.data_access_role.arn
    "BUCKET"     = aws_s3_bucket.demo.id
    "TEST_KEY_A" = local.test_key_a
    "TEST_KEY_B" = local.test_key_b
  }
}

# Create some S3 objects for testing

resource "aws_s3_object" "object_a" {
  bucket  = aws_s3_bucket.demo.id
  key     = local.test_key_a
  content = "a"
}

resource "aws_s3_object" "object_b" {
  bucket  = aws_s3_bucket.demo.id
  key     = local.test_key_b
  content = "b"
}

# Pretty uncommon pattern here but this lets us invoke the lambda we've just created with
# the test scenarios to verify our scope down / session policy works.

data "aws_lambda_invocation" "invoke_lambda" {
  function_name = module.lambda_demo.function_name
  input         = jsonencode({})
  depends_on = [
    module.lambda_demo
  ]
}

output "lambda_invocation_result" {
  value = jsondecode(data.aws_lambda_invocation.invoke_lambda.result)
}
