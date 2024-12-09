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
      image     = var.donut_app_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000 # The .NET Core app listens on port 5000
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Create the ECS service
resource "aws_ecs_service" "donut_service" {
  name            = "donut-service"
  cluster         = aws_ecs_cluster.donut_cluster.id
  task_definition = aws_ecs_task_definition.donut_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.donuteast2a_public_sn.id, aws_subnet.donuteast2b_private_sn.id]
    security_groups = [aws_security_group.web_security_group.id]
  }
}

# Create the load balancer
resource "aws_lb" "donut_lb" {
  name               = "donut-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_security_group.id]
  subnets            = [aws_subnet.donuteast2a_public_sn.id, aws_subnet.donuteast2b_private_sn.id]
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
  vpc_id      = aws_vpc.account_vpc.id
  target_type = "ip"
}

# Attach the ECS service to the load balancer
resource "aws_ecs_service" "donut_ecs_service" {
  name            = "donut-service"
  cluster         = aws_ecs_cluster.donut_cluster.id
  task_definition = aws_ecs_task_definition.donut_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.donuteast2a_public_sn.id]
    security_groups = [aws_security_group.web_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.donut_target_group.arn
    container_name   = "donut-app"
    container_port   = 80
  }
}
