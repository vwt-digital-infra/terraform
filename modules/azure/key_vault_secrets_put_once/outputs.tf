output "secrets" {
  value = {
    for prop in values(resource.azurerm_key_vault_secret.secret)[*] :
    prop.name => {
      value = prop.value
      id    = prop.id
    }
  }
  sensitive = true
}