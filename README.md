# Introduction
This module creates a resources called *azuread_application*.
With this module all necessary resource are created with, which are be necessary, or is in the standardized creation process of Goldbeck development, for creating Application Registration in Azure Entra ID.

# Tests
The current tests are for:
* general usage: check display names of
  * itself
  * *azuread_application_password* resource
* api:
  * *identifier_uris* is created
  * *web* block is created
* app:
  * *identifier_uris* is **not** created
  * *web* block is created
  * *single_page_application* is created