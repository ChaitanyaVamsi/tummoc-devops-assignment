  resource "aws_alb" "main" {
    name= "${local.common_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb.id]
    subnets = [aws_subnet.public.id,aws_subnet.public_b.id]
    enable_deletion_protection = false
    tags = merge(local.common_tags,{
      Name="${local.common_name}-alb"
    })
  }

# app server
  resource "aws_lb_target_group" "app" {
    name        = "${var.project}-${var.environment}-tg"
    port        = 3000
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
    target_type = "instance"

    # Health check — ALB uses this to know if the EC2 is healthy
    health_check {
      enabled             = true
      path                = "/"
      port                = "traffic-port"
      protocol            = "HTTP"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      matcher             = "200-399"
    }
    #  stickiness {
    #   type            = "lb_cookie"
    #   cookie_duration = 86400 # 1 day in seconds
    #   enabled         = true
    # }

    tags = { Name = "${var.project}-${var.environment}-tg" }
  }

  resource "aws_lb_target_group_attachment" "app" {
    target_group_arn = aws_lb_target_group.app.arn
    target_id        = aws_instance.app.id
    port             = 3000
  }

  resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_alb.main.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  }

# jenkins server
    resource "aws_lb_target_group" "jenkins" {
    name        = "${var.project}-${var.environment}-jenkins-tg"
    port        = 8080
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
    target_type = "instance"

    # Health check — ALB uses this to know if the EC2 is healthy
    health_check {
      enabled             = true
      path                = "/login"
      port                = "traffic-port"
      protocol            = "HTTP"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      matcher             = "200-399"
    }

    tags = { Name = "${var.project}-${var.environment}-jenkins-tg" }
  }

    resource "aws_lb_target_group_attachment" "jenkins" {
    target_group_arn = aws_lb_target_group.jenkins.arn
    target_id        = aws_instance.jenkins.id
    port             = 8080
  }

  resource "aws_lb_listener" "jenkins_port" {
    load_balancer_arn = aws_alb.main.arn
    port              = 81
    protocol          = "HTTP"
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.jenkins.arn
    }
  }