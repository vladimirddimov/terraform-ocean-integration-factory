variable "vpc_id" {
  type        = string
  description = "The VPC ID"
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

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN of the certificate"
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

variable "app_host" {
  type        = string
  default     = ""
  description = "The host url to use for the app"
}