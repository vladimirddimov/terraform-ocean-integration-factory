# Terraform Module: AWS Integration Setup

## Overview

This Terraform module sets up the necessary AWS infrastructure for integrating with Port using ECS and Fargate. The module provisions an ECS cluster, ECS task definition, and other related resources.

## Prerequisites

- Ensure you have Terraform installed on your machine. You can download it from the [official Terraform website](https://www.terraform.io/downloads.html).
- AWS CLI configured with appropriate credentials.
- Ensure your AWS user has the necessary permissions to create and manage ECS, IAM, and VPC resources.

## Usage

Create a `main.tf` file in your Terraform project and include the following code, modifying the values as necessary:

```hcl
module "aws_integration" {
  source = "port-labs/integration-factory/ocean/examples/aws_container_app"
  version = ">=0.0.24"

  port = {
    client_id     = "<client-id>"
    client_secret = "<client-secret>"
  }
  integration = {
    identifier = "my-aws-integration"
    config = {
      live_events_api_key = "<your-api-key>"
      organization_role_arn  = "arn:.../organization-role"
      account_read_role_name = "ocean-integration-role"
    }
  }
  initialize_port_resources = true
  allow_incoming_requests   = true
  create_default_sg         = false
  subnets                   = ["subnet-1", "subnet-2", "subnet-3"]
  vpc_id                    = "vpc-1"
  cluster_name              = "port-ocean-aws-exporter"
}
```

### Variables Explanation

- `subnets`: List of subnet IDs where the ECS tasks will run.
- `port.client_id`: The client ID for the Port integration.
- `port.client_secret`: The client secret for the Port integration.
- `integration.identifier`: The identifier for the integration.
- `integration.config.live_events_api_key`: A user-defined API key for authenticating with the live events API, for example "my-secret".
- `integration.config.organization_role_arn` (optional): ARN of the role used to assume the organization role.
- `integration.config.account_read_role_name` (optional): Name of the role used to assume the read role in the account.
- `cluster_name` (optional): Name of the ECS cluster.
- `vpc_id` (optional): VPC ID where the cluster will be created.
- `initialize_port_resources`: Boolean to initialize Port resources.
- `create_default_sg`: Boolean to create a default security group.
- `allow_incoming_requests`: Boolean to allow incoming requests to the ECS tasks.

### custom event creation

In order to create a custom event, you can use the `event` module.
The module creates an event rule and a target for the rule in the specified AWS account.

for example, to create an event rule for S3 events, you can use the following code:

```hcl
module "s3_event" {
  source = "../event"

  name        = "${local.prefix}-s3-trails"
  description = "Capture S3 events"
  event_pattern = {
    source      = ["aws.s3"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName   = [{ prefix : "CreateBucket" }, { prefix : "PutBucket" }, { prefix : "DeleteBucket" }]
    }
  }
  input_paths = {
    resource_type = "AWS::S3::Bucket"
    account_id    = "$.detail.userIdentity.accountId"
    aws_region    = "$.detail.awsRegion"
    event_name    = "$.detail.eventName"
    identifier    = "$.detail.requestParameters.bucketName"
  }

  api_key_param = var.api_key_param
  target_arn    = var.target_arn
}
```

### Steps to Deploy

1. **Login to AWS** by running:

   ```sh
   aws sso login
   ```

2. **Initialize the Terraform configuration** by running:

   ```sh
   terraform init
   ```

3. **Review the Terraform plan** to see the changes that will be made:

   ```sh
   terraform plan
   ```

4. **Apply the Terraform plan** to create the resources:
   ```sh
   terraform apply
   ```

## Notes

- Ensure that the specified subnets and VPC exist in your AWS account.
- The AWS credentials provided (if provided) must have the necessary permissions to create and manage the specified resources.
