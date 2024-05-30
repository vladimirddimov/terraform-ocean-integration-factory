locals {
  prefix = "port-aws-ocean-sync"
}

# S3
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

# CloudFormation
module "cloudformation_event" {
  source = "../event"

  name        = "${local.prefix}-cloudformation-trails"
  description = "Capture CloudFormation events"
  event_pattern = {
    source      = ["aws.cloudformation"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["cloudformation.amazonaws.com"]
      eventName   = [{ prefix : "CreateStack" }, { prefix : "UpdateStack" }, { prefix : "DeleteStack" }]
    }
  }
  input_paths = {
    resource_type = "AWS::CloudFormation::Stack"
    account_id    = "$.detail.userIdentity.accountId"
    aws_region    = "$.detail.awsRegion"
    event_name    = "$.detail.eventName"
    identifier    = "$.detail.requestParameters.stackName"
  }

  api_key_param = var.api_key_param
  target_arn    = var.target_arn
}

module "cloudformation_status_event" {
  source = "../event"

  name        = "${local.prefix}-cloudformation-status-change-trails"
  description = "Capture CloudFormation status change events"
  event_pattern = {
    source      = ["aws.cloudformation"]
    detail-type = ["CloudFormation Stack Status Change"]
  }
  input_paths = {
    resource_type = "AWS::CloudFormation::Stack"
    account_id    = "$.detail.userIdentity.accountId"
    aws_region    = "$.region"
    event_name    = "$.detail.status-details.status"
    identifier    = "$.detail.stack-id"
  }

  api_key_param = var.api_key_param
  target_arn    = var.target_arn
}

# EC2
module "ec2_tags_event" {
  source = "../event"

  name        = "${local.prefix}-ec2-tags-trails"
  description = "Capture EC2 instance tag events"
  event_pattern = {
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = [{ prefix : "DeleteTags" }, { prefix : "CreateTags" }]
    }
  }
  input_paths = {
    resource_type = "AWS::EC2::Instance"
    account_id    = "$.detail.userIdentity.accountId"
    aws_region    = "$.detail.awsRegion"
    event_name    = "$.detail.eventName"
    identifier    = "$.detail.requestParameters.resourcesSet.items[0].resourceId"
  }

  api_key_param = var.api_key_param
  target_arn    = var.target_arn
}

module "ec2_event" {
  source = "../event"

  name        = "${local.prefix}-ec2-instance-status-change-trails"
  description = "Capture EC2 instance status change events"
  event_pattern = {
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  }
  input_paths = {
    resource_type = "AWS::EC2::Instance"
    account_id    = "$.detail.userIdentity.accountId"
    aws_region    = "$.region"
    event_name    = "$.detail.state"
    identifier    = "$.detail.instance-id"
  }

  api_key_param = var.api_key_param
  target_arn    = var.target_arn
}