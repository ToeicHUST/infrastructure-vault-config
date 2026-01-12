output "environment_details" {
  description = "Thông tin đăng nhập AppRole cho từng môi trường"
  sensitive   = true
  value = {
    for env in var.environments : env.name => {
      path      = vault_generic_secret.app_config[env.name].path
      role_id   = vault_approle_auth_backend_role.app_role[env.name].role_id
      secret_id = vault_approle_auth_backend_role_secret_id.app_secret_id[env.name].secret_id
      
      # Tạo lệnh login CLI tiện dụng
      login_cli = "vault write auth/approle/login role_id=${vault_approle_auth_backend_role.app_role[env.name].role_id} secret_id=${vault_approle_auth_backend_role_secret_id.app_secret_id[env.name].secret_id}"
      
      # Tạo lệnh cURL tiện dụng
      login_curl = <<EOT
curl --location '${var.vault_address}/v1/auth/approle/login' \
--header 'Content-Type: application/json' \
--data '{ "role_id": "${vault_approle_auth_backend_role.app_role[env.name].role_id}", "secret_id": "${vault_approle_auth_backend_role_secret_id.app_secret_id[env.name].secret_id}" }'
EOT
    }
  }
}