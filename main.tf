terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
  
  # 필요하다면 여기에 백엔드 구성 추가
  # backend "azurerm" {
  #   resource_group_name  = "tfstate"
  #   storage_account_name = "<storage_account_name>"
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  #   use_oidc             = true
  # }
}

provider "azurerm" {
  features {}
  # 환경 변수에서 자동으로 OIDC 토큰을 가져오므로 여기서 명시적 설정은 필요 없음
  # use_oidc, client_id 등은 생략 가능 (GitHub Actions에서 환경 변수로 설정)
}

resource "azurerm_resource_group" "example" {
  name     = "rg-oidc-test"
  location = "eastus"
  
  tags = {
    environment = "test"
    deployed_by = "terraform-oidc"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
  }
}