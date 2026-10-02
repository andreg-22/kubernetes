terraform {
  required_version = "1.16.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }


  cloud {

    organization = "Andre-HCP_ENV"

    workspaces {
      name = "Kubeadm"
    }
  }
}


provider "aws" {
  region = "us-east-1"

}