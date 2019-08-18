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