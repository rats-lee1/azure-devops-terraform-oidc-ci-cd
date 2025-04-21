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
  use_oidc               = true
  client_id              = "49a5876d-cde1-4724-bad6-d267a5625804"
  tenant_id              = "03c374dc-f90f-458e-ba2b-d89b9422b208"
  subscription_id        = "d4adf5c4-07b2-48bf-9105-c296a8353411"
}

resource "azurerm_resource_group" "example" {
  name     = "rg-oidc-test"
  location = "eastus"  # 원하는 지역으로 변경하세요
  
  tags = {
    environment = "test"
    deployed_by = "terraform-oidc"
  }
}
