# ---------------------------------------------
# Security Group
# ---------------------------------------------
resource "aws_security_group" "terra_allow_alb" {
  name        = "basecamp-step1-alb-sg"
  description = "ALB用のセキュリティグループ"
  vpc_id      = aws_vpc.terra_vpc.id

  tags = {
    Name = "basecamp-step1-alb-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.terra_allow_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "terra_allow_ec2" {
  name        = "basecamp-step1-alb-sg"
  description = "EC2用のセキュリティグループ"
  vpc_id      = aws_vpc.terra_vpc.id

  tags = {
    Name = "basecamp-step1-ec2-sg"
  }
}

resource "aws_security_group" "terra_allow_rds" {
  name        = "basecamp-step1-rds-sg"
  description = "RDS用のセキュリティグループ"
  vpc_id      = aws_vpc.terra_vpc.id

  tags = {
    Name = "basecamp-step1-alb-sg"
  }
}
