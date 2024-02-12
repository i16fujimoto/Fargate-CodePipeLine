terraform {
  # required_version = "~> 1.5.0"
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "fargate-cicd-terraform-state-16fujimoto"
    key     = "fargate-codepipeline/terraform.tfstate"
    encrypt = true
    region  = "ap-northeast-1"
    # NOTE: プロファイルを指定するのを忘れずに
    profile = "terraform"
  }
}

provider "aws" {
  region  = var.region
  profile = "terraform"
  # shared_credentials_files = var.shared_credentials # 認証ファイルを指定することも可能
}
