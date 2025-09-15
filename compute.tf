# ---------------------------------------------
# EC2 instance
# ---------------------------------------------
resource "aws_instance" "ec2_1a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1a.id

  vpc_security_group_ids = [
    aws_security_group.allow_ec2.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-ec2-1"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_instance" "ec2_1c" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1c.id

  vpc_security_group_ids = [
    aws_security_group.allow_ec2.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-ec2-2"
    Project = var.project
    Env     = var.environment
  }
}