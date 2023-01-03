# Logic Apps deployment

Considerations for your LogicApps deployment:
- Scripting the LogicApps 
- Scripting the API Connections

In a real-life project scenario, your LogicApps will be deployed in multiple environments as part of your CI/CD. In Dev, then Test/UAT/QA (depending) then in Production.
The API connections have to be scripted separately and referenced in the LogicApps at deployment time via parameters for example.

API Connections have a different lifecycle than your LogicApps and exist for each environment. This means dedicated CI/CD for the API Connections or your solutions. 

-- nice drawing here --

## Logic App deployment

TBC

## Connectors deployment

To create the ARM template for the API Connection, you will need to provide a list of parameters for each type of API.

Retrieve the API Parameters by calling the URL below with [armclient.exe](https://chocolatey.org/packages/ARMClient) specifying your subscriptionid {subscriptionId}, Azure region {region} in small caps for your region from this [list](https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.documents.locationnames?view=azure-dotnet), and the api type {api}

```
armclient.exe get https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Web/locations/{region}/managedApis/{Api}?api-version=2016-06-01
```

An API connection that use OAuth need to be provided consent after deployment. In automated deployment this can be achieved using this [PowerShell Script](https://github.com/logicappsio/LogicAppConnectionAuth).

Below is a list of parameter types by API connection type for the most important ones:

* azureblob
  * accountName
  * accessKey
 
* azurequeues
  * storageaccount
  * sharedkey
 
* keyvault
  * vaultName
  * token
  * token:clientId
  * token:clientSecret
  * token:TenantId
  * token:resourceUri
  * token:grantType
 
* sftp
  * hostName
  * userName
  * password
  * sshPrivateKey
  * sshPrivateKeyPassphrase
  * portNumber
  * giveUpSecurityAndAcceptAnySshHostKey
  * sshHostKeyFingerprint
  * disableUploadFilesResumeCapability
 
* azuretables
  * Storageaccount
  * sharedkey
 
* servicebus
  * connectionString
 
* sql
  * server
  * database
  * authType (windows, basic)
  * username
  * password
  * gateway (server, database)
  * sqlConnectionString
 
* outlook 
  
```
   "connectionParameters": {
      "token": {
        "type": "oauthSetting",
        "oAuthSettings": {
          "identityProvider": "outlook",
          "clientId": "4ebc1e7f-42cf-4b43-b3bf-6b83dba126ea",
          "scopes": [
            "https://outlook.office.com/mail.readwrite https://outlook.office.com/mail.send https://outlook.office.com/contacts.readwrite https://outlook.office.com/calendars.readwrite"
          ],
          "redirectMode": "Direct",
          "redirectUrl": "https://logic-apis-westeurope.consent.azure-apim.net/redirect",
          "properties": {
            "IsFirstParty": "False"
          },
          "customParameters": {
            "loginUriAAD": {
              "value": "https://login.microsoftonline.com"
            }
          }
        },
```
 
* office365

```
"connectionParameters": {
      "token": {
        "type": "oauthSetting",
       "oAuthSettings": {
          "identityProvider": "aadcertificate",
          "clientId": "7ab7862c-4c57-491e-8a45-d52a7e023983",
          "scopes": [],
          "redirectMode": "Direct",
          "redirectUrl": "https://logic-apis-westeurope.consent.azure-apim.net/redirect",
          "properties": {
            "IsFirstParty": "True",
            "AzureActiveDirectoryResourceId": "https://graph.microsoft.com"
          },
          "customParameters": {
            "loginUri": {
              "value": "https://login.windows.net"
            },
            "loginUriAAD": {
              "value": "https://login.windows.net"
            },
            "resourceUri": {
              "value": "https://graph.microsoft.com"
            }
          }
        },
```

## Articles & samples

[Azure Logic Apps: Set up a continuous integration (CI) and continuous delivery (CD) pipeline](https://github.com/Azure-Samples/azure-logic-apps-deployment-samples
)

Community: [Deploy Logic Apps & API Connection with ARM](https://www.bruttin.com/2017/06/13/deploy-logic-app-with-arm.html)

## Data parsing and transformation in LogicApps
### File parsing
- CSV and FlatFile : create an xml schema (.xsd) using [BizTalk Flat File Schema Wizard](https://docs.microsoft.com/en-us/biztalk/core/walkthrough-creating-a-flat-file-schema-from-a-document-instance). The wizard is accessible in Visual Studio 2015 using [Azure Logic Apps Tools for Visual Studio 2015](https://marketplace.visualstudio.com/items?itemName=VinaySinghMSFT.AzureLogicAppsToolsforVisualStudio). Once created the schema is used with an integration account in LogicApps [Encode and decode flat files in Azure Logic Apps by using the Enterprise Integration Pack](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-flatfile)
- Use 3rd party connector such as [Plumsail](https://docs.microsoft.com/en-us/connectors/plumsail/), [Encodian](https://docs.microsoft.com/en-us/connectors/encodiandocumentmanager/), [Cloudmersive](https://docs.microsoft.com/en-us/connectors/cloudmersiveconvert/#convert-csv-to-json-conversion)  
