 following policy which does both : validating some token values and extracting the application id from the claim and passing it to the backend:

 ```

<policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
            <openid-config url=https://login.microsoftonline.com/M365x038023.onmicrosoft.com/.well-known/openid-configuration />
            <audiences>
                <audience>api://74b0b9e0-1c3f-4671-98ee-0d19142dddb6</audience>
            </audiences>
            <issuers>
                <issuer>https://sts.windows.net/ae26ada5-e2df-4de2-8f82-833f168d1cc5</issuer>
            </issuers>
            <required-claims>
                <claim name="roles" match="all">
                    <value>data.enrich</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <set-header name="x-customer-name" exists-action="override">

            <value>@{
            string appId = "NOAUTH";
            string companyName = "NOCOMPANY";   
            string authHeader = context.Request.Headers.GetValueOrDefault("Authorization", "");

            if (authHeader?.Length > 0)
            {

              string[] authHeaderParts = authHeader.Split(' ');

              if (authHeaderParts?.Length == 2 && authHeaderParts[0].Equals("Bearer", StringComparison.InvariantCultureIgnoreCase))
              {

                Jwt jwt;

                if (authHeaderParts[1].TryParseJwt(out jwt))
                {                   
                    appId = jwt.Claims.GetValueOrDefault("appid", "NOAPPID");
                }
              } 
            }

            if(appId.Equals("307f8a58-9574-4fbf-b24e-a888e4fe3753"))
            {
                companyName = "CompanyA";
            }

            if(appId.Equals("f9d670e8-604f-4a1d-b1ac-cb49cce6aada"))
            {
                companyName = "CompanyB";
            }

            return companyName;
            }</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```