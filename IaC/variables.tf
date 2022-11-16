variable "public_subnets" {
  type = list
  default = ["172.16.1.0/28", "172.16.1.16/28", "172.16.1.32/28"]
}


variable "private_subnets" {
  type = list
  default = ["172.16.1.48/28", "172.16.1.64/28", "172.16.1.80/28"]
}

variable "subnets_availability_zones" {
  type = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_name" {
  type = string
  default = "letscode_db"
}

variable "db_user" {
  type = string
  default = "letscode"
}

variable "db_password" {
  type = string
  default = "7ROtBB44*0XN"
}