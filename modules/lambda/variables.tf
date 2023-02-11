variable "runtime" {
  type        = string
  description = "The Lambda runtime to use"
  default     = "python3.7"
}

variable "lambda_role" {
  type        = string
  description = "The IAM role the lambda function can assume"
}

variable "timeout" {
  type        = number
  description = "Default function timeout in seconds"
  default     = 20
}

variable "ram" {
  type        = number
  description = "Default ram in MB"
  default     = 512
}

variable "name" {
  type        = string
  description = "The name of this function"
}

variable "source_file" {
  type        = string
  description = "The path to a source file that will be added to the .zip archive"
}

variable "handler" {
  type        = string
  default     = ""
  description = "You can choose to set a custom lambda handler. Otherwise we set filename.lambda_handler"
}

variable "description" {
  type        = string
  default     = "Managed by Terraform"
  description = "You can set a custom description for the Lambda function"
}

variable "environment_variables" {
  type        = map(string)
  description = "A map of environment variables. The below is a default as we need to pass at least one"

  default = {
    managed_by_tf = "true"
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to the resource"
}

variable "layers" {
  type        = list(string)
  default     = []
  description = "A list of layers to use with the function"
}

# See Readme. By setting these variables the Lambda function is deployed in the corresponding VPC
variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "A list of subnet IDs associated with the Lambda function."
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "A list of security group IDs associated with the Lambda function."
}
