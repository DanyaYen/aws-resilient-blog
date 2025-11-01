terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # --- ДОБАВЛЕНО ---
    time = {
      source  = "hashicorp/time"
      version = "0.9.1" # Или любая версия > 0.9
    }
    # -----------------
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region = "eu-central-1"
}