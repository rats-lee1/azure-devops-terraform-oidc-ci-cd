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

# Azure 리소스 그룹 목록 가져오기
data "azurerm_resources" "all_resource_groups" {
  type = "Microsoft.Resources/resourceGroups"
}

locals {
  # 기본 리소스 그룹 이름
  base_rg_name = var.base_name
  
  # 모든 기존 리소스 그룹 이름 목록
  existing_rg_names = [for rg in data.azurerm_resources.all_resource_groups.resources : rg.name]
  
  # 기본 이름으로 시작하는 리소스 그룹 필터링 (startswith 대신 substr 사용)
  matching_rgs = [for name in local.existing_rg_names : name if substr(name, 0, length(local.base_rg_name)) == local.base_rg_name]
  
  # 숫자 버전이 있는 경우 (예: rg-oidc-test-1) 가장 큰 숫자 찾기
  numbered_rgs = [
    for name in local.matching_rgs : 
    tonumber(replace(name, "${local.base_rg_name}-", ""))
    if length(regexall("^${local.base_rg_name}-[0-9]+$", name)) > 0
  ]
  
  # 최대 숫자 계산 (있으면 최대값+1, 없으면 1)
  max_number = length(local.numbered_rgs) > 0 ? max(local.numbered_rgs...) + 1 : 1
  
  # 최종 리소스 그룹 이름 결정 - 기존 리소스 그룹이 이미 있으면 숫자가 붙은 이름 사용
  rg_name = contains(local.existing_rg_names, local.base_rg_name) ? "${local.base_rg_name}-${local.max_number}" : local.base_rg_name
}
resource "azurerm_resource_group" "example" {
  name     = local.rg_name
  location = var.location
  
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