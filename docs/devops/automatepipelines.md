# Remotely trigger a deployment process with AzDO Pipelines

In order to stay consistent in the way you manage deployment in your organisation it is considered a good practice to do all your deployments via a CI/CD Pipeline. That includes your applications, of course, but also your infrastructure and even configuration managed by a central IT team such as the digital security team when applying changes  to the organization's AAD Tenant.

Here the requirement is "how to plublish an AzDO Pipeline that can be called from any AzDO project in the same or a different AzDO organisation?"


## Create an AzDO Pipeline and call the pipeline remotely...
### ...within the same project:
Refer to the pipeline in the repo where the Pipeline is located.
e.g.
Pipeline that is triggered: (./azure-pipeline-dostuff.yml)
```
parameters:
- name: param1
  type: string

stages:
- stage: MyStage
  jobs:
  - job: MyJob
    pool:
      vmImage: vs2017-win2016
    steps:
    - script: echo Hello, ${{ parameters.param1 }} world!
```

Then call it from another pipeline (./azure-pipeline-main.yml)

```
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

stages:
- template: azure-pipeline-dostuff.yml
  parameters:
      param1: Mini
```


### From a different org:
In this case, you need to use an AzDO REST API call
Using the REST API:
https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/queue?view=azure-devops-rest-6.1

- Documentation to Queue build with AzDO REST API https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/queue?view=azure-devops-rest-6.1#definitions
- How to authenticate to AzDO for REST API call: 
  - First look at [Choose the right authentication mechanism](https://docs.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/authentication-guidance?view=azure-devops)
  - If using OAuth 2.0 : [Authorize access to REST APIs with OAuth 2.0](https://docs.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/oauth?view=azure-devops)
  - Another option is to use a [PAT token in AzDO](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?bc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Fbreadcrumb%2Ftoc.json&toc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Ftoc.json&view=azure-devops&tabs=preview-page). Pass it as a Basic auth in the REST call https://sanderh.dev/call-Azure-DevOps-REST-API-Postman/.
  
- To pass parameters they need to be specified in the body so in this case the defnition id and other properties to. In the body use the format
```
{
    "templateParameters": {"param1": "myvalue"}
    ,
    "definition": {
        "id": 47,
        "name": "SubTaskPipeline"
    }
} 
```

In the AzDO pipeline, the REST API can be called using  az rest command
```
az rest --method post --headers "{\"Authorization\": \"Basic [YourToken]\"}" --url "https://dev.azure.com/[org-name]/[project-name]]/_apis/build/builds?api-version=6.1-preview.6" --body "{\"templateParameters\":{\"[your-param]\": \"[param-value]\"},\"definition\":{\"id\":[pipeline-id],\"name\":\"[pipeline-name]\"}}"
```
To find the pipeline id, inspect the AzDO Rest calls when running a build from your web browser. Using the method described [here](https://github.com/namtazpro/az-devopstools-automation/blob/main/docs/automateAzDO.md#2---look-up-the-url-in-your-web-browser)

AzDO yaml pipeline Task to call the api:
```
- task: AzureCLI@2
  inputs:
    azureSubscription: '[AzDO-connection-name]'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: 'az rest --method post --headers "{\"Authorization\": \"Basic [YourToken]\"}" --url "https://dev.azure.com/[org-name]/[project-name]]/_apis/build/builds?api-version=6.1-preview.6" --body "{\"templateParameters\":{\"[your-param]\": \"[param-value]\"},\"definition\":{\"id\":[pipeline-id],\"name\":\"[pipeline-name]\"}}"'
```


An alternative is to use Logic App: example using Logic App: https://github.com/namtazpro/az-devopstools-automation/blob/main/docs/automateAzDO.md#trigger-a-pipeline

## Create an AzDO Pipeline custom Task
https://docs.microsoft.com/en-us/azure/devops/extend/develop/add-build-task?view=azure-devops
