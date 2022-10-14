terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27.0"
    }
    # azurerm3 = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> 3.0.0"
    # }
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
    }
  }
}

provider "azurerm" {
  features {}
}

# provider "azurerm3" {
#   features {}
# }

provider "aviatrix" {}
