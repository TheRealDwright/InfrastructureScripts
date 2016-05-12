#--------------------------------------------------------------
# AWS settings
#--------------------------------------------------------------
variable "access_key" {
  description = "AWS access key"
}
variable "secret_key" {
  description = "AWS secret access key"
}
/* AWS VPC Subnet Variables */
variable "region"     {
  description = "AWS region to host your network"
  default     = "us-west-2"
}

variable "availability_zone_1" {
  description = "AWS region to host your network"
  default     = "us-west-2a"
}

variable "availability_zone_2" {
  description = "AWS region to host your network"
  default     = "us-west-2b"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.120.0.0/16"
}
variable "public_subnet_cidr_1" {
  description = "CIDR for public subnet"
  default     = "10.120.1.0/24"
}
variable "public_subnet_cidr_2" {
  description = "CIDR for public subnet"
  default     = "10.120.2.0/24"
}
variable "private_subnet_cidr_1" {
  description = "CIDR for private subnet"
  default     = "10.120.4.0/22"
}
variable "private_subnet_cidr_2" {
  description = "CIDR for private subnet"
  default     = "10.120.8.0/22"
}
variable "db_subnet_cidr_1" {
  description = "CIDR for db subnet"
  default     = "10.120.200.0/22"
}
variable "db_subnet_cidr_2" {
  description = "CIDR for db subnet"
  default     = "10.120.210.0/22"
}
/* Ubuntu 14.04 amis by region */
variable "amis" {
  description = "Base AMI to launch the instances with"
  default = {
    us-west-1 = "ami-06116566"
    us-west-2 = "ami-9abea4fb"
  }
}
