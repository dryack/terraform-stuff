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

#resource "aws_ami_launch_permission" "prod_web" {
#    image_id    = "ami-03e7d2d88e3e9de77"
#    account_id  = "465478892372"
#}

variable "azs_array" {
    type    = list(string)
    default = ["us-west-2a", "us-west-2c"]
}

resource "aws_instance" "prod_web" {
    count = 2

    ami                 = "ami-03e7d2d88e3e9de77"
    instance_type       = "t2.nano"
    availability_zone   = var.azs_array[count.index]

    vpc_security_group_ids = [
        aws_security_group.prod_web.id
    ]
    
    tags = {
        "Terraform" : "true"
    }
}

resource "aws_eip_association" "prod_web" {
    instance_id     = aws_instance.prod_web.0.id
    allocation_id   = aws_eip.prod_web.id
}

resource "aws_eip" "prod_web" {
    tags = {
        "Terraform" : "true"
    }
}

resource "aws_elb" "prod_web" {
    name            = "prod-web"
    instances       = aws_instance.prod_web.*.id
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
