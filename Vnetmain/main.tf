terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-tf-001"
  location = "West Europe"
}

resource "azurerm_resource_group" "example-2" {
  name     = "rg-tf-002"
  location = "West Europe"
}

resource "azurerm_network_security_group" "example" {
  name                = "nsg-tf-001"
  location            = azurerm_resource_group.example-2.location
  resource_group_name = azurerm_resource_group.example-2.name
}

resource "azurerm_network_security_group" "example-2" {
  name                = "nsg-tf-002"
  location            = azurerm_resource_group.example-2.location
  resource_group_name = azurerm_resource_group.example-2.name
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-tf-001"
  location            = azurerm_resource_group.example-2.location
  resource_group_name = azurerm_resource_group.example-2.name
  address_space       = ["10.0.0.0/16","102.168.0.0/16"]
  #  The address space that is used the virtual network. You can supply more than one address space.
  # [] this is called an Array we can use multiple address

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.example.id
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.example-2.id
  }

  tags = {
    environment = "Production"
  }
}
  