variable "instance_type" {
  description = "Name of the project"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
  default     = "aws_access_key"
}

variable "instance_count" {
  description = "Number of instance"
  type        = number
  default     = 2
}

variable "private_key_location" {
  description = "Location of the private key"
  type        = string
  default     = "/Users/shamimmd/.ssh/aws_access_key.pem"
}

variable "public_instance_sg_ports" {

  description = "Define the ports and protocols for instance the security group"
  type        = list(any)
  default = [
    {
      "port" : 22,
      "protocol" : "tcp"
    },
  ]
}

variable "efs_sg_ports" {

  description = "Define the ports and protocols for efs the security group"
  type        = list(any)
  default = [
    {
      "port" : 2049,
      "protocol" : "tcp"
    },
  ]
}

variable "efs_mount_point" {
  description = "Define the ports and protocols for efs the security group"
  type        = string
  default     = "content/test/"
}
