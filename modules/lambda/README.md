# Lambda

This is a simple Lambda module. It lets you take a source file and it will package it and publish it as a Lambda function.

This module is designed to create "duct tape" type Lambda functions that extend the functionality of another service where
that code rarely or never changes. If you are trying to do something more involved with Lambda you probably want to look
at [chalice](https://github.com/aws/chalice) or a more involved Lambda packaging mechanism.

## Conventions

The name of the file in the zip package should have the correct extension e.g .py
This allow you to preview the code in the Lambda console.

### Handler

The handler name is then filename without the extension followed by the function name.

e.g if you have a file `my_python.py` with a function `foo_bar` that you want to use as the entry point

Then the handler is `my_python.foo_bar`

This is automatically computed by the module

We assume the handler `filename.lambda_handler` but you can override this if you used a different entry point in your script

### Filename

You pass a path to the source_file. The module will then use the file() function to grab the file, zip it and create the
lambda package

Do not use dots in the filename.

e.g

`my_python_file.py` is good

`my.python.file.py` is bad

This is because the handler is constructed from the filename. And using a.b.c seems to confuse lambda and
breaks inline code preview which can be handy to view the Lambda code from the AWS Console.

## VPC Support

This modules sets subnet_ids and security_group_ids to an empty list. To deploy a Lambda function in a VPC you can set these
variables.

You would deploy a Lambda function in a specific VPC if for example it needs access to a private resource in that VPC such as a Redshift cluster or an RDS Cluster.
