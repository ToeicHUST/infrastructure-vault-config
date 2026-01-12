terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

# 1. KV Engine (Dùng chung)
resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  options     = { version = "1" }
  description = "KV storage"
}

# 2. AppRole Auth Backend (Dùng chung)
resource "vault_auth_backend" "approle" {
  type = "approle"
  path = "approle"
}

# --- XỬ LÝ VÒNG LẶP ---

locals {
  # Chuyển đổi List sang Map để dùng cho_each. Key sẽ là "name" (dev, prod...)
  # Cấu trúc map: { "dev" = {name="dev", data={...}}, "prod" = {...} }
  env_map = { for item in var.environments : item.name => item }
}

# 3. Tạo Secret cho từng môi trường
resource "vault_generic_secret" "app_config" {
  for_each = local.env_map

  depends_on = [vault_mount.kv]
  # Path: secret/dev/config
  path       = "${vault_mount.kv.path}/${each.value.name}/config"
  data_json  = jsonencode(each.value.data)
}

# 4. Tạo Policy cho từng môi trường (Chỉ đọc đúng path của nó)
resource "vault_policy" "app_policy" {
  for_each = local.env_map

  name = "${each.value.name}-read"
  policy = <<EOT
path "${vault_mount.kv.path}/${each.value.name}/config" {
  capabilities = ["read"]
}
EOT
}

# 5. Tạo AppRole cho từng môi trường
resource "vault_approle_auth_backend_role" "app_role" {
  for_each = local.env_map

  backend        = vault_auth_backend.approle.path
  role_name      = each.value.name
  token_policies = [vault_policy.app_policy[each.key].name]
  token_ttl      = 3600
  token_max_ttl  = 14400
}

# 6. Tạo Secret ID cho AppRole
resource "vault_approle_auth_backend_role_secret_id" "app_secret_id" {
  for_each = local.env_map

  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.app_role[each.key].role_name
}