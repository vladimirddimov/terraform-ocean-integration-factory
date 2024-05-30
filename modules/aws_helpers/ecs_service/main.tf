locals {
  service_name  = "port-ocean-${var.integration.type}-${var.integration.identifier}"
  awslogs_group = var.logs_cloudwatch_group == "" ? "/ecs/${local.service_name}" : var.logs_cloudwatch_group
  port_credentials = [
    {
      name      = "OCEAN__PORT"
      valueFrom = aws_ssm_parameter.ocean_port_credentials.name
    }
  ]

  env = [
    {
      name  = "OCEAN__INITIALIZE_PORT_RESOURCES",
      value = var.initialize_port_resources ? "true" : "false"
    },
    {
      name = "OCEAN__EVENT_LISTENER"
      value = jsonencode({
        for key, value in var.event_listener : key => value if value != null
      })
    },
    {
      name  = "OCEAN__INTEGRATION_IDENTIFIER"
      value = var.integration.identifier
    },
    {
      name  = "OCEAN__INTEGRATION_TYPE"
      value = var.integration.type
    },
    {
      name  = "OCEAN__INTEGRATION_CONFIG"
      value = aws_ssm_parameter.ocean_port_integration_config.name
    }
  ]
}

data "aws_region" "current" {}

resource "aws_ssm_parameter" "ocean_port_integration_config" {
  name  = "ocean.${var.integration.type}.${var.integration.identifier}.integration_config"
  type  = "SecureString"
  value = jsonencode({ for key, value in var.integration.config : key => value if value != null })
}

resource "aws_ssm_parameter" "ocean_port_credentials" {
  name  = "ocean.${var.integration.type}.${var.integration.identifier}.port_credentials"
  type  = "SecureString"
  value = jsonencode(var.port)
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = local.awslogs_group
  retention_in_days = var.logs_cloudwatch_retention

  tags = {
    Name       = local.service_name
    Automation = "Terraform"
  }
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}


data "aws_iam_policy_document" "task_role_account_list_regions_policy" {
  statement {
    actions = [
      "account:ListRegions"
    ]

    resources = var.account_list_regions_resources_policy
  }
}
resource "aws_iam_policy" "task_role_account_list_regions_policy" {
  name   = "ecs-task-role-policy-${local.service_name}"
  policy = data.aws_iam_policy_document.task_role_account_list_regions_policy.json
}
resource "aws_iam_role" "task_role" {
  name               = "ecs-task-role-${local.service_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "task_role_readonly_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "task_role_account_list_regions_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_account_list_regions_policy.arn
}


data "aws_iam_policy_document" "task_execution_role_policy" {
  dynamic "statement" {
    for_each = var.additional_policy_statements

    content {
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }

  statement {
    actions = [
      "ssm:GetParameters"
    ]

    resources = [aws_ssm_parameter.ocean_port_credentials.arn]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.log_group.arn}:*"
    ]
  }
}
resource "aws_iam_policy" "execution-policy" {
  name   = "ecs-task-execution-policy-${local.service_name}"
  policy = data.aws_iam_policy_document.task_execution_role_policy.json
}
resource "aws_iam_role" "task_execution_role" {
  name               = "ecs-task-execution-role-${local.service_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.execution-policy.arn
}

resource "aws_ecs_task_definition" "service_task_definition" {
  family       = local.service_name
  network_mode = var.network_mode

  requires_compatibilities = compact([var.ecs_use_fargate ? "FARGATE" : ""])
  cpu                      = var.ecs_use_fargate ? var.cpu : ""
  memory                   = var.ecs_use_fargate ? var.memory : ""
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn


  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        image       = "${var.image_registry}/port-ocean-${var.integration.type}:${var.integration_version}",
        cpu         = var.cpu,
        memory      = var.memory,
        name        = local.service_name,
        networkMode = var.network_mode,
        environment = local.env,
        secrets     = local.port_credentials
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-create-group  = "true",
            awslogs-group         = "/ecs/${local.service_name}",
            awslogs-region        = data.aws_region.current.name,
            awslogs-stream-prefix = "ecs"
          }
        },
        portMappings = [
          {
            containerPort = var.container_port,
            hostPort      = var.container_port,
            protocol      = "tcp"
          }
        ]
      }
  ])
}

resource "aws_ecs_cluster" "port_ocean_aws_integration_cluster" {
  name  = var.cluster_name
  count = var.existing_cluster_arn == "" ? 1 : 0
}

resource "aws_ecs_service" "ecs_service" {
  cluster = var.existing_cluster_arn != "" ? var.existing_cluster_arn : aws_ecs_cluster.port_ocean_aws_integration_cluster[0].id

  deployment_circuit_breaker {
    enable   = "true"
    rollback = "true"
  }

  deployment_controller {
    type = "ECS"
  }

  name                               = local.service_name
  task_definition                    = aws_ecs_task_definition.service_task_definition.arn
  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"
  desired_count                      = 1
  enable_ecs_managed_tags            = "false"
  enable_execute_command             = "false"
  health_check_grace_period_seconds  = var.lb_target_group_arn != "" ? "30" : "0"
  launch_type                        = "FARGATE"

  dynamic "load_balancer" {
    for_each = var.lb_target_group_arn != "" ? [1] : []
    content {
      container_name   = local.service_name
      container_port   = var.container_port
      target_group_arn = var.lb_target_group_arn
    }
  }

  network_configuration {
    assign_public_ip = var.assign_public_ip
    security_groups  = var.ecs_service_security_groups
    subnets          = var.subnets
  }
  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"

  timeouts {
    create = "10m"
    update = "10m"
    delete = "20m"
  }
}
