Repository intended to deploy a master resource group containing the following components:
- A storage account with the following ADSLGEN2 file systems:
    - asdlgen2-fs-config
    - asdlgen2-fs-raw-zone
    - asdlgen2-fs-curated-zone
- A Key Vault, with the Access Policies ready for the list of Admins and Contributors set on the ```variables.tf``` file

A service principal should with rights over the whole susbcription should be created manually.
It's credentials will be stored in the Key Vault.

To create a service principal follow the following steps:

```console
az ad sp create-for-rbac --name <my-service-principal-name> \
                         --role <role-name> \
                         --scopes </subscriptions/my-subscription-ID/resourceGroups/myResourceGroupName>
```

The scope of the service principal can be extended to the subscription.
A recomended name for this service princial can be: ```dip-service-princial-subscription```

The output will look like this:
```console
{
  "appId": "An App ID",
  "displayName": "dip-service-princial-subscription",
  "password": "A password",
  "tenant": "A tenant ID"
}
```

Store these credentials in the keyvault as:
Service Principal App ID | Owner of the subscription
dip-sp-subscription-appid
Service Principal Secret | Owner of the subscription
dip-sp-subscription-secret
Tenant ID of the subscription
dip-tenantid

Store the output of the file as a secret anmed ```AZURE_CREDENTIALS``` in the repository.

