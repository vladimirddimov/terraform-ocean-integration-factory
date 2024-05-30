variable "vpc_id" {
  type        = string
  description = "The LB VPC ID"
}

variable "container_port" {
  default     = 8000
  description = "The port the container is listening on"
}

variable "create_default_sg" {
  type        = bool
  default     = true
  description = "Whether to create a default security group"
}

variable "additional_security_groups" {
  type        = list(string)
  default     = []
  description = "Additional security groups to attach to the LB"
}

variable "certificate_domain_name" {
  type        = string
  default     = ""
  description = "The domain name for the certificate"
}

variable "additional_secrets" {
  type        = map(string)
  description = "Additional secrets to pass to the container"
}

variable "subnets" {
  type        = list(string)
  description = "The subnets to deploy the LB to"
}

variable "is_internal" {
  type        = bool
  default     = false
  description = "Whether the LB is internal"
}

variable "create_egress_default_sg" {
  type        = bool
  default     = true
  description = "Whether to create a default egress security group"
}

variable "egress_ports" {
  type        = list(number)
  default     = []
  description = "The ports to allow egress traffic to"
}

variable "image_registry" {
  type        = string
  default     = "ghcr.io/port-labs"
  description = "The registry to pull the image from"
}

variable "integration_version" {
  type        = string
  default     = "latest"
  description = "The version of the integration to deploy"
}

variable "logs_cloudwatch_retention" {
  default     = 90
  type        = number
  description = "Number of days you want to retain log events in the log group."
}

variable "logs_cloudwatch_group" {
  type        = string
  default     = ""
  description = "The name of the log group to create"
}

variable "cpu" {
  default     = 1024
  description = "The amount of CPU to allocate to the container"
}

variable "memory" {
  default     = 2048
  description = "The amount of memory to allocate to the container"
}

variable "network_mode" {
  default     = "awsvpc"
  description = "The network mode to use for the container"
}

variable "ecs_use_fargate" {
  type        = bool
  default     = true
  description = "Whether to use Fargate or EC2"
}

variable "existing_cluster_arn" {
  type        = string
  default     = ""
  description = "The ARN of an existing ECS cluster"
}

variable "cluster_name" {
  type        = string
  default     = "port-ocean-aws-integration-cluster"
  description = "The name of the ECS cluster"
}

variable "assign_public_ip" {
  type        = bool
  default     = true
  description = "Whether to assign a public IP to the container"
}

variable "port" {
  type = object({
    client_id     = string
    client_secret = string
  })
  description = "The port credentials"
}

variable "event_listener" {
  type = object({
    type = string

    # POLLING
    resync_on_start = optional(bool)
    interval        = optional(number)

    # WEBHOOK
    app_host = optional(string)


    # KAFKA
    brokers                  = optional(list(string))
    security_protocol        = optional(list(string))
    authentication_mechanism = optional(list(string))
    kafka_security_enabled   = optional(list(bool))
    consumer_poll_timeout    = optional(list(number))
  })

  default = {
    type = "POLLING"
  }

  validation {
    condition     = can(regex("^(POLLING|KAFKA|WEBHOOK)$", var.event_listener.type))
    error_message = "event_listener.type must be one of POLLING, KAFKA, or WEBHOOK"
  }

  description = "The event listener configuration"
}

variable "initialize_port_resources" {
  type        = bool
  default     = true
  description = "Whether to initialize the port resources"
}

variable "integration" {
  type = object({
    identifier = optional(string)
    type       = optional(string, "aws")
    config = object({
      aws_access_key_id      = optional(string)
      aws_secret_access_key  = optional(string)
      live_events_api_key    = optional(string)
      organization_role_arn  = optional(string)
      account_read_role_name = optional(string)
    })
  })
  description = "The integration configuration"
}

variable "lb_targ_group_arn" {
  type        = string
  default     = ""
  description = "The target group ARN"
}
variable "additional_policy_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  default     = []
  description = "Additional policy statements to attach to the task execution role"
}

variable "allow_incoming_requests" {
  type        = bool
  default     = true
  description = "Whether to allow incoming requests for live events"
}

variable "account_list_regions_resources_policy" {
  type        = list(string)
  default     = ["*"]
  description = "The resources to allow the task role to list regions, check out https://docs.aws.amazon.com/accounts/latest/reference/API_ListRegions.html for more information"
}