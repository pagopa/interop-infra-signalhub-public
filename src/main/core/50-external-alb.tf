data "aws_subnets" "ext_lbs" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.ext_lbs_cidrs)
  }
}

resource "aws_security_group" "sh_api" {
  name        = format("elb/%s-api-%s", local.project, var.env)
  description = "SignalHub APIs external load balancer"

  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "sh_api" {
  name = format("%s-api-%s", local.project, var.env)

  enable_deletion_protection = true

  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.sh_api.id]
  subnets            = data.aws_subnets.ext_lbs.ids
  ip_address_type    = "ipv4"

  preserve_host_header = true

  access_logs {
    bucket  = module.alb_logs_bucket.s3_bucket_id
    enabled = true
  }
}

resource "aws_route53_record" "sh_api" {
  zone_id = aws_route53_zone.sh_base.zone_id
  name    = format("api.%s", aws_route53_zone.sh_base.name)
  type    = "A"

  alias {
    name                   = aws_lb.sh_api.dns_name
    zone_id                = aws_lb.sh_api.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener" "sh_api_443" {
  load_balancer_arn = aws_lb.sh_api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.sh_api.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      status_code  = var.sh_api_maintenance_mode ? "503" : "404"
      content_type = "application/json"
    }
  }
}

resource "aws_lb_listener_rule" "v1_pull_signal" {
  count = var.sh_api_maintenance_mode ? 0 : 1

  listener_arn = aws_lb_listener.sh_api_443.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pull_signal.arn
  }

  condition {
    http_request_method {
      values = ["GET"]
    }
  }

  condition {
    path_pattern {
      values = ["/1.0/pull/signals/*"]
    }
  }
}

resource "aws_lb_listener_rule" "v1_push_signal" {
  count = var.sh_api_maintenance_mode ? 0 : 1

  listener_arn = aws_lb_listener.sh_api_443.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.push_signal.arn
  }

  condition {
    http_request_method {
      values = ["POST"]
    }
  }

  condition {
    path_pattern {
      values = ["/1.0/push/signals"]
    }
  }
}

resource "aws_lb_listener_rule" "v1_pull_status" {
  count = var.sh_api_maintenance_mode ? 0 : 1

  listener_arn = aws_lb_listener.sh_api_443.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pull_signal.arn
  }

  condition {
    http_request_method {
      values = ["GET"]
    }
  }

  condition {
    path_pattern {
      values = ["/1.0/pull/status"]
    }
  }
}

resource "aws_lb_listener_rule" "v1_push_status" {
  count = var.sh_api_maintenance_mode ? 0 : 1

  listener_arn = aws_lb_listener.sh_api_443.arn
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.push_signal.arn
  }


  condition {
    http_request_method {
      values = ["GET"]
    }
  }

  condition {
    path_pattern {
      values = ["/1.0/push/status"]
    }
  }
}
