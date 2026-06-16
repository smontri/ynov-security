# Virtual Network
resource "azurerm_virtual_network" "ynov-vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ynov-rg.location
  resource_group_name = azurerm_resource_group.ynov-rg.name

  tags = {
    environment = "${var.environment}"
    owner       = "${var.prefix}"
    label       = "Virtual Network"
    project     = "${var.project}"
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "ynov-vm" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.ynov-rg.location
  resource_group_name   = azurerm_resource_group.ynov-rg.name
  network_interface_ids = [
    azurerm_network_interface.ynov-nic.id
  ]
  size                  = "Standard_D2s_v3"
  admin_username        = "adminuser"

  admin_ssh_key {
    username = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  tags = {
    environment = "${var.environment}"
    owner       = "${var.prefix}"
    label       = "Virtual Machine"
    project     = "${var.project}"
  }
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.ynov-vm.name
}

# Subnet
resource "azurerm_subnet" "ynov-subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.ynov-rg.name
  virtual_network_name = azurerm_virtual_network.ynov-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Resource Group
resource "azurerm_resource_group" "ynov-rg" {
  name     = "${var.prefix}-resources"
  location = "North Europe"

  tags = {
    environment = "${var.environment}"
    owner       = "${var.prefix}"
    label       = "Resource Group"
    project     = "${var.project}"
  }
}

# Public IPs
resource "azurerm_public_ip" "ynov-ip" {
  name                = "${var.prefix}-ip"
  location            = azurerm_resource_group.ynov-rg.location
  resource_group_name = azurerm_resource_group.ynov-rg.name
  allocation_method   = "Static"

  tags = {
    environment = "${var.environment}"
    owner       = "${var.prefix}"
    label       = "Public IP"
    project     = "${var.project}"
  }
}

output "public_ip" {
  value = azurerm_public_ip.ynov-ip.ip_address
}

# Network Security Group and rule
resource "azurerm_network_security_group" "ynov-nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.ynov-rg.location
  resource_group_name = azurerm_resource_group.ynov-rg.name

  # Allow incoming connection on port 22 for SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "${var.environment}"
    owner       = "${var.prefix}"
    label       = "Network Security Group"
    project     = "${var.project}"
  }
}

# Network Interface
resource "azurerm_network_interface" "ynov-nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.ynov-rg.location
  resource_group_name = azurerm_resource_group.ynov-rg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.ynov-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ynov-ip.id
  }

  tags = {
    environment = "${var.environment}"
    owner       = "${var.prefix}"
    label       = "Network Interface"
    project     = "${var.project}"
  }
}