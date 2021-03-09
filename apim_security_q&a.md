## Intercept and enforce requests to protected resources. 
 

APIM provides a single pane of glass where requests can be received. API requests can then be checked for security policies, for example OAUTH, client certificate, IP whitelisting etc. Once requests have been validated, they can be routed to backend services where the routing is controlled through rules, such as path, query string etc. APIM can also integrate with a WAF, to provide further security checks, such as OWASP top 10.  

Web Application Firewall (WAF) provides centralized protection of your web applications from common exploits and vulnerabilities. Web applications are increasingly targeted by malicious attacks that exploit commonly known vulnerabilities. SQL injection and cross-site scripting are among the most common attacks.  

 

   

Supported Services:  

WAF can be deployed with Azure Application Gateway, Azure Front Door, and Azure Content Delivery Network (CDN) service from Microsoft. WAF on Azure CDN is currently under public preview. WAF has features that are customized for each specific service.  

 

 

Example of an architecture that uses APIM and an Application Gateway where the WAF can be deployed.  

https://docs.microsoft.com/en-us/azure/architecture/example-scenario/apps/publish-internal-apis-externally  

 

 

 and 

https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway 

 

## Validate security token in isolated environment. 
APIM can validate JWT tokens through policy, where the JWT signature is first checked against the public key of the identity provider. The public key is cached locally, so does not require a call to the IdP in order to retrieve it for each call.   
Physical isolation can be achieved by separate instances of APIM or through a containerised self-hosted gateway. When APIM is deployed as a containerised instance, individual APIs can be made available to just that gateway providing total isolation, with no inbound connectivity required.  
https://docs.microsoft.com/en-us/azure/api-management/self-hosted-gateway-overview 

 

 

 

## API Keys managed by approved service. 
API keys can be requested by API consumers, which would then require approval by an API administrator. Only then would the API key will be visible to the API Consumer. It is also possible to allocate keys directly to API consumers either through the APIM user interface (by an administrator), or through automation (REST API and PowerShell).  
https://docs.microsoft.com/en-us/azure/api-management/api-management-subscriptions 

 

## Integration with approved bp Identity Providers (Azure, Salesforce)  
APIM supports OAUTH and OpenIDConnect, so is able to work with any provider that adopts these standards. OAUTH flows such as user based flows (implicit or authorisation code) are supported, allowing APIM to validate claims passed to the API, such as scopes, audience etc. For service to service flows, Client Credential flow is also supported providing further role validation as part of the JWT. APIM downloads the public signature key from the OAUTH provider metadata endpoints so it is able to validate the signature of the JWT to ensure no tampering, and then validate any of the claims present. 
https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-protect-backend-with-aad 

 

## RBAC model, segregation of duty based on role  
- APIM provides a number of RBAC roles for the APIM platform, but can also create custom RBAC roles that can be used at individual API level if required. 
List of built-in Roles https://docs.microsoft.com/en-us/azure/api-management/api-management-role-based-access-control 
- Azure Policies https://docs.microsoft.com/en-us/azure/governance/policy/overview (not to be confused with API Policies) can also be applied to APIM, for example enforcing that APIs being created are HTTPS only, with HTTP not supported. This is then applied to the APIM user interface and automated deployments. Another example is enforcing deployment rules, such as a certain pricing SKU or region.  
 

Automated security checks built into pipeline. 
APIM provides security on four levels:  

1) The Authoring experience itself, creating APIs. This is managed using Role Based Access Control in the Azure Portal and automation  

APIM RBAC roles https://docs.microsoft.com/en-us/azure/api-management/api-management-role-based-access-control 

2) API Consumer Developer Portal. Support for username/password, or external identity provider such as Goole, Microsoft (OAUTH)  

3) Front end - i.e. the API endpoint exposed by APIM. This supports OAUTH, OpenID Connect, Client Certificate, IP whitelisting, key, rate limits and quotas  

4) Backend - i.e., the backend API that APIM is forwarding the request to. This supports OAUTH, OpenID Connect, Client Certificate, IP whitelisting (static IP) key, networking (VNET - private network access)  

  

Please see the API Management Security Baseline for more details: https://docs.microsoft.com/en-us/azure/api-management/security-baseline 

 