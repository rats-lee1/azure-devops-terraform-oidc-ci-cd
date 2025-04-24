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
  # backend "azurerm" {
  #   # resource_group_name  = "terraform-state-rg"
  #   # storage_account_name = "tfstatebithumbdev"
  #   # container_name       = "tfstate"
  #   # key                  = "terraform/dev/rg_dev_test/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# Azure CLI를 통해 모든 리소스 그룹 이름 가져오기 (기존 로직은 유지하지만 조건부로 실행)
data "external" "resource_groups" {
  count = var.base_name != "" ? 1 : 0
  program = [
    "bash", "-c",
    <<EOT
    echo '{"result": "'$(az group list --query "[].name" -o json | base64 -w 0)'"}'
    EOT
  ]
}

# 기존 리소스 그룹 목록을 확인하는 로컬 변수
locals {
  # 자동 생성 로직 사용 여부 결정
  use_auto_naming = var.base_name != ""
  
  # 자동 생성 로직을 사용할 경우만 아래 로직 실행
  decoded_json    = local.use_auto_naming ? base64decode(data.external.resource_groups[0].result.result) : "[]"
  existing_rg_names = local.use_auto_naming ? jsondecode(local.decoded_json) : []
  
  # 기본 이름으로 시작하는 리소스 그룹 필터링
  base_rg_name = local.use_auto_naming ? var.base_name : ""
  
  matching_rgs = local.use_auto_naming ? [
    for name in local.existing_rg_names : 
    name if length(regexall("^${local.base_rg_name}(-[0-9]+)?$", name)) > 0
  ] : []
  
  # 숫자 접미사가 있는 리소스 그룹들만 필터링
  numbered_rgs = local.use_auto_naming ? [
    for name in local.matching_rgs : 
    tonumber(replace(name, "${local.base_rg_name}-", ""))
    if length(regexall("^${local.base_rg_name}-[0-9]+$", name)) > 0
  ] : []
  
  # 최대 번호 찾기
  max_number = local.use_auto_naming && length(local.numbered_rgs) > 0 ? max(local.numbered_rgs...) + 1 : 1
  
  # 최종 리소스 그룹 이름 결정
  # 1. use_auto_naming이 true이고 기본 이름이 이미 존재하면 숫자 접미사 붙이기
  # 2. use_auto_naming이 true이지만 기본 이름이 존재하지 않으면 기본 이름 사용
  # 3. use_auto_naming이 아니면 워크플로우에서 받은 resource_group_name 사용
  final_rg_name = local.use_auto_naming ? (
    contains(local.existing_rg_names, local.base_rg_name) ? 
    "${local.base_rg_name}-${local.max_number}" : local.base_rg_name
  ) : var.resource_group_name
}

# 리소스 그룹 생성
resource "azurerm_resource_group" "example" {
  name     = local.final_rg_name
  location = var.location
  
  tags = {
    environment = "test"
    deployed_by = "terraform-oidc"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
  }
}

# 디버깅용 출력
output "existing_resource_groups" {
  value = local.use_auto_naming ? local.existing_rg_names : ["Auto-naming disabled"]
}

output "matching_resource_groups" {
  value = local.use_auto_naming ? local.matching_rgs : ["Auto-naming disabled"]
}

output "numbered_resource_groups" {
  value = local.use_auto_naming ? local.numbered_rgs : ["Auto-naming disabled"]
}

output "max_number" {
  value = local.max_number
}

# 생성된 리소스 그룹 이름 출력
output "resource_group_name" {
  value = azurerm_resource_group.example.name
  description = "생성된 리소스 그룹의 이름"
}