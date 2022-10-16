# Create parent Resource Group to house resources
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.region
  tags     = var.tags
}

# Create Azure Router Server and Virtual VPN Gateway's vNet
resource "azurerm_virtual_network" "ars_vng" {
  name                = "ars-vng-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.10.0/24"]
  tags                = var.tags
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
  name                             = var.ars_name
  resource_group_name              = azurerm_resource_group.this.name
  location                         = azurerm_resource_group.this.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip.id
  subnet_id                        = azurerm_subnet.ars_subnet.id
  branch_to_branch_traffic_enabled = true
}

module "mc-transit-1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "2.3.0"
  cloud           = "Azure"
  region          = var.region
  cidr            = "10.0.20.0/23"
  account         = "azure-test-jye"
  local_as_number = 65020
  bgp_ecmp = true
  enable_bgp_over_lan = true
  resource_group = azurerm_resource_group.this.name
  name = "transit-1"
  insane_mode = true # The Azure Route Server integration is supported with Insane Mode enabled gateway only.
}

module "mc-transit-2" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "2.3.0"
  cloud           = "Azure"
  region          = var.region
  cidr            = "10.0.100.0/23"
  account         = "azure-test-jye"
  local_as_number = 65100
  bgp_ecmp = true
  resource_group = azurerm_resource_group.this.name
  name = "transit-2"
}

module "mc-spoke1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.4.1"
  cloud           = "Azure"
  region          = var.region
  cidr            = "10.0.30.0/24"
  account         = "azure-test-jye"
  transit_gw	 = module.mc-transit-1.transit_gateway.gw_name
  ha_gw = false
  name = "spoke1"
  # attached  = false
}

module "mc-spoke2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.4.1"
  cloud           = "Azure"
  region          = var.region
  cidr            = "10.0.110.0/24"
  account         = "azure-test-jye"
  transit_gw	 = module.mc-transit-2.transit_gateway.gw_name
  ha_gw = false
  name = "spoke2"
}


# Create two public IPs for VNG
resource "azurerm_public_ip" "vng_pip_1" {
  name                = "vng-pip-1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Dynamic"
}

resource "azurerm_public_ip" "vng_pip_2" {
  name                = "vng-pip-2"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.vng_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2"

  generation = "Generation2"

  bgp_settings {
    asn         = azurerm_route_server.ars.virtual_router_asn
    peer_weight = 0

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig1"
      apipa_addresses = [var.vng_primary_tunnel_ip]
    }
    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig2"
      apipa_addresses = [var.vng_ha_tunnel_ip]
    }
  }



  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.vng_pip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng_subnet.id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.vng_pip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng_subnet.id
  }
}




# Create Preshared Key for IPSec tunnels
resource "random_string" "psk" {
  length           = 40
  special          = false
}




resource "azurerm_local_network_gateway" "primary" {
  name                = module.mc-transit-2.transit_gateway.gw_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  gateway_address     = module.mc-transit-2.transit_gateway.public_ip
  bgp_settings {
    asn         = module.mc-transit-2.transit_gateway.local_as_number
    peer_weight = 0

    bgp_peering_address = var.avx_primary_tunnel_ip
  }
}

resource "azurerm_local_network_gateway" "ha" {
  name                = module.mc-transit-2.transit_gateway.ha_gw_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  gateway_address     = module.mc-transit-2.transit_gateway.ha_public_ip
  bgp_settings {
    asn         = module.mc-transit-2.transit_gateway.local_as_number
    peer_weight = 0

    bgp_peering_address = var.avx_ha_tunnel_ip
  }
}

resource "azurerm_virtual_network_gateway_connection" "primary" {
  name                = module.mc-transit-2.transit_gateway.gw_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.primary.id

  shared_key = random_string.psk.result
  enable_bgp = true
  ipsec_policy {
    ike_encryption = "AES256"
    ike_integrity = "SHA256"
    dh_group = "DHGroup14"
    ipsec_encryption = "AES256"
    ipsec_integrity = "SHA256"
    pfs_group = "None"
  }
  connection_mode = "ResponderOnly"
}

resource "azurerm_virtual_network_gateway_connection" "ha" {
  name                = module.mc-transit-2.transit_gateway.ha_gw_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.ha.id

  shared_key = random_string.psk.result
  enable_bgp = true
  ipsec_policy {
    ike_encryption = "AES256"
    ike_integrity = "SHA256"
    dh_group = "DHGroup14"
    ipsec_encryption = "AES256"
    ipsec_integrity = "SHA256"
    pfs_group = "None"
  }
  connection_mode = "ResponderOnly"
}


