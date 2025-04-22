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
}

# Azure CLI를 사용하여 모든 리소스 그룹 이름 가져오기
data "external" "resource_groups" {
  program = ["bash", "-c", "az group list --query \"[].name\" -o json | jq -r '{resource_groups: .}'"]
}

locals {
  # 기본 리소스 그룹 이름
  base_rg_name = "rg-oidc-test"
  
  # 모든 기존 리소스 그룹 이름 목록
  existing_rg_names = jsondecode(data.external.resource_groups.result.resource_groups)
  
  # 기본 이름으로 시작하는 리소스 그룹 필터링
  matching_rgs = [for name in local.existing_rg_names : name if startswith(name, local.base_rg_name)]
  
  # 숫자 버전이 있는 경우 (예: rg-oidc-test-1) 가장 큰 숫자 찾기
  numbered_rgs = [for name in local.matching_rgs : 
    tonumber(replace(name, "${local.base_rg_name}-", "")) 
    if length(regexall("^${local.base_rg_name}-[0-9]+$", name)) > 0
  ]
  
  # 최대 숫자 계산 (있으면 최대값+1, 없으면 1)
  max_number = length(local.numbered_rgs) > 0 ? max(local.numbered_rgs...) + 1 : 1
  
  # 최종 리소스 그룹 이름 결정
  rg_name = contains(local.existing_rg_names, local.base_rg_name) ? "${local.base_rg_name}-${local.max_number}" : local.base_rg_name
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