# Introduction

This module creates a resources called _azuread_application_.
With this module all necessary resource are created with, which are be necessary, or is in the standardized creation process of Goldbeck development, for creating Application Registration in Azure Entra ID.

# Tests

The current tests are for:

- general usage: check display names of
  - itself
  - _azuread_application_password_ resource
- api:
  - _identifier_uris_ is created
  - _web_ block is created
- app:
  - _identifier_uris_ is **not** created
  - _web_ block is created
  - _single_page_application_ is created

# How to Use

## For productive use

```hcl
module "key_vault" {
  source  = "app.terraform.io/goldbeck/appregistration-api/azuread"
  version = "1.2.0"
}
```

## For Testing use

```hcl
module "key_vault" {
  source = "github.com/GOLDBECK-ID/terraform-azuread-appregistration-api?ref=dev"
  # source = "github.com/GOLDBECK-ID/terraform-azurerm-key-vault?ref=<branch-name>"
  # other required configs
}
```
