variable "resource_group_name" {
  description = "GitHub 이슈에서 추출한 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리소스를 배포할 지역"
  type        = string
  default     = "Korea Central"
}

variable "base_name" {
  description = "기본 리소스 그룹 이름 접두사 (자동 넘버링이 필요할 경우)"
  type        = string
  default     = ""
}