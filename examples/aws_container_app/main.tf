locals {
  # This is used for the ecs_service to be able to receive traffic from the load balancer
  ec2_service_security_groups = concat(
    var.additional_security_groups,
    var.allow_incoming_requests ? module.port_ocean_ecs_lb[0].security_groups : []
  )
}

module "port_ocean_ecs_lb" {
  source                  = "../../modules/aws_helpers/ecs_lb"
  count                   = var.allow_incoming_requests ? 1 : 0
  vpc_id                  = var.vpc_id
  subnets                 = var.subnets
  certificate_domain_name = var.certificate_domain_name
}


module "port_ocean_ecs" {
  source = "../../modules/aws_helpers/ecs_service"

  subnets                               = var.subnets
  cluster_name                          = var.cluster_name
  existing_cluster_arn                  = var.existing_cluster_arn
  account_list_regions_resources_policy = var.account_list_regions_resources_policy


  lb_target_group_arn         = var.allow_incoming_requests ? module.port_ocean_ecs_lb[0].target_group_arn : ""
  ecs_service_security_groups = local.ec2_service_security_groups

  image_registry = var.image_registry

  port = {
    client_id     = var.port.client_id
    client_secret = var.port.client_secret
  }

  integration_version       = var.integration_version
  initialize_port_resources = var.initialize_port_resources
  event_listener            = var.event_listener

  integration = {
    type       = var.integration.type
    identifier = var.integration.identifier
    config = var.allow_incoming_requests ? merge({
      app_host = module.port_ocean_ecs_lb[0].dns_name
    }, var.integration.config) : var.integration.config
  }
}

module "api_gateway" {
  source = "../../modules/aws_helpers/api_gateway"
  count  = var.allow_incoming_requests ? 1 : 0

  webhook_url = var.allow_incoming_requests ? module.port_ocean_ecs_lb[0].dns_name : ""
}

module "events" {
  source = "../../modules/aws_helpers/default_events"
  count  = var.allow_incoming_requests ? 1 : 0

  api_key_param = var.integration.config.live_events_api_key
  target_arn    = var.allow_incoming_requests ? module.api_gateway[0].integration_webhook_api_arn : ""
}