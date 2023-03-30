variable "aws_region" {

  default = "ap-southeast-2"
}

variable "image_tag" {
  default = "latest"
}
variable "image_repo_url" {
  default = "982469757400.dkr.ecr.ap-southeast-2.amazonaws.com/flask-demo-2"
}

/*
variable "private-subnet" {
  sub1 = {subnet1 = "10.0.2.0/24"}
  sub2 = {subnet2 = "10.0.3.0/24"}
}
*/

variable "vpc_subnets" {
  type = map(object({
    
    cidr       = optional(string)
    av_z       = optional(string)
    #appid       = optional(string)
    
  }))
}

variable "aws_account_id" {
  type = string
  default = "982469757400"
}

variable "image_repo_name" {
  type = string
  default = "flask-demo-2"
}

variable "github_repo_name" {
  type = string
  default = "github-actions"
}

variable "github_repo_owner" {
  type = string
  default = "nagaripratap"
}

variable "github_branch" {
  type = string
  default = "main"
}
