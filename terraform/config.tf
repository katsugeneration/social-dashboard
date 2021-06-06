terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "social-dashboard-terraform-state"
    key    = "terraform.tfstate"
  }
}
