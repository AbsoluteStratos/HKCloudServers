
variable "vm_name" {
  type        = string
  description = "VM Name to use"
  default     = "hollow-knight-server"
  sensitive   = true
}

# https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#AMICatalog:
variable "ami" {
  type        = string
  description = "Amazon machine images for VM, default ubuntu"
  default     = "ami-0866a3c8686eaeeba"
  sensitive   = true
}


variable "machine_type" {
  type        = string
  description = "Machine type to use for VM"
  default     = "t2.micro"
  sensitive   = true
}

variable "key_pair" {
  type        = string
  description = "Key pair name credential to use"
  default     = "hkaws"
  sensitive   = true
}


variable "hkmp_port" {
  type        = number
  description = "Hollow-knight multi-player port"
  default     = 2222
}

variable "hkmw_port" {
  type        = number
  description = "Hollow-knight multi-world port"
  default     = 3333
}