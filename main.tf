terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc       = true
  client_id      = "49a5876d-cde1-4724-bad6-d267a5625804"
}

resource "azurerm_resource_group" "example" {
  name     = "rg-oidc-test"
  location = "eastus"
  
  tags = {
    environment = "test"
    deployed_by = "terraform-oidc"
  }
}