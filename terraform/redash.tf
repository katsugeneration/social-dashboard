resource "aws_iam_role" "redash_ecs_exec_role" {
  name = "redash_ecs_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_role" "redash_ecs_task_role" {
  name = "redash_ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "redash_ecs_task_policy" {
  name = "redash_ecs_task_policy"
  role = aws_iam_role.redash_ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid    = "ECSTaskManagement",
        Effect = "Allow",
        Action = [
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:Describe*",
          "ec2:DetachNetworkInterface",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "route53:ChangeResourceRecordSets",
          "route53:CreateHealthCheck",
          "route53:DeleteHealthCheck",
          "route53:Get*",
          "route53:List*",
          "route53:UpdateHealthCheck",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:Get*",
          "servicediscovery:List*",
          "servicediscovery:RegisterInstance",
          "servicediscovery:UpdateInstanceCustomHealthStatus"
        ],
        Resource = "*"
      },
      {
        Sid    = "AutoScaling",
        Effect = "Allow",
        Action = [
          "autoscaling:Describe*"
        ],
        Resource = "*"
      },
      {
        Sid    = "AutoScalingManagement",
        Effect = "Allow",
        Action = [
          "autoscaling:DeletePolicy",
          "autoscaling:PutScalingPolicy",
          "autoscaling:SetInstanceProtection",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Resource = "*",
        Condition = {
          Null = {
            "autoscaling:ResourceTag/AmazonECSManaged" = "false"
          }
        }
      },
      {
        Sid    = "AutoScalingPlanManagement",
        Effect = "Allow",
        Action = [
          "autoscaling-plans:CreateScalingPlan",
          "autoscaling-plans:DeleteScalingPlan",
          "autoscaling-plans:DescribeScalingPlans"
        ],
        Resource = "*"
      },
      {
        Sid    = "CWAlarmManagement",
        Effect = "Allow",
        Action = [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm"
        ],
        Resource = "arn:aws:cloudwatch:*:*:alarm:*"
      },
      {
        Sid    = "ECSTagging",
        Effect = "Allow",
        Action = [
          "ec2:CreateTags"
        ],
        Resource = "arn:aws:ec2:*:*:network-interface/*"
      },
      {
        Sid    = "CWLogGroupManagement",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy"
        ],
        Resource = "arn:aws:logs:*:*:log-group:/aws/ecs/*"
      },
      {
        Sid    = "CWLogStreamManagement",
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"
      },
      {
        Sid    = "ExecuteCommandSessionManagement",
        Effect = "Allow",
        Action = [
          "ssm:DescribeSessions"
        ],
        Resource = "*"
      },
      {
        Sid    = "ExecuteCommand",
        Effect = "Allow",
        Action = [
          "ssm:StartSession"
        ],
        Resource = [
          "arn:aws:ecs:*:*:task/*",
          "arn:aws:ssm:*:*:document/AmazonECS-ExecuteInteractiveCommand"
        ]
      }
    ]
  })
}

resource "aws_ecs_cluster" "redash_ecs" {
  name = "redash_ecs"
}

resource "aws_cloudwatch_log_group" "redash_log" {
  name              = "/ecs/redash"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "redash_server_ecs" {
  family             = "redash_server_ecs"
  cpu                = 512
  memory             = 1024
  execution_role_arn = aws_iam_role.redash_ecs_exec_role.arn
  task_role_arn      = aws_iam_role.redash_ecs_task_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  container_definitions = jsonencode([
    {
      name  = "redash_server"
      image = "redash/redash:9.0.0-beta.b42121"
      command = [
        "dev_server"
      ]
      cpu    = 512
      memory = 1024
      environment = [
        {
          name  = "PYTHONUNBUFFERED"
          value = "0"
        },
        {
          name  = "REDASH_LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "REDASH_REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redash_ec.cache_nodes.0.address}:${aws_elasticache_cluster.redash_ec.cache_nodes.0.port}"
        },
        {
          name  = "REDASH_DATABASE_URL"
          value = "postgresql://${var.redash_db_user_name}:${var.redash_db_user_password}@${aws_db_instance.redash_rds.endpoint}/postgres"
        },
        {
          name  = "REDASH_DATE_FORMAT"
          value = "YY/MM/DD"
        }
      ]
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redash"
          awslogs-region        = var.region
          awslogs-stream-prefix = "server"
        }
      }
    }
  ])

  depends_on = [
    aws_elasticache_cluster.redash_ec,
    aws_db_instance.redash_rds,
  ]
}

