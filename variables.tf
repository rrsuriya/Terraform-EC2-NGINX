variable "instance_type" {
  default = "t2.micro"
}

variable "east_key_name" {
  description = "Key Pair name for us-east-1"
  default     = "us-east-1-key-pair"
}

variable "west_key_name" {
  description = "Key Pair name for us-west-2"
  default     = "us-west-2-key-pair"
}
