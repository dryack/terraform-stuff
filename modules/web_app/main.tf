resource "aws_elb" "this" {
    name            = "${var.web_app}-web"
    subnets         = var.subnets
    security_groups = var.security_groups_elb

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

resource "aws_launch_template" "this" {
  name_prefix   = "${var.web_app}-web"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type
  #vpc_security_group_ids = [aws_security_group.prod_web.id]
  #vpc_security_group_ids = var.subnets
  vpc_security_group_ids = var.security_groups_web 

    tags = {
        "Terraform" : "true"
    }
}

resource "aws_autoscaling_group" "this" {
  #vpc_zone_identifier   = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  vpc_zone_identifier   = var.subnets
  desired_capacity      = var.web_desired_capacity
  max_size              = var.web_max_size
  min_size              = var.web_min_size

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  elb                    = aws_elb.this.id
}
