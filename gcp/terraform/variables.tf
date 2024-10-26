
variable "project" {
  type        = string
  description = "Name of the GCP project to use"
  default     = "default-project"
  sensitive   = true
}

variable "username" {
  type        = string
  description = "Google account user name"
  default     = "root"
  sensitive   = true
}

variable "vm_name" {
  type        = string
  description = "VM Name to use"
  default     = "hollow-knight-server"
  sensitive   = true
}

variable "machine_type" {
  type        = string
  description = "Machine type to use for VM"
  default     = "e2-micro"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Compute region"
  default     = "us-central1"
  sensitive   = true
}

variable "zone" {
  type        = string
  description = "Compute zone"
  default     = "c"
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

variable "credential_file" {
  type        = string
  description = "GCP account credential file obtained using `gcloud auth application-default login`"
  default     = "credentials.json"
}