resource "aws_vpc" "social_dashboard_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "social_dashboard_subnet_private_a" {
  vpc_id                  = aws_vpc.social_dashboard_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  depends_on = [
    aws_vpc.social_dashboard_vpc,
  ]
}

resource "aws_subnet" "social_dashboard_subnet_private_c" {
  vpc_id                  = aws_vpc.social_dashboard_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  depends_on = [
    aws_vpc.social_dashboard_vpc,
  ]
}


resource "aws_subnet" "social_dashboard_subnet_public" {
  vpc_id                  = aws_vpc.social_dashboard_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1d"
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.social_dashboard_vpc,
  ]
}

resource "aws_security_group" "ecs_redash_sg" {
  name        = "ecs_redash_sg"
  description = "ECS Redash Security Group"
  vpc_id      = aws_vpc.social_dashboard_vpc.id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [
    aws_vpc.social_dashboard_vpc,
  ]
}

resource "aws_security_group" "rds_redash_sg" {
  name        = "rds_redash_sg"
  description = "RDS Redash Security Group"
  vpc_id      = aws_vpc.social_dashboard_vpc.id

  ingress {
    description = "Postgres Insider Access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_redash_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [
    aws_vpc.social_dashboard_vpc,
    aws_security_group.ecs_redash_sg,
  ]
}

