terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}


provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "main"
    }
} 


resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id


    tags = {
        Name = "main"
    }
} 

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.vpc_id
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1"
    cidr_block = "10.0.1.0/24"


    tags = {
        Name = "main"
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.vpc_id
    availability_zone = "ap-northeast-1"
    cidr_block = "10.0.2.0/24"

    tags = {
        Name = "main"
    }
}

resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public.id


    tags = {
        Name = "main"
    }
}


#public route table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.vpc_id

    route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "main"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route = {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "main"
    }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_ecr_repository" "main" {
    name = "main"
}


resource "aws_ecs_cluster" "backend" {
    name = "backend-cluster"
}


# setup a role
resource "aws_iam_role" "ecs_task_execution" {
    name = "ecsTaskExecutionRole"
    assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
    role = aws_iam_role.ecs_task_execution
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # predefined by aws
}

resource "aws_cloudwatch_log_group" "backend" {
    name = "/ecs/backend"
}

resource "aws_ecs_task_definition" "backend" {
    family = "backend"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "2"
    memory = "512"

    execution_role_arn = aws_iam_role.ecs_task_execution.arn
    task_role_arn = aws_iam_role.ecs_task_execution.arn

    container_definition = jsonencode([
        {
            name = "backend"
            image = "...." # from ecr
            essential = true
            portMappings = [
                {
                    containerPort = 8000
                    hostPort = 8000
                    protocol = "tcp"
                }
            ]
            logConfiguration = {
                logDriver = "awslogs"
                options = {
                    awslogs-group = aws_cloudwatch_log_group.backend
                    awslogs-create-group = true
                    awslogs-region = "ap-northeast-1"
                    awslogs-stream-prefix = "ecs"
                }
            }
            environment = [
                {
                    name = "ENV"
                    value = "production"
                }
            ]
        }
    ])
}

resource "aws_ecs_service" "backend" {
    name = "backend"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.backend.arn

    desired_count = 2
    launch_type = "FARGATE"
    enable_execute_command = true

    network_configuration {
        subnets = aws_subnet.private.id
        assign_public_ips = true
        security_group
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.app_tag.arn
        container_name = "backend"
        container_port = 8000
    }
}


#alb, security_group