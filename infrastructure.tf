###########################################################
### Default configuration block when working with Azure ###
###########################################################
terraform {
  # Provide configuration details for Terraform
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.90"
    }
  }
  # This resources need to be in place to be able to use them.
  # https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
  backend "azurerm" {
    resource_group_name  = "dip-prd-master-rg"
    storage_account_name = "dipprdmasterst"
    container_name       = "dip-prd-asdlgen2-fs-config"
    key                  = "dip-prd-master-rg/terraform.tfstate"
    
  }
}

# provide configuration details for the Azure terraform provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}


# For naming conventions please refer to:
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules

# Get info about current user
data "azuread_client_config" "current" {}


###########################################################
###################  Resource Group #######################
###########################################################
resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "${var.default_prefix}-${var.environment}-${var.random_id}-rg"
  tags = {
    owner       = var.owner
    environment = var.environment

  }
}

# Add Ownership roles for the resource group to the list of contributors.
# Note.- Admins do not need to be added. They are already owners of the subscription, so they will inherit the ownershipt for this resource group. Otherwise there will be listed twice.
resource "azurerm_role_assignment" "roles_on_rg_for_contributors" {
  for_each = toset(var.contributors_object_ids)
  role_definition_name = "Owner" # "Owner" | "Contributor" | azurerm_role_definition.rd.name
  scope                = azurerm_resource_group.rg.id
  principal_id         = each.key
}

###########################################################
###################  Storage Account ######################
###########################################################
resource "azurerm_storage_account" "storageaccount" {
  name = "${var.default_prefix}${var.environment}${var.random_id}st" # Between 3 to 24 characters and
                                                                     # UNIQUE within Azure
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"

  tags = {
    owner       = var.owner
    environment = var.environment
  }
}

# resource "azurerm_role_assignment" "sp01_role_02" {
#   role_definition_name = "Storage Blob Data Contributor" # "Owner" | "Contributor" | azurerm_role_definition.rd.name
#   scope                = azurerm_resource_group.rg.id
#   principal_id         = azuread_service_principal.sp01.id
# }

###########################################################
################  Azure Storage Container #################
###########################################################
# resource "azurerm_storage_container" "storage_container" {
#   name                  = "${var.default_prefix}-${var.environment}-content"
#   storage_account_name  = azurerm_storage_account.storageaccount.name
#   container_access_type = "private"
# }

# Upload file to storage container
resource "azurerm_storage_blob" "example" {
  name                   = "README.md"
  storage_account_name   = azurerm_storage_account.storageaccount.name
#  storage_container_name = azurerm_storage_container.storage_container.name
  storage_container_name = azurerm_storage_data_lake_gen2_filesystem.myasdlgen2replica01.name
  type                   = "Block"
  source                 = "README.md"
}


###########################################################
########  Azure Storage Data Lake Gen2 Filesystem #########
###########################################################
resource "azurerm_storage_data_lake_gen2_filesystem" "myasdlgen2replica01" {
  name               = "${var.default_prefix}-${var.environment}-asdlgen2-fs-config"
  storage_account_id = azurerm_storage_account.storageaccount.id

  properties = {
    hello = "aGVsbG8="
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "myasdlgen2replica02" {
  name               = "${var.default_prefix}-${var.environment}-asdlgen2-fs-raw-zone"
  storage_account_id = azurerm_storage_account.storageaccount.id

  properties = {
    hello = "aGVsbG8="
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "myasdlgen2replica03" {
  name               = "${var.default_prefix}-${var.environment}-asdlgen2-fs-curated-zone"
  storage_account_id = azurerm_storage_account.storageaccount.id

  properties = {
    hello = "aGVsbG8="
  }
}


###########################################################
##################### Azure Key Vault #####################
###########################################################
resource "azurerm_key_vault" "kv" {
  name = "${var.default_prefix}-${var.environment}-${var.random_id}-kv" # Between 3 to 24 characters and
                                                                        # UNIQUE within Azure
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azuread_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

}

# Add Access Policy Rights to the list of Administrator Object IDs
resource "azurerm_key_vault_access_policy" "keyVault_accessPolicies_for_admins" {
  for_each           = toset(var.admins_object_ids)
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azuread_client_config.current.tenant_id
  object_id          = each.key
  key_permissions    = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
  "ManageContacts", "GetIssuers", "ManageIssuers", "SetIssuers", "ListIssuers", "DeleteIssuers"]
}

# Add Access Policy Rights to the list of Contributors Object IDs
resource "azurerm_key_vault_access_policy" "keyVault_accessPolicies_for_contributors" {
  for_each           = toset(var.contributors_object_ids)
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azuread_client_config.current.tenant_id
  object_id          = each.key
  key_permissions    = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
  "ManageContacts", "GetIssuers", "ManageIssuers", "SetIssuers", "ListIssuers", "DeleteIssuers"]
}

