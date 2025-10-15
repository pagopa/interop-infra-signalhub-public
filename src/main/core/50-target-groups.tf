locals {
  tg_k8s_namespace = var.env
}

resource "aws_lb_target_group" "push_signal" {
  name = format("%s-push-signal", local.tg_k8s_namespace)

  port            = 8088
  protocol        = "HTTP"
  target_type     = "ip"
  ip_address_type = "ipv4"
  vpc_id          = module.vpc.vpc_id

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    enabled             = true
    interval            = 10
    path                = "/health"
    port                = 8088
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_lb_target_group" "pull_signal" {
  name = format("%s-pull-signal", local.tg_k8s_namespace)

  port            = 8088
  protocol        = "HTTP"
  target_type     = "ip"
  ip_address_type = "ipv4"
  vpc_id          = module.vpc.vpc_id

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    enabled             = true
    interval            = 10
    path                = "/health"
    port                = 8088
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = 200
  }
}
