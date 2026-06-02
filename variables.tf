variable "instance_name" {
  description = "The name of the instance to create."
  type        = string
    default     = "learn-terraform"
}

variable "instance_type" {
  description = "The EC2 instance's type."
  type        = string
    default     = "t2.micro"
}
