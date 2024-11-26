terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6.0"
    }
  }

  backend "s3" {
    # // leave blank, filled in by terraform init dynamically depending on the environment
  }

}
