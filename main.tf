# Define the resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.label_prefix}-A05-RG"
  location = var.region

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# Define a public IP address
resource "azurerm_public_ip" "webserver" {
  name                = "${var.label_prefix}A05PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [azurerm_resource_group.rg]
}

# Define the virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.label_prefix}A05Vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [azurerm_resource_group.rg]
}

# Define the subnet
resource "azurerm_subnet" "webserver" {
  name                 = "${var.label_prefix}A05Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [azurerm_virtual_network.vnet]
}

# Define network security group and rules
resource "azurerm_network_security_group" "webserver" {
  name                = "${var.label_prefix}A05SG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [azurerm_resource_group.rg]

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

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Define the network interface
resource "azurerm_network_interface" "webserver" {
  name                = "${var.label_prefix}A05Nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  timeouts {
    create = "10m"
    delete = "10m"
  }

  ip_configuration {
    name                          = "${var.label_prefix}A05NicConfig"
    subnet_id                     = azurerm_subnet.webserver.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webserver.id
  }

  depends_on = [
    azurerm_subnet.webserver,
    azurerm_public_ip.webserver
  ]
}

# Link the security group to the NIC
resource "azurerm_network_interface_security_group_association" "webserver" {
  network_interface_id      = azurerm_network_interface.webserver.id
  network_security_group_id = azurerm_network_security_group.webserver.id
}

# Define the init script template
data "cloudinit_config" "init" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/init.sh")
  }
}

# Define the virtual machine
resource "azurerm_linux_virtual_machine" "webserver" {
  name                  = "${var.label_prefix}A05VM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  network_interface_ids = [azurerm_network_interface.webserver.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "${var.label_prefix}A05OSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "${var.label_prefix}A05VM"
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  custom_data = data.cloudinit_config.init.rendered
}