resource "aws_ecs_task_definition" "redash_worker_ecs" {
  family             = "redash_worker_ecs"
  cpu                = 512
  memory             = 1024
  execution_role_arn = aws_iam_role.redash_ecs_exec_role.arn
  task_role_arn      = aws_iam_role.redash_ecs_task_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  container_definitions = jsonencode([
    {
      name  = "redash_worker"
      image = "redash/redash:9.0.0-beta.b42121"
      command = [
        "worker"
      ]
      cpu    = 512
      memory = 1024
      environment = [
        {
          name  = "PYTHONUNBUFFERED"
          value = "0"
        },
        {
          name  = "REDASH_LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "REDASH_REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redash_ec.cache_nodes.0.address}:${aws_elasticache_cluster.redash_ec.cache_nodes.0.port}"
        },
        {
          name  = "REDASH_DATABASE_URL"
          value = "postgresql://${var.redash_db_user_name}:${var.redash_db_user_password}@${aws_db_instance.redash_rds.endpoint}/postgres"
        },
        {
          name  = "REDASH_DATE_FORMAT"
          value = "YY/MM/DD"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redash"
          awslogs-region        = var.region
          awslogs-stream-prefix = "worker"
        }
      }
    }
  ])

  depends_on = [
    aws_elasticache_cluster.redash_ec,
    aws_db_instance.redash_rds,
  ]
}

resource "aws_ecs_task_definition" "redash_scheduler_ecs" {
  family             = "redash_scheduler_ecs"
  cpu                = 512
  memory             = 1024
  execution_role_arn = aws_iam_role.redash_ecs_exec_role.arn
  task_role_arn      = aws_iam_role.redash_ecs_task_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  container_definitions = jsonencode([
    {
      name  = "redash_scheduler"
      image = "redash/redash:9.0.0-beta.b42121"
      command = [
        "scheduler"
      ]
      cpu    = 512
      memory = 1024
      environment = [
        {
          name  = "PYTHONUNBUFFERED"
          value = "0"
        },
        {
          name  = "REDASH_LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "REDASH_REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redash_ec.cache_nodes.0.address}:${aws_elasticache_cluster.redash_ec.cache_nodes.0.port}"
        },
        {
          name  = "REDASH_DATABASE_URL"
          value = "postgresql://${var.redash_db_user_name}:${var.redash_db_user_password}@${aws_db_instance.redash_rds.endpoint}/postgres"
        },
        {
          name  = "REDASH_DATE_FORMAT"
          value = "YY/MM/DD"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redash"
          awslogs-region        = var.region
          awslogs-stream-prefix = "scheduler"
        }
      }
    }
  ])

  depends_on = [
    aws_elasticache_cluster.redash_ec,
    aws_db_instance.redash_rds,
  ]
}

resource "aws_ecs_service" "redash_server" {
  name                   = "redash_server"
  cluster                = aws_ecs_cluster.redash_ecs.id
  task_definition        = aws_ecs_task_definition.redash_server_ecs.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.redash_server_alb.arn
    container_name   = "redash_server"
    container_port   = 5000
  }

  network_configuration {
    subnets = [
      aws_subnet.social_dashboard_subnet_private_a.id,
      aws_subnet.social_dashboard_subnet_private_c.id
    ]
    security_groups = [
      aws_security_group.ecs_redash_sg.id
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_task_definition.redash_server_ecs,
    aws_lb_target_group.redash_server_alb,
  ]
}

resource "aws_ecs_service" "redash_worker" {
  name                   = "redash_worker"
  cluster                = aws_ecs_cluster.redash_ecs.id
  task_definition        = aws_ecs_task_definition.redash_worker_ecs.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets = [
      aws_subnet.social_dashboard_subnet_private_a.id,
      aws_subnet.social_dashboard_subnet_private_c.id
    ]
    security_groups = [
      aws_security_group.ecs_redash_sg.id
    ]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_task_definition.redash_worker_ecs]
}

resource "aws_ecs_service" "redash_scheduler" {
  name                   = "redash_scheduler"
  cluster                = aws_ecs_cluster.redash_ecs.id
  task_definition        = aws_ecs_task_definition.redash_scheduler_ecs.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets = [
      aws_subnet.social_dashboard_subnet_private_a.id,
      aws_subnet.social_dashboard_subnet_private_c.id
    ]
    security_groups = [
      aws_security_group.ecs_redash_sg.id
    ]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_task_definition.redash_scheduler_ecs]
}