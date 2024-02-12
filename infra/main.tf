terraform {
  required_version = "~> 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "fargate-cicd-terraform-state"
    key     = "fargate-codepipeline-i16fujimoto/terraform.tfstate"
    encrypt = true
    region  = "ap-northeast-1"
  }
}

provider "aws" {
  region = var.region
  profile = "terraform"
}
