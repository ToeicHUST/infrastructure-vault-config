variable "vault_address" {
  description = "Địa chỉ Vault Server"
  type        = string
}

variable "vault_token" {
  description = "Root token Vault"
  type        = string
  sensitive   = true
}

variable "environments" {
  description = "Danh sách các môi trường và dữ liệu cấu hình"
  type = list(object({
    name = string # Ví dụ: dev, prod, staging
    data = any    # Dữ liệu JSON/Map bên trong
  }))
}