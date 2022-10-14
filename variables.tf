variable "resource_group_name" {
  type = string
  description = "Provide Resource Group Name"
  default = "ars-bgp-multipeer-avx-transit-lab"
}

variable "region" {
  type = string
  description = "Provide region of the resources"
  default = "East US"
}

variable "tags" {
  type = map
  description = "Provide tags for resources"
  default = {
    Name = "ars-multi-peer-bgp-with-avx-transit-lab"
  }
}

variable "ars_name" {
  type = string
  description = "Provide Azure Route Server name"
  default = "routerserver"
}

variable "vng_name" {
  type = string
  description = "Provide Azure VPN Gateway Name"
  default = "vng"
}

variable "vng_asn" {
  type = number
  description = "Provide ASN for Azure VPN Gateway"
  default = 65010  
}


variable "vng_primary_tunnel_ip" {
  type = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default = "169.254.21.1"
}

variable "vng_ha_tunnel_ip" {
  type = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default = "169.254.22.1"
}

variable "avx_primary_tunnel_ip" {
  type = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default = "169.254.21.2"
}

variable "avx_ha_tunnel_ip" {
  type = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default = "169.254.22.2"
}

variable "public_key_file" {
  type = string
  description = "Provide the path to the test instance's SSH public key"
}