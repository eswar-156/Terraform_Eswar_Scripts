  terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.0.2"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}


resource "azurerm_resource_group" "RG_5" {
  name     = var.RG_1_name
  location = var.location
  tags = {
    "automation" = "dailycleanup"
  }
}


resource "azurerm_virtual_network" "vnet_1" {
  name                = var.vnet_name
  location            = azurerm_resource_group.RG_5.location
  resource_group_name = azurerm_resource_group.RG_5.name
  address_space       = var.vnet_addr_space


  subnet {
    name           = var.subnet_1_name
    address_prefix = var.snet_1_addr_pfx
  }

  subnet {
    name           = var.subnet_2_name
    address_prefix = var.snet_2_addr_pfx
    
  }

  tags = {
    environment = var.env_tag
  }
}