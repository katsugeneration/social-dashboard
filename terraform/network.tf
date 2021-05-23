resource "aws_vpc" "social_dashboard_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "social_dashboard_gw" {
  vpc_id = aws_vpc.social_dashboard_vpc.id
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

resource "aws_subnet" "social_dashboard_subnet_public_a" {
  vpc_id                  = aws_vpc.social_dashboard_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.social_dashboard_vpc,
  ]
}

resource "aws_subnet" "social_dashboard_subnet_public_c" {
  vpc_id                  = aws_vpc.social_dashboard_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.social_dashboard_vpc,
  ]
}

resource "aws_route_table" "social_dashboard_rt" {
  vpc_id = aws_vpc.social_dashboard_vpc.id
}

resource "aws_route" "social_dashboard_route" {
  route_table_id         = aws_route_table.social_dashboard_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.social_dashboard_gw.id
}

resource "aws_route_table_association" "social_dashboard_route_ass_a" {
  route_table_id = aws_route_table.social_dashboard_rt.id
  subnet_id      = aws_subnet.social_dashboard_subnet_public_a.id
}

resource "aws_route_table_association" "social_dashboard_route_ass_d" {
  route_table_id = aws_route_table.social_dashboard_rt.id
  subnet_id      = aws_subnet.social_dashboard_subnet_public_c.id
}

resource "aws_eip" "social_dashboard_nat" {
  vpc = true
}

resource "aws_nat_gateway" "social_dashboard_nat" {
  allocation_id = aws_eip.social_dashboard_nat.id
  subnet_id     = aws_subnet.social_dashboard_subnet_public_a.id
}

resource "aws_route_table" "social_dashboard_private_rt" {
  vpc_id = aws_vpc.social_dashboard_vpc.id
}

resource "aws_route" "social_dashboard_private_route" {
  route_table_id         = aws_route_table.social_dashboard_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.social_dashboard_nat.id
}

resource "aws_route_table_association" "social_dashboard_private_route_ass_a" {
  route_table_id = aws_route_table.social_dashboard_private_rt.id
  subnet_id      = aws_subnet.social_dashboard_subnet_private_a.id
}

resource "aws_route_table_association" "social_dashboard_private_route_ass_c" {
  route_table_id = aws_route_table.social_dashboard_private_rt.id
  subnet_id      = aws_subnet.social_dashboard_subnet_private_c.id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "ALB Redash Security Group"
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

resource "aws_security_group" "ecs_redash_sg" {
  name        = "ecs_redash_sg"
  description = "ECS Redash Server Security Group"
  vpc_id      = aws_vpc.social_dashboard_vpc.id

  ingress {
    description     = "Redash Server Insider Access"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
    aws_security_group.alb_sg,
  ]
}

resource "aws_security_group" "rds_redash_sg" {
  name        = "rds_redash_sg"
  description = "RDS Redash Security Group"
  vpc_id      = aws_vpc.social_dashboard_vpc.id

  ingress {
    description     = "Postgres Insider Access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
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

resource "aws_security_group" "ec_redash_sg" {
  name        = "ec_redash_sg"
  description = "Elastic Cache Redash Security Group"
  vpc_id      = aws_vpc.social_dashboard_vpc.id

  ingress {
    description     = "Redis Insider Access"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
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

resource "aws_lb" "redash_server_alb" {
  name               = "redash-server-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.social_dashboard_subnet_public_a.id,
    aws_subnet.social_dashboard_subnet_public_c.id,
  ]

  depends_on = [
    aws_route_table_association.social_dashboard_route_ass_a,
    aws_route_table_association.social_dashboard_route_ass_d,
  ]
}

resource "aws_lb_target_group" "redash_server_alb" {
  name        = "redash-server-alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.social_dashboard_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "redash_server_alb" {
  load_balancer_arn = aws_lb.redash_server_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redash_server_alb.arn
  }

  depends_on = [
    aws_lb_target_group.redash_server_alb,
    aws_lb.redash_server_alb,
  ]
}
