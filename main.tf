/*
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
*/

resource "aws_ecs_cluster" "flask_app_demo" {
  name = "flask-app-demo"
}
resource "aws_ecs_task_definition" "flask_app_demo" {
  family                   = "flask-app-demo"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions = <<DEFINITION
[
  {
    "name": "flask-app-demo",
    "image": "${var.image_repo_url}:${var.image_tag}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.flask_app_demo.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "flask-app-demo"
      }
    }
  }
]
DEFINITION
  execution_role_arn = aws_iam_role.task_definition_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}
resource "aws_cloudwatch_log_group" "flask_app_demo" {
  name = "/ecs/flask-app-demo"
}

resource "aws_ecs_service" "flask_app_demo" {
  name            = "flask-app-demo"
  cluster         = aws_ecs_cluster.flask_app_demo.id
  task_definition = aws_ecs_task_definition.flask_app_demo.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [for key, subnet in aws_subnet.public : subnet.id ]
    security_groups = [aws_security_group.flask_app_demo.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.flask_app_demo.arn
    container_name   = "flask-app-demo"
    container_port   = 5000
  }
}


resource "aws_lb_target_group" "flask_app_demo" {
  name        = "flask-app-demo"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc-flask.id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb" "flask_app_demo" {
  name               = "flask-app-demo"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.asg.id]
  subnets            = [for key, subnet in aws_subnet.public : subnet.id ]
  enable_deletion_protection = false
  tags = {
    Name = "flask-app-demo"
  }
}


resource "aws_lb_listener" "flask_app_demo" {
  load_balancer_arn = aws_lb.flask_app_demo.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_app_demo.arn
  }
}
resource "aws_lb_listener_rule" "flask_app_demo" {
  listener_arn = aws_lb_listener.flask_app_demo.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_app_demo.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}


resource "aws_iam_role" "task_definition_role" {
  name = "flask_demo_task_definition"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "task_definition_policy" {
  name = "flask_demo_task_definition_policy"
  role = aws_iam_role.task_definition_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

/*
resource "aws_codepipeline" "codepipeline" {
  name     = "flask_demo_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
    encryption_key {
      id   = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = var.github_branch
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.flask_app.name
      }
    }
  }
}

*/