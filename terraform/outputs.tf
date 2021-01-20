output "acr_id" {
  value = module.container_registry[0].acr_id
}

output "acr_login_server" {
  value = module.container_registry[0].acr_login_server
}
