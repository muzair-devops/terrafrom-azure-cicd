terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "local" {} # or use Azure storage backend for remote state
}

provider "azurerm" {
  features {}
}

# --- Variables ---
variable "resource_group_name" {
  default = "visitor-counter-rg"
}

variable "location" {
  default = "eastus2"
}

# --- Resource Group ---
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# --- Storage Account (for Function App) ---
resource "azurerm_storage_account" "storage" {
  name                     = "funcappstorage1234"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# --- App Service Plan (Consumption Plan) ---
resource "azurerm_service_plan" "plan" {
  name                = "function-app-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# --- Cosmos DB ---
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "mycosmoscounterdb1234"
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

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "VisitorDB1"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "CounterContainer1"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
}

# --- Function App ---
resource "azurerm_linux_function_app" "func" {
  name                       = "VisitorCounterApp"
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
  }

  app_settings = {
    AzureWebJobsStorage       = azurerm_storage_account.storage.primary_connection_string
    FUNCTIONS_WORKER_RUNTIME  = "python"
    COSMOS_ENDPOINT           = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOS_KEY                = azurerm_cosmosdb_account.cosmos.primary_key
    COSMOS_DB_NAME            = azurerm_cosmosdb_sql_database.db.name
    COSMOS_CONTAINER_NAME     = azurerm_cosmosdb_sql_container.container.name
  }
}
