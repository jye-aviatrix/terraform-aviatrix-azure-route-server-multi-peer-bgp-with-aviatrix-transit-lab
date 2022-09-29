resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.region
}

resource "azurerm_virtual_network" "ars_vng" {
  name                = "ars-vng-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.10.0/24"]

  subnet {
    name           = "RouteServerSubnet"
    address_prefix = "10.0.10.0/25"
  }

  subnet {
    name           = "GatewaySubnet"
    address_prefix = "10.0.10.128/25"
  }

  tags = {
    environment = "Production"
  }
}