locals {
  is_certificate_arn_empty         = var.certificate_arn == ""
  is_certificate_domain_name_empty = var.certificate_domain_name == ""
  is_certificate                   = !local.is_certificate_domain_name_empty || !local.is_certificate_arn_empty
  lb_protocol                      = local.is_certificate ? "HTTPS" : "HTTP"
  lb_port                          = local.is_certificate ? "443" : "80"
  egress_ports = var.create_egress_default_sg ? concat([
    443, 9196, var.container_port
  ], var.egress_ports) : concat(var.egress_ports, [var.container_port])
}

data "aws_acm_certificate" "acm_certificate" {
  count  = !local.is_certificate_domain_name_empty && local.is_certificate_arn_empty ? 1 : 0
  domain = var.certificate_domain_name
}

resource "aws_security_group" "default_ocean_sg" {
  count  = var.create_default_sg ? 1 : 0
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = [var.container_port, local.lb_port]
    content {
      description      = "TLS from VPC"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  dynamic "egress" {
    for_each = local.egress_ports
    content {
      from_port        = egress.value
      to_port          = egress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

resource "aws_lb" "ocean_lb" {
  internal           = var.is_internal
  load_balancer_type = "application"
  security_groups = var.create_default_sg ? concat(
    var.additional_security_groups, [aws_security_group.default_ocean_sg[0].id]
  ) : var.additional_security_groups
  subnets = var.subnets
}

resource "aws_lb_target_group" "ocean_tg" {
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/docs"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "lb_listener" {
  default_action {
    order            = "1"
    type             = "forward"
    target_group_arn = aws_lb_target_group.ocean_tg.arn
  }
  load_balancer_arn = aws_lb.ocean_lb.arn
  port              = local.lb_port
  protocol          = local.lb_protocol
  certificate_arn   = !local.is_certificate_domain_name_empty ? data.aws_acm_certificate.acm_certificate[0].arn : (!local.is_certificate_arn_empty ? var.certificate_arn : null)
}