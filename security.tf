# ---------------------------------------------
# Security Group
# ---------------------------------------------

# alb security group
resource "aws_security_group" "allow_alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-alb-sg"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# ec2 security group
resource "aws_security_group" "allow_ec2" {
  name        = "${var.project}-${var.environment}-ec2-sg"
  description = "EC2 Security Group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.environment}-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_http_ipv4" {
  security_group_id            = aws_security_group.allow_ec2.id
  referenced_security_group_id = aws_security_group.allow_alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "ec2_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# rds security group
resource "aws_security_group" "allow_rds" {
  name        = "basecamp-step1-rds-sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.environment}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_http_ipv4" {
  security_group_id            = aws_security_group.allow_rds.id
  referenced_security_group_id = aws_security_group.allow_ec2.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "rds_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}