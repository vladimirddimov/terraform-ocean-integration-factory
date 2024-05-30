### Example for Azure Integration over Azure ContainerApp:

```hcl
module "ocean_container_app_example_azure-integration" {
  source  = "port-labs/integration-factory/ocean//examples/azure_container_app_azure_integration"
  version = ">=0.0.24"

  port_client_id = "xxxxx-xxxx-xxxx-xxxx"
  port_client_secret = "yyyy-yyyy-yyyy-yyyy"
}
```

### Example for Azure Integration over Azure ContainerApp with specified subscription id to be used for hosting:

```hcl
module "ocean_container_app_example_azure-integration" {
  source  = "port-labs/integration-factory/ocean//examples/azure_container_app_azure_integration"
  version = ">=0.0.24"

  port_client_id = "xxxxx-xxxx-xxxx-xxxx"
  port_client_secret = "yyyy-yyyy-yyyy-yyyy"
  hosting_subscription_id = "zzzz-zzzz-zzzz-zzzz"
}
```

### Example for Azure Integration over Azure ContainerApp with Existing Event Grid System Topic:

```hcl
module "ocean_container_app_example_azure-integration" {
  source  = "port-labs/integration-factory/ocean//examples/azure_container_app_azure_integration"
  version = ">=0.0.24"

  port_client_id = "xxxxx-xxxx-xxxx-xxxx"
  port_client_secret = "yyyy-yyyy-yyyy-yyyy"

  event_grid_system_topic_name = "my-event-grid-system-topic-name"
}
```
