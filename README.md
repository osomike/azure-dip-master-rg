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
                         --scopes </subscriptions/my-subscription-ID/resourceGroups/myResourceGroupName> \
                         --sdk-auth
```

The scope of the service principal can be extended to the subscription, just use ```--scopes </subscriptions/my-subscription-ID``` instead.

A recomended name for this service princial can be: ```dip-service-princial-subscription```

The output of the previous command should look like this:
```console
{
  "clientId": "<cliend-ID>",
  "clientSecret": "<cliend-secret>",
  "subscriptionId": "<subscription-ID>",
  "tenantId": "<tenant-ID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

Store this output as a secret named ```AZURE_CREDENTIALS``` in the repository.

The file cicd.yml from github actions folder will read its content to perform the steps.

The repository should also also contain the [Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) ```dev```, ```acp``` and ```prd```.

Store these credentials in the keyvault as:
Service Principal App ID | Owner of the subscription
dip-sp-subscription-appid
Service Principal Secret | Owner of the subscription
dip-sp-subscription-secret
Tenant ID of the subscription
dip-tenantid
