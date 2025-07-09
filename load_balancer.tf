# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group for Web Servers
resource "aws_lb_target_group" "web_servers" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Deregistration delay
  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-web-tg"
  }
}

# ALB Listener for HTTP traffic
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }

  tags = {
    Name = "${var.project_name}-web-listener"
  }
}

# Target Group Attachment - will be done in ec2.tf after instances are created 
# Listener Rule: Block specific IP with 400 response
resource "aws_lb_listener_rule" "block_specific_ip" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<!DOCTYPE html><html><head><title>Access Denied</title></head><body><h1>400 - Bad Request</h1><p>Access from your IP address is not allowed.</p><p>Your IP: 210.157.221.7</p></body></html>"
      status_code  = "400"
    }
  }

  condition {
    source_ip {
      values = ["210.157.221.7/32"]
    }
  }

  tags = {
    Name = "${var.project_name}-block-ip-rule"
  }
}

# Listener Rule: Block specific paths with 400 response
resource "aws_lb_listener_rule" "block_admin_paths" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 101

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<!DOCTYPE html><html><head><title>Path Forbidden</title></head><body><h1>400 - Bad Request</h1><p>Access to this path is forbidden.</p><p>Blocked paths: /admin/, /forbidden/, /api/private/</p></body></html>"
      status_code  = "400"
    }
  }

  condition {
    path_pattern {
      values = ["/admin/*", "/forbidden/*", "/api/private/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-block-paths-rule"
  }
}

# Listener Rule: Mobile-specific content
resource "aws_lb_listener_rule" "mobile_content" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 102

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<!DOCTYPE html><html><head><title>📱 Mobile Site</title><meta name='viewport' content='width=device-width, initial-scale=1'><style>body{font-family:Arial;padding:20px;text-align:center;background:#f0f8ff}</style></head><body><h1>�� Mobile Version</h1><p>Welcome to the mobile-optimized site!</p><p><strong>Detected: Mobile Device</strong></p><p>This is special content for mobile users!</p><hr><p>Server: Mobile-Optimized ALB Response</p></body></html>"
      status_code  = "200"
    }
  }

  condition {
    http_header {
      http_header_name = "User-Agent"
      values           = ["*Mobile*", "*Android*", "*iPhone*", "*iPad*", "*iPod*", "*BlackBerry*", "*Windows Phone*"]
    }
  }

  tags = {
    Name = "${var.project_name}-mobile-content-rule"
  }
}
