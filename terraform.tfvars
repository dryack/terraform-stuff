web_int_incoming_allowlist = ["172.31.0.0/16"]
web_outgoing_allowlist     = ["0.0.0.0/0", "0.0.0.0/0"]

web_ext_incoming_allowlist = ["23.124.108.20/32", "149.56.26.83/32"]

web_image_id               = "ami-03e7d2d88e3e9de77"
web_instance_type          = "t2.nano"
web_desired_capacity       = 2
web_max_size               = 2
web_min_size               = 1

azs_array                   = ["us-west-2a", "us-west-2c"]
