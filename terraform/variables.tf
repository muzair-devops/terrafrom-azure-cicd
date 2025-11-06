############################################################
# variables.tf — Input variables
############################################################

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "visitor-counter-rg"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus2"
}

variable "storage_account_name" {
  description = "Unique storage account name for Function App"
  type        = string
  default     = "funcappstorage1234"
}

variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
  default     = "VisitorCounterApp"
}

variable "cosmos_account_name" {
  description = "Name of the Azure Cosmos DB account"
  type        = string
  default     = "mycosmoscounterdb1234"
}

variable "cosmos_database_name" {
  description = "Name of the Cosmos DB SQL database"
  type        = string
  default     = "VisitorDB1"
}

variable "cosmos_container_name" {
  description = "Name of the Cosmos DB container"
  type        = string
  default     = "CounterContainer1"
}
