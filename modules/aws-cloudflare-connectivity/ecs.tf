# cloudflared connectors run as Fargate tasks instead of EC2 — no instances to
# patch, AMI to track, or capacity to manage. Same outbound-only posture:
# no inbound ports, no public IP, egress-443-only security group.

resource "aws_ecs_cluster" "cloudflared" {
  name = "${var.name_prefix}-cloudflared"
  tags = var.tags
}

resource "aws_security_group" "cloudflared" {
  name        = "${var.name_prefix}-cloudflared"
  description = "Outbound-only: cloudflared needs no inbound ports (tunnel is initiated outbound to Cloudflare)."
  vpc_id      = aws_vpc.this.id

  egress {
    description = "HTTPS to Cloudflare edge"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudflared-sg"
  })
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name_prefix}-cloudflared-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "cloudflared" {
  name              = "/ecs/${var.name_prefix}-cloudflared"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_ecs_task_definition" "cloudflared" {
  family                   = "${var.name_prefix}-cloudflared"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "cloudflared"
      image     = "cloudflare/cloudflared:latest"
      essential = true
      command = [
        "tunnel", "--no-autoupdate", "run",
        "--token", cloudflare_zero_trust_tunnel_cloudflared.clickhouse.tunnel_token
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cloudflared.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "cloudflared"
        }
      }
    }
  ])

  tags = var.tags
}

# One service per AZ private subnet — mirrors the 2x-connector HA pattern,
# without owning any instances.
resource "aws_ecs_service" "cloudflared" {
  count           = length(var.availability_zones)
  name            = "${var.name_prefix}-cloudflared-${var.availability_zones[count.index]}"
  cluster         = aws_ecs_cluster.cloudflared.id
  task_definition = aws_ecs_task_definition.cloudflared.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private[count.index].id]
    security_groups  = [aws_security_group.cloudflared.id]
    assign_public_ip = false
  }

  tags = var.tags
}
