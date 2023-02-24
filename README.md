## Attach EFS volume to Multiple EC2 instances

```
#! /bin/bash
sudo yum update -y
sudo mkdir -p content/test/
sudo yum -y install amazon-efs-utils
#sudo su -c  "echo 'fs-02567aab704af0f76:/ content/test efs _netdev,tls,iam 0 0' >> /etc/fstab"
sudo su -c  "echo 'fs-02567aab704af0f76:/ content/test efs _netdev,tls 0 0' >> /etc/fstab"
sudo mount content/test/
df -k
```

```
file-system-id:/ efs-mount-point efs _netdev,tls,iam 0 0 

This appears to be an entry in the /etc/fstab file on a Linux system.

The entry specifies that the EFS (Elastic File System) should be mounted at a specific mount point (specified by "efs-mount-point"), with the file system ID being "file-system-id". The options specified for the mount include "_netdev" (which indicates that the filesystem is a network device and should not be mounted until the network is available), "tls" (which enables Transport Layer Security for data in transit), and "iam" (which enables the use of AWS Identity and Access Management (IAM) credentials for authentication).

The final "0 0" specifies the dump and file system check order options, respectively. A "0" for these options indicates that they should be skipped.
```