terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatebithumbdev"
    container_name       = "tfstate"
    key                  = "terraform/dev/rg_dev_test/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Azure CLI를 통해 모든 리소스 그룹 이름 가져오기
data "external" "resource_groups" {
  program = [
    "bash", "-c",
    <<EOT
    echo '{"result": "'$(az group list --query "[].name" -o json | base64 -w 0)'"}'
    EOT
  ]
}


# 기존 리소스 그룹 목록을 확인하는 로컬 변수
locals {
  # 기본 리소스 그룹 이름
  base_rg_name = var.base_name
  
  # 모든 기존 리소스 그룹 이름 목록
  decoded_json = base64decode(data.external.resource_groups.result.result)
  existing_rg_names = jsondecode(local.decoded_json)  

  # 기본 이름으로 시작하는 리소스 그룹 필터링
  matching_rgs = [
    for name in local.existing_rg_names : 
    name if length(regexall("^${local.base_rg_name}(-[0-9]+)?$", name)) > 0
  ]
  
  # 숫자 접미사가 있는 리소스 그룹들만 필터링 (예: rg-oidc-test-1)
  numbered_rgs = [
    for name in local.matching_rgs : 
    tonumber(replace(name, "${local.base_rg_name}-", ""))
    if length(regexall("^${local.base_rg_name}-[0-9]+$", name)) > 0
  ]
  
  # 최대 번호 찾기 (존재하면 최대값+1, 없으면 1)
  max_number = length(local.numbered_rgs) > 0 ? max(local.numbered_rgs...) + 1 : 1
  
  # 기본 이름이 이미 존재하면 숫자 접미사 붙이기
  rg_name = contains(local.existing_rg_names, local.base_rg_name) ? "${local.base_rg_name}-${local.max_number}" : local.base_rg_name
}

# 디버깅 출력
output "existing_resource_groups" {
  value = local.existing_rg_names
}

output "matching_resource_groups" {
  value = local.matching_rgs
}

output "numbered_resource_groups" {
  value = local.numbered_rgs
}

output "max_number" {
  value = local.max_number
}

# 리소스 그룹 생성
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