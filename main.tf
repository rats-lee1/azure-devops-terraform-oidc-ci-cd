provider "azurerm" {
  features {}
}

# 리소스 그룹 생성
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = "Korea Central"
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = replace(var.resource_group_name, "rg-", "")
  }
}

# =====================================================
# RBAC (사용자 권한 관리) 로직
# =====================================================

# 사용자 이메일 추출
locals {
  user_emails = [for user in var.user_list : split(":", user)[1]]
  
  # GPU 크기별 할당량 매핑
  gpu_quotas = {
    "Tiny"    = 4
    "Small"   = 8
    "Medium"  = 16
    "Large"   = 24
    "XLarge"  = 32
    "해당 없음" = 0
  }
  gpu_quota = lookup(local.gpu_quotas, var.gpu_size, 0)
}

# 사용자별 역할 할당
resource "azurerm_role_assignment" "user_contributor" {
  for_each             = toset(local.user_emails)
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = each.value
}

# =====================================================
# GPU 정책 설정 로직
# =====================================================

# GPU 할당량 정책 설정
resource "azurerm_policy_assignment" "gpu_quota" {
  count                = local.gpu_quota > 0 ? 1 : 0
  name                 = "gpu-quota-policy"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/5c99bc60-3bcd-475f-b420-5a4abe6eaec4" # 가상 정책 ID (실제 ID로 대체 필요)
  parameters           = jsonencode({
    gpuQuotaValue = {
      value = local.gpu_quota
    }
  })
}

# 출력값 정의
output "resource_group_id" {
  value = azurerm_resource_group.main.id
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "assigned_users" {
  value = local.user_emails
}

output "gpu_quota" {
  value = local.gpu_quota
}