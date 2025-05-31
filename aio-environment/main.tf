# s3
resource "aws_s3_bucket" "filestore" {
  bucket        = "will-filestore"
  force_destroy = true
}


resource "aws_s3_bucket_policy" "filestore" {
  bucket = aws_s3_bucket.filestore.id
  policy = data.aws_iam_policy_document.s3_filestore.json
}

resource "aws_s3_bucket_ownership_controls" "filestore" {
  bucket = aws_s3_bucket.filestore.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


data "aws_iam_policy_document" "s3_filestore" {
  statement {
    actions = ["s3:getObject"]
    effect  = "Allow"

    resources = ["${aws_s3_bucket.filestore.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task.arn]
    }
  }
}


resource "aws_s3_bucket_public_access_block" "filestore" {
  bucket                  = aws_s3_bucket.filestore.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ecs
resource "aws_ecs_cluster" "backend" {
  name = "backend-cluster"
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # predefined by aws
}

resource "aws_iam_role" "ecs_task" {
  name               = "ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

# cache
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "redis-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "redis-replication-group"
  description                = "an example group with one replica and not Multi-AZ "
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t3.micro"
  num_node_groups            = 1
  replicas_per_node_group    = 1
  automatic_failover_enabled = true
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  port               = 6379
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Name = "redis-replication-group"
  }
}

resource "aws_security_group" "redis" {
  name        = "redis-sg"
  description = "Allow redis access from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.service.id]
    description     = "allow ecs tasks to connect to Redis"
  }
}

# rds
resource "aws_db_subnet_group" "postgres" {
  name       = "test-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier        = "test-db-postgres"
  engine            = "postgres"
  engine_version    = "16.3"
  allocated_storage = 20
  storage_type      = "gp2"
  instance_class    = "db.t3.micro"

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  skip_final_snapshot = true # for testing only
  publicly_accessible = false

  tags = {
    Name = "test-db"
  }
}

resource "aws_security_group" "postgres" {
  name        = "postgres-sg"
  description = "Allow access to RDS"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.service.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# ecs
resource "aws_security_group" "service" {
  name        = "service-sg"
  description = "security group for computing services"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "service-sg"
  }
}

# secret manager
# 1. define a secret manager
resource "aws_secretsmanager_secret" "pg_credentials" {
  name        = "pg-db-credentials"
  description = "PostgreSQL credentials for my RDS instance"
}

# 2. random password
resource "random_password" "db_master" {
  length  = 16
  special = false
}


# 3. create the secret value
resource "aws_secretsmanager_secret_version" "pg_credentials_version" {
  secret_id = aws_secretsmanager_secret.pg_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_master.result
  })
}

# ecr
# 1. setup ecr
resource "aws_ecr_repository" "backend" {
  name = "backend"
}

# 2. setup ecr lifecycle policy
resource "aws_ecr_lifecycle_policy" "backend" {
  resource = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire untagged image after 14 days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 14
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

}


# 4. allow IAM roles or services to access secret value

# ecs
# resource "aws_ecs_task_definition" "backend" {
#   family                   = "backend"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "256"
#   memory                   = "512"

#   execution_role_arn = aws_iam_role.ecs_task_execution.arn
#   task_role_arn      = aws_iam_role.ecs_task.arn

#   container_definition = jsonencode([
#     {
#       name      = "backend"
#       image     = "...." # from ecr
#       essential = true
#       portMappings = [
#         {
#           containerPort = 8000
#           hostPort      = 8000
#           protocol      = "tcp"
#         }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.backend
#           awslogs-create-group  = true
#           awslogs-region        = "ap-northeast-1"
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#       environment = [
#         {
#           name  = "ENV"
#           value = "production"
#         }
#       ]
#     }
#   ])
# }

# resource "aws_ecs_service" "backend" {
#   name                   = "backend"
#   cluster                = aws_ecs_cluster.backend.id
#   task_definition        = aws_ecs_task_definition.backend.arn
#   desired_count          = 2
#   launch_type            = "FARGATE"
#   enable_execute_command = true

#   network_configuration {
#     subnets          = [aws_subnet.private.id]
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.app_tg.arn
#     container_name   = "backend"
#     container_port   = 8000
#   }

#   depends_on = [aws_lb_listener.app_listener]
# }

# ecr
# resource "aws_ecr_repository" "main" {
#   name = "main"
# }

# resource "aws_cloudwatch_log_group" "backend" {
#   name = "/ecs/backend"
# }

# nat gateway
# resource "aws_eip" "nat" {
#   vpc = true
# }

# resource "aws_nat_gateway" "main" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public.id


#   tags = {
#     Name = "main"
#   }
# }


# #public route table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.vpc_id

#   route = {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

#   tags = {
#     Name = "main"
#   }
# }

# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route = {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.main.id
#   }

#   tags = {
#     Name = "main"
#   }
# }

# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }


