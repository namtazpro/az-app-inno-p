## Client request checks
Check that a call is not made from the same location for the GUID within 10 seconds
'''
<policies>
    <inbound>
        <base />
        <set-backend-service id="apim-generated-policy" backend-id="func-api-win-nodejs" />
        <cache-lookup-value key="@(context.Request.OriginalUrl.Query.GetValueOrDefault("location") + "_" + context.Request.OriginalUrl.Query.GetValueOrDefault("guid"))" default-value="none" variable-name="sessionkey" />
        <choose>
            <when condition="@(context.Request.OriginalUrl.Query.GetValueOrDefault("location") + "_" + context.Request.OriginalUrl.Query.GetValueOrDefault("guid") == (string)context.Variables["sessionkey"])">
                <return-response>
                    <set-status code="403" reason="Client session must be from same location" />
                </return-response>
            </when>
        </choose>
        <cache-store-value key="@(context.Request.OriginalUrl.Query.GetValueOrDefault("location") + "_" + context.Request.OriginalUrl.Query.GetValueOrDefault("guid"))" value="@(context.Request.OriginalUrl.Query.GetValueOrDefault("location") + "_" + context.Request.OriginalUrl.Query.GetValueOrDefault("guid"))" duration="10" />
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
'''