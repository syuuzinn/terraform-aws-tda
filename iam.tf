# ---------------------------------------------
# IAM role
# ---------------------------------------------
resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.project}-${var.environment}-ec2-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Sid       = ""
      }
    ]
  })

  tags = {
    Name    = "${var.project}-${var.environment}-ec2-iam-role"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = [aws_iam_role.ec2_iam_role]
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-${var.environment}-ec2-iam-role"
  role = aws_iam_role.ec2_iam_role.name
}