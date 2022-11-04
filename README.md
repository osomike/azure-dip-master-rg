Repository intended to deploy a master resource group containing the following components:
- A storage account with the following ADSLGEN2 file systems:
    - A
    - B
    - C
- A Key Vault

A service principal should with rights over the whole susbcription should be created manually.
It's credentials will be stored in the Key Vault.

To create a service principal follow the following steps:

