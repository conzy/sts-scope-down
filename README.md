# Scope Down

A simple project to demo STS scope down (session policies)

## Article

This demo has an acompanying [article](https://conormaher.com/robust-logical-isolation-using-aws-sts-scope-down-policies) 

## Running the demo

```bash
git clone git@github.com:conzy/sts-scope-down.git
cd sts-scope-down
terraform init
terraform apply
```

Terraform will create: 
 - AWS IAM Role for the Lambda function
 - AWS IAM Role for data access
 - S3 Bucket with objects under 2 keys.
 - Lambda Function with the test boto3 code

Terraform will also use the `aws_lambda_invocation` data source to invoke the lambda and output the results.

You are now in a position to experiment, you can modify the policies in `main.tf` or play with boto3 and session policies in `main.py`

A `terraform apply` will deploy your changes

You can `terraform destroy` to tidy up, although these resources should not cost you anything.
