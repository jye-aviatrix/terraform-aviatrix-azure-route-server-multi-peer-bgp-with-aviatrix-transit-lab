# Create parent Resource Group to house resources
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.region
  tags = var.tags
}

# Create Azure Router Server and Virtual VPN Gateway's vNet
resource "azurerm_virtual_network" "ars_vng" {
  name                = "ars-vng-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.10.0/24"]
  tags = var.tags

#   subnet {
#     name           = "RouteServerSubnet"
#     address_prefix = "10.0.10.0/25"
#   }

#   subnet {
#     name           = "GatewaySubnet"
#     address_prefix = "10.0.10.128/25"
#   }
}

# Create Subnet for Azure Route Server
resource "azurerm_subnet" "ars_subnet" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.ars_vng.name
  address_prefixes     = ["10.0.10.0/25"]
}

# Create Subnet for Virtual Private Gateway
resource "azurerm_subnet" "vng_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.ars_vng.name
  address_prefixes     = ["10.0.10.128/25"]
}

# Create public IP for Azure Route Server
resource "azurerm_public_ip" "ars_pip" {
  name                = "ars-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Azure Route Server
resource "azurerm_route_server" "ars" {
  name                             = "routerserver"
  resource_group_name              = azurerm_resource_group.this.name
  location                         = azurerm_resource_group.this.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip.id
  subnet_id                        = azurerm_subnet.ars_subnet.id
  branch_to_branch_traffic_enabled = true
}