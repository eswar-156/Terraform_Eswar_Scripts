variable "location" {
  type = string
  description = "please enter location name"
}
variable "RG_1_name" {
  type = string
  default = "Rg-1"
}
variable "vnet_name" {
    type = string
    default = "Vnet_1"
  
}
variable "vnet_addr_space" {
    type = list
    default = ["10.0.0.0/16"]
  
}
variable "subnet_1_name" {
    type = string
    default = "subnet-1"
  
}
variable "snet_1_addr_pfx" {
    type = string
    default = "10.0.1.0/24"
  
}
variable "subnet_2_name" {
    type = string
    default = "subnet-2"
  
}
variable "snet_2_addr_pfx" {
    type = string
    default = "10.0.2.0/24"
  
}
variable "env_tag" {
    type = string
    default = "dummy"
  
}