# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-vm-lab"
  location = var.location
}
 
# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "tf-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}
 
# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}
 
# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "tf-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
 
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 
  security_rule {
    name                       = "HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
 
# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "tf-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}
 
# NIC
resource "azurerm_network_interface" "nic" {
  name                = "tf-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
 
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
 
# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
 
# VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "tf-ubuntu"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = var.vm_admin_user
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
 
  admin_ssh_key {
    username   = var.vm_admin_user
    public_key = file(var.public_key_path)
  }
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}