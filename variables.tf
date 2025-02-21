# Define config variables
variable "label_prefix" {
  type        = string
  description = "Your college username. This will form the beginning of various resource names."
}

variable "region" {
  type        = string
  default     = "canadacentral"
  description = "The Azure region to deploy the resources to."
}

variable "admin_username" {
  type        = string
  default     = "azureadmin"
  description = "The username for the local user account on the VM."
}
