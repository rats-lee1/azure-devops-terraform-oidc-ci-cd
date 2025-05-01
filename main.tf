provider "azurerm" {
  features {}
  subscription_id = "d4adf5c4-07b2-48bf-9105-c296a8353411"
}

provider "azuread" {
  # AzureAD 공급자 설정
  # Azure CLI 로그인과 동일한 인증 정보를 사용합니다
}

# 리소스 그룹 생성
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = "Korea Central"
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = replace(var.resource_group_name, "rg-", "")
    GPUQuota    = var.gpu_size != "0" ? var.gpu_size : "0"
  }
}

# =====================================================
# RBAC (사용자 권한 관리) 로직
# =====================================================

locals {
  # GPU 쿼터는 이제 var.gpu_size를 직접 사용 (이미 숫자만 포함)
  gpu_quota = tonumber(var.gpu_size)
}

# Azure AD 사용자 조회
data "azuread_user" "users" {
  for_each = toset(var.user_list)
  mail     = each.value
}

# 사용자별 역할 할당
resource "azurerm_role_assignment" "user_contributor" {
  for_each             = data.azuread_user.users
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = each.value.object_id
}

# =====================================================
# GPU 정책 설정 로직 (메타데이터 태그 방식으로 변경)
# =====================================================

# GPU 할당량을 리소스 그룹 태그로 설정 (정책 대신)
resource "azurerm_resource_group_policy_assignment" "gpu_quota" {
  count                = local.gpu_quota > 0 ? 1 : 0
  name                 = "gpu-quota-policy"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = "/subscriptions/d4adf5c4-07b2-48bf-9105-c296a8353411/providers/Microsoft.Authorization/policyDefinitions/a5121561-90f0-445c-a41a-a96602c862ad"
  
  parameters = jsonencode({
    "effect": {
      "value": "Deny"
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
  value = var.user_list
}

output "gpu_quota" {
  value = local.gpu_quota
}