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

variable "rg_name" {
  type = string
  # type - This argument specifies what value types are accepted for the variable.
  # string: a sequence of Unicode characters representing some text, like "hello"
  description = "Name of the resource group"
  default = "rg-dev-01"
}

variable "location" {
  type = string
  description = "Location to create azure resource"
  default = "EastUS"
}

variable "nsg_name" {
  type = string
  description = "name of nsg"
  default = "nsg-dev-01"
}

variable "vnet_name" {
  type = string
  description = "name of the Vnet"
  default = "vnet-dev-01"
}

variable "vnet_addr_space" {
  type = list
  # list (or tuple): a sequence of values, like ["us-west-1a", "us-west-1c"]. Elements in a list or tuple are identified by consecutive whole numbers, starting with zero.
  description = "Add address spaces"
  default = ["10.0.0.0/16","102.168.0.0/16"]
}

variable "subnet_name" {
  type = string
  description = "name of the subnet"
  default = "subnet1"
}

variable "subnet_addr_space" {
  type = string
  description = "Address prefix for subnet-1"
  default = "10.0.1.0/24"
}


resource "azurerm_resource_group" "example" {
  name     = var.rg_name
  location = var.location
}


resource "azurerm_network_security_group" "example" {
  name                = var.nsg_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}


resource "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = var.vnet_addr_space
  #  The address space that is used the virtual network. You can supply more than one address space.
  # [] this is called an Array we can use multiple address

  subnet {
    name           = var.subnet_name
    address_prefix = var.subnet_addr_space
    security_group = azurerm_network_security_group.example.id
  }
  
}
