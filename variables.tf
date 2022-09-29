variable "resource_group_name" {
  type = string
  description = "Provide Resource Group Name"
}

variable "region" {
  type = string
  description = "Provide region of the resources"
}

variable "tags" {
  type = map
  description = "Provide tags for resources"
  default = {
    Name = "ars-multi-peer-bgp-with-avx-transit-lab"
  }
}