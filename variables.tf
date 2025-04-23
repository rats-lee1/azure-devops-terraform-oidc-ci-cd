variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "eastus"
}

variable "base_name" {
  description = "리소스 이름의 기본 부분"
  type        = string
  default     = "rg-oidc-test"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}