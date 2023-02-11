import os
import json
import boto3
from boto3.session import Session
from botocore.exceptions import ClientError

role_arn = os.environ["ROLE_ARN"]
bucket = os.environ["BUCKET"]
test_key_a = os.environ["TEST_KEY_A"]
test_key_b = os.environ["TEST_KEY_B"]

scope_down_policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ScopeDown",
            "Effect": "Allow",
            "Action": ["s3:GetObject*"],
            "Resource": [f"arn:aws:s3:::{bucket}/123/*"],
        }
    ],
}


def get_session(assumed_role):
    return Session(
        aws_access_key_id=assumed_role["Credentials"]["AccessKeyId"],
        aws_secret_access_key=assumed_role["Credentials"]["SecretAccessKey"],
        aws_session_token=assumed_role["Credentials"]["SessionToken"],
    )


def get_scoped_down_s3_client():
    client = boto3.client("sts")
    assumed_role = client.assume_role(
        RoleArn=role_arn,
        RoleSessionName="data_access_scope_down_test",
        Policy=json.dumps(scope_down_policy),
    )
    return get_session(assumed_role).client("s3")


def test_get_object_with_lambda_role_fails():
    """Try fetch the object with the role the Lambda Function assumes"""
    try:
        s3_client = boto3.client("s3")
        response = s3_client.get_object(Bucket=bucket, Key=test_key_a)
        return False
    except ClientError:
        print("Attempt to retrive object using Lambda role failed. This is good!")
        return True


def test_get_object_with_assumed_role_succeeds():
    """Try fetch objects using the assumed role with no scope down"""
    client = boto3.client("sts")
    assumed_role = client.assume_role(
        RoleArn=role_arn,
        RoleSessionName="session_no_scope_down",
    )
    s3_client = get_session(assumed_role).client("s3")
    print(f"Attempting key: {test_key_a}")
    response_a = s3_client.get_object(Bucket=bucket, Key=test_key_a)["ResponseMetadata"]["HTTPStatusCode"]
    print(f"Attempting key: {test_key_b}")
    response_b = s3_client.get_object(Bucket=bucket, Key=test_key_b)["ResponseMetadata"]["HTTPStatusCode"]
    return response_a == 200 and response_b == 200


def test_get_object_with_assumed_role_scope_down_succeeds():
    """Now lets introduce the scope down policy"""
    print("Now trying with scope down policy limiting us to org 123 key")
    s3_client = get_scoped_down_s3_client()
    print(f"Attempting key: {test_key_a}")
    response = s3_client.get_object(Bucket=bucket, Key=test_key_a)["ResponseMetadata"]["HTTPStatusCode"]
    return response == 200


def test_get_object_outside_scope_down_fails():
    print("Attempting access blocked by scope down policy")
    print(f"Attempting key: {test_key_b}")
    s3_client = get_scoped_down_s3_client()
    try:
        s3_client.get_object(Bucket=bucket, Key=test_key_b)
        return False
    except ClientError:
        print("Attempt to retrive object failed because of scope down policy. This is good!")
        return True


def lambda_handler(event, context):
    results = [
        test_get_object_with_lambda_role_fails(),
        test_get_object_with_assumed_role_succeeds(),
        test_get_object_with_assumed_role_scope_down_succeeds(),
        test_get_object_outside_scope_down_fails(),
    ]
    if all(results):
        return "Tests passed. Scope down policy is working as expected"
    return "Something went wrong... IAM is hard."
