

# Transformation in Logic App (Consumption plan, v1)

## Use data transformation:
- MS Doc: [Perform data operations in Azure Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/-logic-apps-perform-data-operations)
- community article: https://platform.deloitte.com.au/articles/transforming-json-objects-in-logic-apps

## Use scripting:
### inline scripting in Logic App
[Add and run code snippets by using inline code in Azure Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-add-run-inline-code)

>Requires an Azure [integration accout](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-create-integration-account?tabs=azure-portal)

### with Azure Function
[Call functions from Azure Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-azure-functions)

## Use Liquid template:
> Requires an Azure [integration accout](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-create-integration-account?tabs=azure-portal)

### Liquid mapping in Logic App
[Transform JSON and XML using Liquid templates as maps in Azure Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-liquid-transform)

[TechNet Microsoft Azure: Liquid Templates in Logic Apps](https://social.technet.microsoft.com/wiki/contents/articles/51275.microsoft-azure-liquid-templates-in-logic-apps.aspx)

>The Transform JSON to JSON - Liquid action follows the [DotLiquid implementation for Liquid](https://github.com/dotliquid/dotliquid), which differs in specific cases from the [Shopify implementation for Liquid](https://shopify.github.io/liquid). For more information, see [Liquid template considerations](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-liquid-transform#liquid-template-considerations).

 Liquid mapping in VSC:

- Open VS Code
- Install the [Shopify Liquid Template snippets](https://marketplace.visualstudio.com/items?itemName=killalau.vscode-liquid-snippets)
- Install the [Shopify Liquid Preview](https://marketplace.visualstudio.com/items?itemName=kirchner-trevor.shopify-liquid-preview)
- Write a simple Liquid template. See article [Liquid Template editing in Visual Studio Code](https://lfalck.se/liquid-template-editing-in-visual-studio-code/)
- Upload to your Azure integration account
- Add it to your Logic App and execute it in your workflow.
- Extract the Input from the Run extract (the JSON that has the "content" element)
- Use this extract as your JSON sample file in VSC. It will contain the exact content as if executing in Logic App 
- When writing the mapping, use Ctrl+Shit+P and select "Shopify Liquid : open preview to the side". Point to the file you want to use as a source.
- Tip: in Logic App, the JSON to JSON will validate the JSON. If JSON is not valid, the mapping will generate an error. In this case use the JSON to Text to see what value is returned in the Logic App run and spot your error by validating the output JSON in your favorite editor.


### Liquid mapping in Azure Function
From community:

This method uses DotLiquid in a Function. Avoids having to use an Integration Account :
[Using Liquid transformations in Logic Apps](https://purple.telstra.com.au/blog/using-liquid-transformations-in-logic-apps-for-free)

# Transformation in Logic App (Standard, v2)

# Transformation in APIM

MS Doc: [APIM Tranformation policies](https://docs.microsoft.com/en-us/azure/api-management/api-management-transformation-policies)


For policy expression syntax : MS Doc: [APIM policy expressions](https://docs.microsoft.com/en-us/azure/api-management/api-management-policy-expressions#ref-imessagebody)

MS Doc: [APIM advanced policies](https://docs.microsoft.com/en-us/azure/api-management/api-management-advanced-policies#SendRequest)

MS Doc: [Transformation examples video](https://azure.microsoft.com/en-gb/resources/videos/episode-177-more-api-management-features-with-vlad-vinogradsky/)


# JSON editing
Use an editor such as https://jsoneditoronline.org/ to make sure your JSON is well formed.