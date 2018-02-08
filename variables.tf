#

variable "environment" {
  default = "mydemo"
}

variable "opsman_image" {
}

variable "network_infrastructure" {
  default = "192.168.101.0/26"
}

variable "network_services" {
  default = "192.168.20.0/22"
}

variable "network_main" {
  default = "192.168.16.0/26"
}

# GCP Settings

variable "project" {
}

variable "region" {
  default = "us-central1"
}

variable "zones" {
  default = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

# will create a set of external IPs based on the provided names
variable "external_ips" {
  default = ["lb"]
}