resource "aws_lambda_function" "lambda" {
  filename         = "${var.name}.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = var.name
  role             = var.lambda_role
  description      = var.description

  handler     = var.handler != "" ? var.handler : "${local.file_name_no_extension}.lambda_handler"
  runtime     = var.runtime
  timeout     = var.timeout
  memory_size = var.ram

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = var.environment_variables
  }

  tags   = var.tags
  layers = var.layers
}

# This creates a zip of the file whose path is passed
data "archive_file" "lambda_zip" {
  type                    = "zip"
  output_path             = "${var.name}.zip"
  source_content          = file(var.source_file)
  source_content_filename = local.file_name
}

# Do not use dots in file names as it will break the lambda handler / inline code display
locals {
  file_name              = basename(var.source_file)
  temp                   = split(".", local.file_name)
  file_name_no_extension = join(".", slice(local.temp, 0, length(local.temp) - 1))
}
