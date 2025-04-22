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

# 구독 내의 모든 리소스 그룹 조회
data "azurerm_resources" "existing_resource_groups" {
  type = "Microsoft.Resources/resourceGroups"
}

locals {
  # 기본 리소스 그룹 이름
  base_rg_name = "rg-oidc-test"
  
  # 모든 리소스 그룹 이름 추출
  existing_rg_names = [for rg in data.azurerm_resources.existing_resource_groups.resources : rg.name]
  
  # 이름이 기본 이름으로 시작하는 리소스 그룹 찾기
  matching_rgs = [for name in local.existing_rg_names : name if startswith(name, local.base_rg_name)]
  
  # 기본 이름이 존재하지 않으면 그대로 사용, 존재하면 숫자 부여
  rg_name = contains(local.existing_rg_names, local.base_rg_name) ? (
    # 기존 이름으로 시작하는 리소스 그룹 이름에서 최대 숫자 찾기
    length(local.matching_rgs) > 0 ? (
      "${local.base_rg_name}-${length(local.matching_rgs) + 1}"
    ) : "${local.base_rg_name}-1"
  ) : local.base_rg_name
}

resource "azurerm_resource_group" "example" {
  name     = local.rg_name
  location = "eastus"
  
  tags = {
    environment = "test"
    deployed_by = "terraform-oidc"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.example.name
  description = "생성된 리소스 그룹의 이름"
}