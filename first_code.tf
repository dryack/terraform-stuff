provider "aws" {
    profile = "default"
    region = "us-west-2"
}   

resource "aws_s3_bucket" "tf_class" {
    bucket  = "dryack-tf-class-2021"
    acl     = "private"
}
