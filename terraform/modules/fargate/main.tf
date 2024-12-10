/***********
Inputs
************/
variable "vpc_id" {
  description = "The VPC ID to be used by the fargate service"
  type        = string
}

variable "db_endpoint" {
  description = "The endpoint of the donut database"
  type        = string
}

variable "db_port" {
  description = "The port of the donut database"
  type        = number
}

variable "db_user" {
  description = "The user of the donut database"
  type        = string
}

variable "db_password" {
  description = "The password of the donut database"
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet"
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}

variable "security_group_id" {
  description = "The security group to be used by the fargate service"
  type        = string
}

/***********
Compute Configuration with Faragate
************/

# Create the web server through Fargate
resource "aws_ecs_cluster" "donut_cluster" {
  name = "donut-cluster"
}

# Create the ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create the ECS task definition
resource "aws_ecs_task_definition" "donut_task" {
  family                   = "donut-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  
  container_definitions    = jsonencode([
    {
      name      = "donut-app"
      image     = "${var.ecr_repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = var.db_endpoint
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port) # Convert the number to a string
        },
        {
          name  = "DB_USER"
          value = var.db_user
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]
    }
  ])
}

# Create the load balancer
resource "aws_lb" "donut_lb" {
  name               = "donut-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = [var.public_subnet_id, var.private_subnet_id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.donut_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.donut_target_group.arn
  }
}

resource "aws_lb_target_group" "donut_target_group" {
  name        = "donut-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


# Create and attach the ECS service to the load balancer
resource "aws_ecs_service" "donut_ecs_service" {
  name            = "donut-service"
  cluster         = aws_ecs_cluster.donut_cluster.id
  task_definition = aws_ecs_task_definition.donut_task.arn
  desired_count   = 2 # Start with 2 instances
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [var.public_subnet_id, var.private_subnet_id]
    security_groups = [var.security_group_id]
    assign_public_ip = true # Ensure tasks get public IPs
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.donut_target_group.arn
    container_name   = "donut-app"
    container_port   = 80
  }
}

/***********
Outputs
************/
output "lb_dns_name" {
  value       = aws_lb.donut_lb.dns_name
  description = "DNS name of the load balancer"
}