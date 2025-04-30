# 변수 정의
variable "resource_group_name" {
  description = "배포할 리소스 그룹 이름"
  type        = string
}

variable "user_list" {
  description = "접근 권한을 부여할 사용자 목록"
  type        = list(string)
  default     = []
}

variable "gpu_size" {
  description = "필요한 GPU 크기"
  type        = string
  default     = "해당 없음"
}

variable "environment" {
  description = "배포 환경"
  type        = string
  default     = "개발(Development)"
}