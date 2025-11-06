############################################################
# main.tf — Azure Function + Cosmos DB Terraform Deployment
############################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  required_version = ">= 1.5.0"

  backend "local" {} # You can switch to Azure Storage backend for remote state
}

provider "azurerm" {
  features {}
}

##############################
# Resource Group
##############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

##############################
# Storage Account (for Function App)
##############################
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

##############################
# Service Plan (Consumption Plan)
##############################
resource "azurerm_service_plan" "plan" {
  name                = "function-app-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

##############################
# Cosmos DB Account
##############################
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_account_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

##############################
# Cosmos DB SQL Database
##############################
resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.cosmos_database_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

##############################
# Cosmos DB SQL Container
##############################
resource "azurerm_cosmosdb_sql_container" "container" {
  name                = var.cosmos_container_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"

  indexing_policy {
    indexing_mode = "consistent"
  }
}

##############################
# Azure Function App
##############################
resource "azurerm_linux_function_app" "func" {
  name                       = var.function_app_name
  resource_group_name         = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  functions_extension_version = "~4"

  site_config {
    application_stack {
      python_version = "3.10"
    }

    cors {
      allowed_origins = ["*"]   # 👈 Enable CORS for all origins
      support_credentials = false
    }
  }

  app_settings = {
    AzureWebJobsStorage       = azurerm_storage_account.storage.primary_connection_string
    FUNCTIONS_WORKER_RUNTIME  = "python"
    COSMOS_ENDPOINT           = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOS_KEY                = azurerm_cosmosdb_account.cosmos.primary_key
    COSMOS_DB_NAME            = azurerm_cosmosdb_sql_database.db.name
    COSMOS_CONTAINER_NAME     = azurerm_cosmosdb_sql_container.container.name
  }

  identity {
    type = "SystemAssigned"
  }
}