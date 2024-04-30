provider "aws" {
  region = "us-east-2"
}

# random lowercase string used for naming
resource "random_string" "resource_id" {
  length  = 8
  lower   = true
  special = false
  upper   = false
  numeric = false
}

data "aws_sagemaker_prebuilt_ecr_image" "deploy_image" {
  repository_name = "pytorch-inference"
  image_tag       = "2.2.0-gpu-py310-cu118-ubuntu20.04-sagemaker"
}

resource "aws_iam_role" "new_role" {
  count = 1
  name  = "deploy-s3-sagemaker-execution-role-${random_string.resource_id.result}"
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

resource "aws_sagemaker_model" "model_with_model_artifact" {
  count              = 1
  name               = "deploy-s3-model-${random_string.resource_id.result}"
  execution_role_arn = aws_iam_role.new_role[0].arn

  primary_container {
    # CPU Image
    image          = data.aws_sagemaker_prebuilt_ecr_image.deploy_image.registry_path
	model_data_url = "s3://instance-transfer/model.tar.gz"
	#model_data_source {
    #  s3_data_source {
    #    s3_uri = "s3://instance-transfer/model.pt"
    #    s3_data_type = "S3Object"
    #    compression_type = "None"
    #  }
	#}
    environment = {
      HF_TASK = "text-classification"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  sagemaker_model = aws_sagemaker_model.model_with_model_artifact[0]
}

resource "aws_sagemaker_endpoint_configuration" "my_endpoint_config" {
  count = 1
  name  = "deploy-s3-ep-config-${random_string.resource_id.result}"


  production_variants {
    variant_name           = "AllTraffic"
    model_name             = local.sagemaker_model.name
    initial_instance_count = 1
    instance_type          = "ml.g4dn.xlarge"
  }
}


locals {
  sagemaker_endpoint_config = aws_sagemaker_endpoint_configuration.my_endpoint_config[0]
}

resource "aws_sagemaker_endpoint" "my_endpoint_config" {
  name = "deploy-s3-ep-${random_string.resource_id.result}"

  endpoint_config_name = local.sagemaker_endpoint_config.name
}
