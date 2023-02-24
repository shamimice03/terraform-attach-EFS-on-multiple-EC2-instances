instance_type               = "t2.micro"
key_name                    = "aws_access_key"
public_instance_per_subnet  = 3
private_instance_per_subnet = 2
private_key_location        = "/Users/shamimmd/.ssh/aws_access_key.pem"
public_instance_sg_ports = [
  {
    "port" : 22,
    "protocol" : "tcp"
  },
]
private_instance_sg_ports = [
  {
    "port" : 22,
    "protocol" : "tcp"
  },
  {
    "port" : -1,
    "protocol" : "icmp"
  }
]
 