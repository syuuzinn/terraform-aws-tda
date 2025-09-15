# ---------------------------------------------
# ALB
# ---------------------------------------------
resource "aws_lb" "alb" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.allow_alb.id
  ]
  subnets = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id
  ]

}

resource "aws_lb_listener" "lab_listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# ---------------------------------------------
# Target group
# ---------------------------------------------
resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.project}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-tg"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_lb_target_group_attachment" "instance_1a" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance_1c" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_1c.id
  port             = 80
}