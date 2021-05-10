provider "aws" {
    profile = "default"
    region = "us-west-2"
}   

resource "aws_s3_bucket" "prod_tf_class" {
    bucket  = "dryack-tf-class-2021"
    acl     = "private"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
    availability_zone = "us-west-2a"
    tags = {
        "Terraform" : "true"
    }
}

resource "aws_default_subnet" "default_az2" {
    availability_zone = "us-west-2c"
    tags = {
        "Terraform" : "true"
    }
}

resource "aws_security_group" "prod_web" {
    name        = "prod_web"
    description = "Allow standard http/https ports inbound and everything outbound"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["172.31.0.0/16"]
    }
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["172.31.0.0/16"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0", "0.0.0.0/0"]
    }

    tags = {
        "Terraform" : "true"
    }
}

# The tutorial didn't cover this SG, but it immediately solved the issue
resource "aws_security_group" "prod_elb" {
    name        = "prod_elb"
    description = "Allow ELB to accept incoming connections via http/https"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["23.124.108.20/32", "149.56.26.83/32"]
    }
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
       #cidr_blocks = ["23.124.108.20/32", "149.56.26.83/32"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0", "0.0.0.0/0"]
    }

    tags = {
        "Terraform" : "true"
    }
}

variable "azs_array" {
    type    = list(string)
    default = ["us-west-2a", "us-west-2c"]
}

resource "aws_elb" "prod_web" {
    name            = "prod-web"
    #instances       = aws_instance.prod_web.*.id
    subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
    #security_groups = [aws_security_group.prod_web.id]
    security_groups = [aws_security_group.prod_elb.id]

    listener {
        instance_port       = 80
        instance_protocol   = "http"
        lb_port             = 80
        lb_protocol         = "http"
    }
    
    tags = {
        "Terraform" : "true"
    }
}

resource "aws_launch_template" "prod_web" {
  name_prefix   = "prod-web"
  image_id      = "ami-03e7d2d88e3e9de77"
  instance_type = "t2.nano"
  vpc_security_group_ids = [aws_security_group.prod_web.id]

    tags = {
        "Terraform" : "true"
    }
}

resource "aws_autoscaling_group" "prod_web" {
  #availability_zones    = ["us-west-2a","us-west-2c"]
  vpc_zone_identifier   = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  desired_capacity      = 2
  max_size              = 2
  min_size              = 1

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id
}
