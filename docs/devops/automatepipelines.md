# Remotely trigger a deployment process with ADO Pipelines

In order to stay consistent in the way you manage deployment in your organisation it is considered a good practice to do all your deployments via a CI/CD Pipeline. That includes your applications, of course, but also your infrastructure and even configuration managed by a central IT team such as the digital security team when applying changes  to the organization's AAD Tenant.

Here the requirement is "how to plublish an ADO Pipeline that can be called from any ADO project in the same or a different ADO organisation?"


## Create an ADO Pipeline and call the pipeline remotely...
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
In this case, you need to use an ADO REST API call
Using the REST API:
https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/queue?view=azure-devops-rest-6.1

- Documentation to Queue build with ADO REST API https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/queue?view=azure-devops-rest-6.1#definitions
- How to authenticate to ADO for REST API call: 
You will need to create a PAT token in ADO and pass it as a Basic auth in the REST call https://sanderh.dev/call-Azure-DevOps-REST-API-Postman/
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

In the ADO pipeline, the REST API can be called using  az rest command
```
az rest --method post --headers "{\"Authorization\": \"Basic [YourToken]\"}" --url "https://dev.azure.com/[org-name]/[project-name]]/_apis/build/builds?api-version=6.1-preview.6" --body "{\"templateParameters\":{\"[your-param]\": \"[param-value]\"},\"definition\":{\"id\":[pipeline-id],\"name\":\"[pipeline-name]\"}}"
```
To find the pipeline id, inspect the ADO Rest calls when running a build from your web browser. Using the method described [here](https://github.com/namtazpro/az-devopstools-automation/blob/main/docs/automateado.md#2---look-up-the-url-in-your-web-browser)

ADO yaml pipeline Task to call the api:
```
- task: AzureCLI@2
  inputs:
    azureSubscription: '[ADO-connection-name]'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: 'az rest --method post --headers "{\"Authorization\": \"Basic [YourToken]\"}" --url "https://dev.azure.com/[org-name]/[project-name]]/_apis/build/builds?api-version=6.1-preview.6" --body "{\"templateParameters\":{\"[your-param]\": \"[param-value]\"},\"definition\":{\"id\":[pipeline-id],\"name\":\"[pipeline-name]\"}}"'
```


An alternative is to use Logic App: example using Logic App: https://github.com/namtazpro/az-devopstools-automation/blob/main/docs/automateado.md#trigger-a-pipeline

## Create an ADO Pipeline custom Task
https://docs.microsoft.com/en-us/azure/devops/extend/develop/add-build-task?view=azure-devops
