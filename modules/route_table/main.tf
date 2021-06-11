terraform {
  required_version = ">=0.13.4"

  required_providers {
    azurerm = ">=2.51.0"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_route_table" "route_table" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_route" "route" {
  for_each = {
    for route in var.routes :
    route.name => route
  }
  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.route_table.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_type == "VirtualAppliance" ? each.value.next_hop_in_ip_address : null
}
