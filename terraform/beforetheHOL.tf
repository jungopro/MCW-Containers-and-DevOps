/*
Below values must be set as env vars for init to work

ARM_SUBSCRIPTION_ID=32...
ARM_CLIENT_ID=ef..
ARM_CLIENT_SECRET=I+..
ARM_TENANT_ID=97..
*/

// Before the HOL

variable "suffix" {
  default = "mcw"
}

provider "azurerm" {
  version = "~> 1.28"
}

resource "azurerm_resource_group" "resource_group" {
  name     = "mcw"
  location = "westeurope"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "fabmedicald-${var.suffix}-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_network_security_rule" "rule" {
  name                        = "RDP"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "fabmedical-${var.suffix}-vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["172.16.0.0/24"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefix       = "172.16.0.0/24"
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "pip" {
  name                = "fabmedicald-${var.suffix}-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  allocation_method = "Dynamic"
  sku               = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "fabmedicald-${var.suffix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_storage_account" "sa" {
  name                     = "fabmedicald${var.suffix}diag"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_kind             = "Storage"
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

resource "azurerm_virtual_machine" "vm" {
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = azurerm_resource_group.resource_group.location
  name                  = "fabmedicald-${var.suffix}"
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS2_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-pron"
    version   = "latest"
  }
  storage_os_disk {
    name              = "fabmedicald${var.suffix}osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = "fabmedicald-${var.suffix}"
    admin_username = "adminfabmedical"
    admin_password = "Password$123"
  }
  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
  license_type = "Windows_Client"

  boot_diagnostics {
    enabled     = true
    storage_uri = "https://${azurerm_storage_account.sa.name}.blob.core.windows.net/"
  }
}

resource "azurerm_network_security_group" "linux_nsg" {
  name                = "fabmedical-${var.suffix}-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_network_security_rule" "linux_rule" {
  name                        = "SSH"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.linux_nsg.name
}

resource "azurerm_network_security_rule" "linux_rule_2" {
  name                        = "allow-app-endpoints"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000-3010"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.linux_nsg.name
}

resource "azurerm_public_ip" "linux_pip" {
  name                = "fabmedical-${var.suffix}-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  allocation_method = "Dynamic"
  sku               = "Basic"
}

resource "azurerm_network_interface" "linux_nic" {
  name                = "fabmedicald-${var.suffix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_pip.id
  }

  network_security_group_id = azurerm_network_security_group.linux_nsg.id
}