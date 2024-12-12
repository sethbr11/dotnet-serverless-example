/***********
Compute Configuration with Fargate
************/

# ECS Cluster
resource "aws_ecs_cluster" "donut_cluster" {
  name = "donut-cluster"
}

# IAM Role for ECS Task Execution
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

# Attach Default ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach Read-Only ECR Policy for Image Retrieval
resource "aws_iam_role_policy_attachment" "ecs_task_ecr_readonly_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "donut_task" {
  family                   = "donut-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
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
        { name = "DB_HOST", value = var.db_endpoint },
        { name = "DB_PORT", value = tostring(var.db_port) },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASSWORD", value = var.db_password }
      ]

      tags = {
        Name = "donut-rds-app-task"
      }
    }
  ])
}

# Application Load Balancer
resource "aws_lb" "donut_lb" {
  name               = "donut-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.web_security_group_id]
  subnets            = [var.public_subnet_id, var.public_subnet2_id]
}

# Load Balancer Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.donut_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.donut_target_group.arn
  }
}

# Load Balancer Target Group
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

# ECS Service for Fargate
resource "aws_ecs_service" "donut_ecs_service" {
  name            = "donut-service"
  cluster         = aws_ecs_cluster.donut_cluster.id
  task_definition = aws_ecs_task_definition.donut_task.arn
  desired_count   = 1  # Start with 1 instance
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [var.public_subnet_id]
    security_groups = [var.web_security_group_id]
    assign_public_ip = true  # Ensure tasks get public IPs
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.donut_target_group.arn
    container_name   = "donut-app"
    container_port   = 80
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy,
    aws_ecs_task_definition.donut_task
  ]
}
