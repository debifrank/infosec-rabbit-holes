terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "prefix" {
  type    = string
  default = "vulnapp1"
}

variable "functionapp" {
  type    = string
  default = "./vulnapp1.zip"
}

provider "azurerm" {
  features {}
}

resource "random_string" "uid" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg-${random_string.uid.result}"
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}sa${random_string.uid.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                 = "${var.prefix}-container-${random_string.uid.result}"
  storage_account_name = azurerm_storage_account.storage.name
}

data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true
  start             = "2023-01-01"
  expiry            = "2123-01-01"
  resource_types {
    object    = true
    container = false
    service   = false
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

resource "azurerm_storage_blob" "blob" {
  name                   = "vulnapp1.zip"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = var.functionapp
}

resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-plan-${random_string.uid.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "functions" {
  name                       = "${var.prefix}-func-app-${random_string.uid.result}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "${azurerm_storage_blob.blob.url}${data.azurerm_storage_account_sas.sas.sas}"
  }
  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_function_app_host_keys" "keys" {
  name                = azurerm_linux_function_app.functions.name
  resource_group_name = azurerm_resource_group.rg.name
}

output "Fetch-Target-URL" {
  description = "Endpoint where you can interact with the vulnerable function app endpoint 'fetch', including the API key"
  value       = nonsensitive("https://${azurerm_linux_function_app.functions.name}.azurewebsites.net/api/fetch?code=${data.azurerm_function_app_host_keys.keys.default_function_key}&url=https://www.codydmartin.com/robots.txt")
}

output "Read-Target-URL" {
  description = "Endpoint where you can interact with the vulnerable function app endpoint 'read', including the API key"
  value       = nonsensitive("https://${azurerm_linux_function_app.functions.name}.azurewebsites.net/api/read?code=${data.azurerm_function_app_host_keys.keys.default_function_key}&file=/tmp/license.txt")
}