# Configure the Terraform runtime requirements.
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.6-alpha1"
    }
  }

}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
  subscription_id = "d0681dfb-9589-4bb4-8dbd-11883649bebf"
}

provider "cloudinit" {
  # Configuration options
}
