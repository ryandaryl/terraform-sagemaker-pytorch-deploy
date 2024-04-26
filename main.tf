# git clone https://github.com/philschmid/terraform-aws-sagemaker-huggingface
module "sagemaker-huggingface" {
  source               = "./terraform-aws-sagemaker-huggingface"
  name_prefix          = "distilbert"
  pytorch_version      = "1.9.1"
  transformers_version = "4.12.3"
  instance_type        = "ml.g4dn.xlarge"
  instance_count       = 1 # default is 1
  hf_model_id          = "distilbert-base-uncased-finetuned-sst-2-english"
  hf_task              = "text-classification"
}