# random lowercase string used for naming
resource "random_string" "resource_id" {
  length  = 8
  lower   = true
  special = false
  upper   = false
  numeric = false
}

data "aws_sagemaker_prebuilt_ecr_image" "deploy_image" {
  repository_name = "huggingface-pytorch-inference"
  image_tag       = "1.9.1-transformers4.12.3-gpu-py38-cu111-ubuntu20.04"
}

resource "aws_iam_role" "new_role" {
  count = 1
  name  = "deploy-hub-sagemaker-execution-role-${random_string.resource_id.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "terraform-inferences-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "cloudwatch:PutMetricData",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:DescribeLogStreams",
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ],
          Resource = "*"
        }
      ]
    })

  }
}

resource "aws_sagemaker_model" "model_with_hub_model" {
  count              = 1
  name               = "deploy-hub-model-${random_string.resource_id.result}"
  execution_role_arn = aws_iam_role.new_role[0].arn

  primary_container {
    image = data.aws_sagemaker_prebuilt_ecr_image.deploy_image.registry_path
    environment = {
      HF_TASK           = "text-classification"
      HF_MODEL_ID       = "distilbert-base-uncased-finetuned-sst-2-english"
      HF_API_TOKEN      = null
      HF_MODEL_REVISION = null
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  sagemaker_model = aws_sagemaker_model.model_with_hub_model[0]
}

resource "aws_sagemaker_endpoint_configuration" "huggingface" {
  count = 1
  name  = "deploy-hub-ep-config-${random_string.resource_id.result}"


  production_variants {
    variant_name           = "AllTraffic"
    model_name             = local.sagemaker_model.name
    initial_instance_count = 1
    instance_type          = "ml.g4dn.xlarge"
  }
}


locals {
  sagemaker_endpoint_config = aws_sagemaker_endpoint_configuration.huggingface[0]
}

resource "aws_sagemaker_endpoint" "huggingface" {
  name = "deploy-hub-ep-${random_string.resource_id.result}"

  endpoint_config_name = local.sagemaker_endpoint_config.name
}
