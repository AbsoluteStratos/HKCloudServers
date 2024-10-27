
variable "vm_name" {
  type        = string
  description = "VM Name to use"
  default     = "hollow-knight-server"
  sensitive   = true
}

variable "machine_type" {
  type        = string
  description = "Machine type to use for VM"
  default     = "t2.micro"
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