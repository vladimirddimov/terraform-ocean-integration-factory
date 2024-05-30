variable "name" {
  type        = string
  description = "The name of the event"
}

variable "description" {
  type        = string
  description = "The description of the event"
}

variable "event_pattern" {
  type = object({
    source      = list(string)
    detail-type = list(string)
    detail      = optional(any)
  })
}

variable "input_paths" {
  type = object({
    account_id    = string,
    aws_region    = string,
    event_name    = string,
    identifier    = string,
    resource_type = string,
  })
  description = "The input paths"
}

variable "target_arn" {
  type        = string
  description = "The ARN of the target"
}

variable "api_key_param" {
  type        = string
  description = "The API Key parameter"
}