resource "aviatrix_transit_external_device_conn" "transit_2_to_vng" {
  vpc_id            = module.mc-transit-2.transit_gateway.vpc_id
  connection_name   = "${module.mc-transit-2.transit_gateway.gw_name}-to-${var.vng_name}"
  gw_name           = module.mc-transit-2.transit_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  enable_ikev2 = true
  bgp_local_as_num  = module.mc-transit-2.transit_gateway.local_as_number
  bgp_remote_as_num = var.vng_asn
  remote_gateway_ip = join(",", flatten(azurerm_virtual_network_gateway.this.bgp_settings[*].peering_addresses[*].tunnel_ip_addresses))
  local_tunnel_cidr = "${var.avx_primary_tunnel_ip}/30,${var.avx_ha_tunnel_ip}/30"
  remote_tunnel_cidr = "${var.vng_primary_tunnel_ip}/30,${var.vng_ha_tunnel_ip}/30"
  pre_shared_key = random_string.psk.result
  depends_on = [
    azurerm_virtual_network_peering.transit_1_to_vng,
    azurerm_virtual_network_peering.vng_to_transit_1
  ]
}


# Create vNet peering between VNG and Transit-11 Vnet
resource "azurerm_virtual_network_peering" "transit_1_to_vng" {
  name                      = "transit-1-to-vng"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.mc-transit-1.vpc.name
  remote_virtual_network_id = azurerm_virtual_network.ars_vng.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  use_remote_gateways = true
  depends_on = [
    azurerm_virtual_network_gateway.this
  ]
}

resource "azurerm_virtual_network_peering" "vng_to_transit_1" {
  name                      = "vng-to-spoke"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.ars_vng.name
  remote_virtual_network_id = module.mc-transit-1.vpc.azure_vnet_resource_id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = true
  depends_on = [
    azurerm_virtual_network_gateway.this
  ]
}



resource "aviatrix_transit_external_device_conn" "transit_1_to_ars" {
  vpc_id            = module.mc-transit-1.transit_gateway.vpc_id
  connection_name   = "${module.mc-transit-1.transit_gateway.gw_name}-to-${var.ars_name}"
  gw_name           = module.mc-transit-1.transit_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "LAN"
  
  remote_vpc_name          = "${azurerm_virtual_network.ars_vng.name}:${azurerm_virtual_network.ars_vng.resource_group_name}:${split("/",azurerm_virtual_network.ars_vng.id)[2]}"

  bgp_local_as_num  = module.mc-transit-1.transit_gateway.local_as_number
  bgp_remote_as_num = azurerm_route_server.ars.virtual_router_asn
  remote_lan_ip            = tolist(azurerm_route_server.ars.virtual_router_ips)[0]
  
  ha_enabled               = true
  backup_bgp_remote_as_num = azurerm_route_server.ars.virtual_router_asn
  backup_remote_lan_ip     = tolist(azurerm_route_server.ars.virtual_router_ips)[1]

  enable_bgp_lan_activemesh = true

}

resource "azurerm_route_server_bgp_connection" "ars_to_transit_1_primary" {
  name            = module.mc-transit-1.transit_gateway.gw_name
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = module.mc-transit-1.transit_gateway.local_as_number
  peer_ip         = aviatrix_transit_external_device_conn.transit_1_to_ars.local_lan_ip
}

resource "azurerm_route_server_bgp_connection" "ars_to_transit_1_hagw" {
  name            = module.mc-transit-1.transit_gateway.ha_gw_name
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = module.mc-transit-1.transit_gateway.local_as_number
  peer_ip         = aviatrix_transit_external_device_conn.transit_1_to_ars.backup_local_lan_ip
  depends_on = [
    azurerm_route_server_bgp_connection.ars_to_transit_1_primary
  ]
}


module "azure-linux-vm-public-spoke1" {
  source  = "jye-aviatrix/azure-linux-vm-public/azure"
  version = "2.0.0"
  public_key_file = var.public_key_file
  region = var.region
  resource_group_name = azurerm_resource_group.this.name
  subnet_id = module.mc-spoke1.vpc.public_subnets[0].subnet_id
  vm_name = "spoke1-test-vm"
}

module "azure-linux-vm-public-spoke2" {
  source  = "jye-aviatrix/azure-linux-vm-public/azure"
  version = "2.0.0"
  public_key_file = var.public_key_file
  region = var.region
  resource_group_name = azurerm_resource_group.this.name
  subnet_id = module.mc-spoke2.vpc.public_subnets[0].subnet_id
  vm_name = "spoke2-test-vm"
}

output "spoke1-test-vm" {
  value = module.azure-linux-vm-public-spoke1
}

output "spoke2-test-vm" {
  value = module.azure-linux-vm-public-spoke2
}