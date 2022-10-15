# terraform-aviatrix-azure-route-server-multi-peer-bgp-with-aviatrix-transit-lab

This module create a lab environment, intergrating Azure Router Server with Aviatrix Transit via BGP multi-peer. Then use VPN Gateway to establish BGP over IPSec connection with OnPrem to exchange routes


## Tested environment
- Terraform v1.2.8
- provider registry.terraform.io/aviatrixsystems/aviatrix v2.24.1
- provider registry.terraform.io/hashicorp/azurerm v3.27.0
- provider registry.terraform.io/hashicorp/http v3.1.0
- provider registry.terraform.io/hashicorp/random v3.4.3

## Cost estimate
```
 Name                                                                           Monthly Qty  Unit                      Monthly Cost 
                                                                                                                     

 azurerm_public_ip.ars_pip                                                                                           

 └─ IP address (static)                                                                 730  hours                   
         $3.65
                                                                                                                     

 azurerm_public_ip.vng_pip_1                                                                                         

 └─ IP address (dynamic)                                                                730  hours                   
         $2.92
                                                                                                                     

 azurerm_public_ip.vng_pip_2                                                                                         

 └─ IP address (dynamic)                                                                730  hours                   
         $2.92
                                                                                                                     

 azurerm_virtual_network_gateway.this                                                                                

 ├─ VPN gateway (VpnGw2)                                                                730  hours                   
       $357.70
 ├─ VPN gateway P2S tunnels (over 128)                                   Monthly cost depends on usage: $7.30 per tunnel
 └─ VPN gateway data tranfer                                             Monthly cost depends on usage: $0.035 per GB

                                                                                                                     

 azurerm_virtual_network_gateway_connection.ha                                                                       

 └─ VPN gateway (VpnGw2)                                                                730  hours                   
        $10.95
                                                                                                                     

 azurerm_virtual_network_gateway_connection.primary                                                                  

 └─ VPN gateway (VpnGw2)                                                                730  hours                   
        $10.95
                                                                                                                     

 azurerm_virtual_network_peering.transit_1_to_vng                                                                    

 ├─ Inbound data transfer                                                Monthly cost depends on usage: $0.01 per GB 

 └─ Outbound data transfer                                               Monthly cost depends on usage: $0.01 per GB 

                                                                                                                     

 azurerm_virtual_network_peering.vng_to_transit_1                                                                    

 ├─ Inbound data transfer                                                Monthly cost depends on usage: $0.01 per GB 
               
 └─ Outbound data transfer                                               Monthly cost depends on usage: $0.01 per GB 

                                                                                                                     

 module.azure-linux-vm-public-spoke1.azurerm_linux_virtual_machine.this                                              

 ├─ Instance usage (pay as you go, Standard_B1s)                                        730  hours                   
         $7.59
 └─ os_disk                                                                                                          

    ├─ Storage (S4)                                                                       1  months                  
         $1.54
    └─ Disk operations                                                   Monthly cost depends on usage: $0.0005 per 10k operations
                                                                                                                     

 module.azure-linux-vm-public-spoke1.azurerm_public_ip.this                                                          

 └─ IP address (static)                                                                 730  hours                   
         $2.63
                                                                                                                     

 module.azure-linux-vm-public-spoke2.azurerm_linux_virtual_machine.this                                              

 ├─ Instance usage (pay as you go, Standard_B1s)                                        730  hours                   
         $7.59
 └─ os_disk                                                                                                          

    ├─ Storage (S4)                                                                       1  months                  
         $1.54
    └─ Disk operations                                                   Monthly cost depends on usage: $0.0005 per 10k operations
                                                                                                                     

 module.azure-linux-vm-public-spoke2.azurerm_public_ip.this                                                          

 └─ IP address (static)                                                                 730  hours                   
         $2.63
                                                                                                                     

 OVERALL TOTAL                                                                                                       
       $412.60
```

## reference
- [Azure Route Server support for ExpressRoute and Azure VPN](https://learn.microsoft.com/en-us/azure/route-server/expressroute-vpn-support)