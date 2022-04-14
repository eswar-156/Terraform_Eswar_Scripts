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
  features {
    
  }
}

resource "azurerm_resource_group" "rg-dev" {
  name     = "rg-myvec-dev-eus-001"
  location = "EastUS"
}

resource "azurerm_virtual_network" "vnet-dev" {
  name                = "vnet-myvec-dev-eus-001"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name
  address_space       = ["10.0.0.0/16"]  
  depends_on = [
    azurerm_resource_group.rg-dev
  ]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = azurerm_resource_group.rg-dev.name
  virtual_network_name = azurerm_virtual_network.vnet-dev.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [
    azurerm_virtual_network.vnet-dev
  ]
}

// This interface is for vm1-myvec-dev-eus-001

resource "azurerm_network_interface" "nic-1" {
  name                = "nic-myvec-dev-eus-001"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.vnet-dev,
    azurerm_subnet.SubnetA
  ]
}

// This interface is for vm1-myvec-dev-eus-002

resource "azurerm_network_interface" "nic-2" {
  name                = "nic-myvec-dev-eus-002"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.vnet-dev,
    azurerm_subnet.SubnetA
  ]
}

// This is the resource for vm1-myvec-dev-eus-001

resource "azurerm_windows_virtual_machine" "vm1-dev" {
  name                = "vm1-myvec-dev-eus-001"
  resource_group_name = azurerm_resource_group.rg-dev.name
  location            = azurerm_resource_group.rg-dev.location
  size                = "Standard_D2s_v3"
  computer_name       = "vm1-dev-001"
  admin_username      = "eswar"
  admin_password      = "Azure@123"
  availability_set_id = azurerm_availability_set.avset-dev.id
  network_interface_ids = [
    azurerm_network_interface.nic-1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.nic-1,
    azurerm_availability_set.avset-dev
  ]
}


// This is the resource for vm1-myvec-dev-eus-002

resource "azurerm_windows_virtual_machine" "vm2-dev" {
  name                = "vm1-myvec-dev-eus-002"
  resource_group_name = azurerm_resource_group.rg-dev.name
  location            = azurerm_resource_group.rg-dev.location
  size                = "Standard_D2s_v3"
  computer_name       = "vm2-dev-001"
  admin_username      = "eswar"
  admin_password      = "Azure@123"
  availability_set_id = azurerm_availability_set.avset-dev.id
  network_interface_ids = [
    azurerm_network_interface.nic-2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.nic-2,
    azurerm_availability_set.avset-dev
  ]
}


resource "azurerm_availability_set" "avset-dev" {
  name                = "avset-myvec-dev-eus-001"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name
  platform_fault_domain_count = 3
  platform_update_domain_count = 5  
  depends_on = [
    azurerm_resource_group.rg-dev
  ]
}

resource "azurerm_storage_account" "stg-dev" {
  name                     = "stgmyvecdeveus001"
  resource_group_name      = azurerm_resource_group.rg-dev.name
  location                 = azurerm_resource_group.rg-dev.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "stgmyvecdeveus001"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.stg-dev
    ]
}

# Here we are uploading our IIS Configuration script as a blob
# to the Azure storage account

resource "azurerm_storage_blob" "IIS_config" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = "stgmyvecdeveus001"
  storage_container_name = "data"
  type                   = "Block"
  source                 = "IIS_Config.ps1"
   depends_on=[azurerm_storage_container.data]
}

// This is the extension for vm1-myvec-dev-eus-001

resource "azurerm_virtual_machine_extension" "vm_extension1" {
  name                 = "vm1-dev-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm1-dev.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.IIS_config
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.stg-dev.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS
}

// This is the extension for vm1-myvec-dev-eus-002

resource "azurerm_virtual_machine_extension" "vm_extension2" {
  name                 = "vm2-dev-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm2-dev.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.IIS_config
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.stg-dev.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS
}

resource "azurerm_network_security_group" "nsg-dev" {
  name                = "nsg-myvec-dev-eus-001"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name

# We are creating a rule to allow traffic on port 80

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.nsg-dev.id
  depends_on = [
    azurerm_network_security_group.nsg-dev
  ]
}

resource "azurerm_public_ip" "LB-pip-dev" {
  name                = "LB-pip-myvec-dev-eus-001"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "Lb-dev" {
  name                = "LB-myvec-dev-eus-001"
  location            = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name

  frontend_ip_configuration {
    name                 = "Lb-ft-pip-dev"
    public_ip_address_id = azurerm_public_ip.LB-pip-dev.id
  }
  sku = "Standard"
  depends_on = [
    azurerm_public_ip.LB-pip-dev
  ]
}

resource "azurerm_lb_backend_address_pool" "Bpool-dev" {
  loadbalancer_id = azurerm_lb.Lb-dev.id
  name            = "Lb-bp-dev"

  depends_on = [
    azurerm_lb.Lb-dev
  ]
}

resource "azurerm_lb_backend_address_pool_address" "vm1-dev-address" {
  name                    = "vm1-myvec-dev-eus-001"
  backend_address_pool_id = azurerm_lb_backend_address_pool.Bpool-dev.id
  virtual_network_id      = azurerm_virtual_network.vnet-dev.id
  ip_address              = azurerm_network_interface.nic-1.private_ip_address

  depends_on = [
    azurerm_lb_backend_address_pool.Bpool-dev
  ]
}

resource "azurerm_lb_backend_address_pool_address" "vm2-dev-address" {
  name                    = "vm1-myvec-dev-eus-002"
  backend_address_pool_id = azurerm_lb_backend_address_pool.Bpool-dev.id
  virtual_network_id      = azurerm_virtual_network.vnet-dev.id
  ip_address              = azurerm_network_interface.nic-2.private_ip_address

   depends_on = [
    azurerm_lb_backend_address_pool.Bpool-dev
  ]
}

resource "azurerm_lb_probe" "Lb-hprobe-dev" { 
  loadbalancer_id = azurerm_lb.Lb-dev.id
  name            = "http-running-probe"
  port            = 80
  depends_on = [
    azurerm_lb.Lb-dev
  ]
}

resource "azurerm_lb_rule" "LbRule-dev" {
  loadbalancer_id                = azurerm_lb.Lb-dev.id
  name                           = "LbRule-dev"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "Lb-ft-pip-dev"

  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.Bpool-dev.id]
  probe_id                       = azurerm_lb_probe.Lb-hprobe-dev.id
depends_on = [
    azurerm_lb.Lb-dev,azurerm_lb_probe.Lb-hprobe-dev
  ]
}