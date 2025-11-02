terraform {
  backend "s3" {
    bucket         = "my-tf-state-blog-project-2025"
    key            = "eks-wordpress/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-lock"
  }
}