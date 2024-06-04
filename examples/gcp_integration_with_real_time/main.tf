locals {
  envs = var.environment_variables != null ? var.environment_variables : [
    {
      name  = "OCEAN__PORT__CLIENT_ID",
      value = var.port_client_id
    },
    {
      name  = "OCEAN__PORT__CLIENT_SECRET",
      value = var.port_client_secret
    },
    {
      name  = upper("OCEAN__INITIALIZE_PORT_RESOURCES"),
      value = var.initialize_port_resources ? "true" : "false"
    },
    {
      name = upper("OCEAN__EVENT_LISTENER")
      value = jsonencode({
        for key, value in var.event_listener : key => value if value != null
      })
    },
    {
      name = upper("OCEAN__INTEGRATION")
      value = jsonencode({
        "identifier": var.integration_identifier,
        "type": var.integration_type,
        "config": {}
      })
    }
  ]
  feed_topic_id = var.assets_feed_topic_id != null ? var.assets_feed_topic_id : "ocean-integration-topic"
  permissions = var.gcp_ocean_integration_sa_permissions != null ? var.gcp_ocean_integration_sa_permissions : ["cloudasset.assets.exportResource",
    "cloudasset.assets.listCloudAssetFeeds",
    "cloudasset.assets.listResource",
    "cloudasset.assets.searchAllResources",
    "cloudasset.feeds.create",
    "cloudasset.feeds.list",
    "pubsub.topics.list",
    "pubsub.topics.get",
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    "resourcemanager.folders.get",
    "resourcemanager.folders.list",
    "resourcemanager.organizations.get",
    "run.routes.invoke",
  "run.jobs.run"]
  asset_types = var.assets_types_for_monitoring != null ? var.assets_types_for_monitoring : [
    "artifactregistry.googleapis.com/DockerImage",
    "artifactregistry.googleapis.com/Repository",
    "cloudresourcemanager.googleapis.com/Organization",
    "cloudresourcemanager.googleapis.com/Folder",
    "cloudresourcemanager.googleapis.com/Project",
    "firestore.googleapis.com/Database",
    "container.googleapis.com/Cluster",
    "container.googleapis.com/NodePool",
    "iam.googleapis.com/Role",
    "iam.googleapis.com/ServiceAccount",
    "storage.googleapis.com/Bucket",
    "cloudfunctions.googleapis.com/CloudFunction",
    "pubsub.googleapis.com/Subscription",
    "pubsub.googleapis.com/Topic"
  ]
  service_account_id = var.service_account_name != null ? var.service_account_name : "ocean-service-account"
  role_id            = var.role_name != null ? var.role_name : "OceanIntegrationRole"
}
module "port_ocean_authorization" {
  source             = "../../modules/gcp_helpers/authorization"
  permissions        = local.permissions
  service_account_id = local.service_account_id
  role_id            = local.role_id
  organization       = var.gcp_organization
  project            = var.gcp_ocean_setup_project
  projects           = var.gcp_projects
}
module "port_ocean_pubsub" {
  source                     = "../../modules/gcp_helpers/pubsub"
  push_endpoint              = "${module.port_ocean_cloud_run.endpoint}/integration/events"
  ocean_integration_topic_id = local.feed_topic_id
  project                    = var.gcp_ocean_setup_project
  service_account_email      = module.port_ocean_authorization.service_account_email
}

module "port_ocean_assets_feed" {
  source             = "../../modules/gcp_helpers/assets_feed"
  feed_topic_project = var.gcp_ocean_setup_project
  billing_project    = var.gcp_ocean_setup_project
  assets_feed_id     = var.assets_feed_id
  projects           = var.gcp_projects
  feed_topic         = module.port_ocean_pubsub.ocean_topic_name
  organization       = var.gcp_organization
  asset_types        = local.asset_types
  depends_on         = [module.port_ocean_cloud_run]
}
resource "time_sleep" "wait_for_authentication_to_take_affect" {
  depends_on      = [module.port_ocean_authorization]
  create_duration = "180s"
}
module "port_ocean_cloud_run" {
  source                = "../../modules/gcp_helpers/cloud_run"
  service_account_name  = "${var.service_account_name}@${var.gcp_ocean_setup_project}.iam.gserviceaccount.com"
  environment_variables = local.envs
  project               = var.gcp_ocean_setup_project
  image                 = var.gcp_ocean_integration_image
  depends_on            = [time_sleep.wait_for_authentication_to_take_affect]
}
