#! /bin/bash
sudo yum update -y
sudo mkdir -p content/test/
sudo yum -y install amazon-efs-utils
sudo su -c  "echo 'fs-0325af0dd03ee80bf:/ content/test/ efs _netdev,tls 0 0' >> /etc/fstab"
sudo mount content/test/
df -k

