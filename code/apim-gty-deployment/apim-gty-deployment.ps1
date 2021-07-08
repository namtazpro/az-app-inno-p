#From article https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/apis/protect-apis

# ------------------1 create resource group -----------------
$resGroupName = "rg-apim-appgtw"
$location = "westeurope"
New-AzResourceGroup -Name $resGroupName -Location $location

# ------------------ create virtual network ----------------
# Retrieve virtual network information
$vnet = Get-AzVirtualNetwork -Name vnet-apim  -ResourceGroupName $resGroupName

# Add the appgtw-subnet to the existing virtual network 
$subnetApplicationGatewayConfig = Add-AzVirtualNetworkSubnetConfig `
-Name appgtw-subnet `
-AddressPrefix 172.17.1.0/24 `
-VirtualNetwork $vnet

# Add the apim-subnet to the existing virtual network 
$subnetAPIMConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name apim-subnet `
  -AddressPrefix 172.17.2.0/24 `
  -VirtualNetwork $vnet

# Attach subnets to the virtual network 
$vnet | Set-AzVirtualNetwork

# Check that subnets were successfully added
$vnet.Subnets

# Assign subnet to variables
$appgatewaysubnetdata = $vnet.Subnets[1]
$apimsubnetdata = $vnet.Subnets[2]


# Create an API Management virtual network-connected object
$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $apimsubnetdata.Id

# ------------------------------- create APIM ----------------------------------
# Create an API Management service inside the virtual network
$apimServiceName = "apim-contoso2021"
$apimOrganization = "contoso1media3"
$apimAdminEmail = "virouet@microsoft.com"

$apimService = New-AzApiManagement `
    -ResourceGroupName $resGroupName `
    -Location $location `
    -Name $apimServiceName `
    -Organization $apimOrganization `
    -AdminEmail $apimAdminEmail `
    -VirtualNetwork $apimVirtualNetwork `
    -VpnType "Internal" `
    -Sku "developer"


# ---------------------------- create certificate -------------------------
# USE An Administrator session to do this next step (and the next)
New-SelfSignedCertificate `
  -certstorelocation cert:\localmachine\my `
  -dnsname "api.contoso1media.com", "portal.contoso1media.com"

  #Result:
  PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\my

  Thumbprint                                Subject
  ----------                                -------
  B01C1D37C8CFF9C31DC1211578A1A6F2352FB6CE  CN=api.contoso1media.com

#--------------------- Export private key --------------------
# USE An Administrator session to do this next step:
  $pwd = ConvertTo-SecureString -String Grenadine1234! -Force -AsPlainText
Export-PfxCertificate `
  -cert cert:\localMachine\my\B01C1D37C8CFF9C31DC1211578A1A6F2352FB6CE `
  -FilePath C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\appgwcert.pfx `
  -Password $pwd

  Export-PfxCertificate `
  -cert cert:\localMachine\my\B01C1D37C8CFF9C31DC1211578A1A6F2352FB6CE `
  -FilePath C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\cert.pfx `
  -Password $pwd


# Specify certificate configuration
$gatewayHostname = "api.contoso1media.com"
$portalHostname = "portal.contoso1media.com"
$gatewayCertCerPath = "C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\cert.pfx"
$gatewayCertPfxPath = "C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\appgwcert.pfx"
$portalCertPfxPath = "C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\appgwcert.pfx"
$gatewayCertPfxPassword = "Grenadine1234!"
$portalCertPfxPassword = "Grenadine1234!"

# Convert to secure string before sending over HTTP
$certPwd = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force
$certPortalPwd = ConvertTo-SecureString -String $portalCertPfxPassword -AsPlainText -Force

# Create and set the hostname configuration objects for the proxy and portal
$proxyHostnameConfig = New-AzApiManagementCustomHostnameConfiguration `
  -Hostname $gatewayHostname `
  -HostnameType Proxy `
  -PfxPath $gatewayCertPfxPath `
  -PfxPassword $certPwd

$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration `
  -Hostname $portalHostname `
  -HostnameType DeveloperPortal `
  -PfxPath $portalCertPfxPath `
  -PfxPassword $certPortalPwd


# Tie certificates configurations into API Management service
# vincent: If process was interupted and you've lost the apim variable, run :  $apimService = Get-AzApiManagement -name apim-contoso2021 -resourcegroup rg-apim-appgtw
$apimService.ProxyCustomHostnameConfiguration = $proxyHostnameConfig
$apimService.PortalCustomHostnameConfiguration = $portalHostnameConfig

# Update API Management with the updated configuration
Set-AzApiManagement -InputObject $apimService


# ---------------------------------- create public ip -------------------
# Create a public IP address for the Application Gateway front end
$publicip = New-AzPublicIpAddress `
    -ResourceGroupName $resGroupName `
    -name "apim-public-ip" `
    -location $location `
    -AllocationMethod Dynamic

# ------------------------------------ configure app gateway
# IP

# Step 1 - create new Application Gateway IP configuration
$gipconfig = New-AzApplicationGatewayIPConfiguration `
    -Name "gatewayIP" `
    -Subnet $appgatewaysubnetdata

# Step 2 - configure the front-end IP port for the public IP endpoint
$fp01 = New-AzApplicationGatewayFrontendPort `
    -Name "frontend-port443" `
    -Port 443

# Step 3 - configure the front-end IP with the public IP endpoint
$fipconfig01 = New-AzApplicationGatewayFrontendIPConfig `
    -Name "frontend1" `
    -PublicIPAddress $publicip

# Step 4 - configure certificates for the Application Gateway
$cert = New-AzApplicationGatewaySslCertificate `
    -Name "apim-gw-cert" `
    -CertificateFile $gatewayCertPfxPath `
    -Password $certPwd

$certPortal = New-AzApplicationGatewaySslCertificate `
    -Name "apim-portal-cert" `
    -CertificateFile $portalCertPfxPath `
    -Password $certPortalPwd

# ------------------------- create app gateway listeners --------------

# Step 5 - configure HTTP listeners for the Application Gateway
$listener = New-AzApplicationGatewayHttpListener `
    -Name "apim-api-listener" `
    -Protocol "Https" `
    -FrontendIPConfiguration $fipconfig01 `
    -FrontendPort $fp01 `
    -SslCertificate $cert `
    -HostName $gatewayHostname `
    -RequireServerNameIndication true

$portalListener = New-AzApplicationGatewayHttpListener `
    -Name "apim-portal-listener" `
    -Protocol "Https" `
    -FrontendIPConfiguration $fipconfig01 `
    -FrontendPort $fp01 `
    -SslCertificate $certPortal `
    -HostName $portalHostname `
    -RequireServerNameIndication true


# -------------------------------- create app gateway endpoints

# Step 6 - create custom probes for API Management endpoints
$apimprobe = New-AzApplicationGatewayProbeConfig `
    -Name "apim-api-probe" `
    -Protocol "Https" `
    -HostName $gatewayHostname `
    -Path "/status-0123456789abcdef" `
    -Interval 30 `
    -Timeout 120 `
    -UnhealthyThreshold 8

$apimPortalProbe = New-AzApplicationGatewayProbeConfig `
    -Name "apim-portal-probe" `
    -Protocol "Https" `
    -HostName $portalHostname `
    -Path "/signin" `
    -Interval 60 `
    -Timeout 300 `
    -UnhealthyThreshold 8


# Step 7 - upload certificate for SSL-enabled backend pool resources
$authcert = New-AzApplicationGatewayAuthenticationCertificate `
    -Name "whitelistcert1" `
    -CertificateFile $gatewayCertCerPath

    THIS BIT DOES NOT WORK

# Step 8 - configure HTTPs backend settings for the Application Gateway
$apimPoolSetting = New-AzApplicationGatewayBackendHttpSettings `
    -Name "apim-api-poolsetting" `
    -Port 443 `
    -Protocol "Https" `
    -CookieBasedAffinity "Disabled" `
    -Probe $apimprobe 
    #-AuthenticationCertificates $authcert `
    -RequestTimeout 180

$apimPoolPortalSetting = New-AzApplicationGatewayBackendHttpSettings `
    -Name "apim-portal-poolsetting" `
    -Port 443 `
    -Protocol "Https" `
    -CookieBasedAffinity "Disabled" `
    -Probe $apimPortalProbe 
    #-AuthenticationCertificates $authcert `
    -RequestTimeout 180



# Step 9a - map backend pool IP with API Management internal IP
$apimProxyBackendPool = New-AzApplicationGatewayBackendAddressPool `
    -Name "apimbackend" `
    -BackendIPAddresses $apimService.PrivateIPAddresses[0]

# Step 9b - create sinkpool for API Management requests to discard 
$sinkpool = New-AzApplicationGatewayBackendAddressPool -Name "sinkpool"

$apimProxyBackendPool = New-AzApplicationGatewayBackendAddressPool `
    -Name "apimbackend" `
    -BackendIPAddresses $apimService.PrivateIPAddresses[0]


# Step 10 - create a routing rule to allow external internet access to the developer portal
$rule01 = New-AzApplicationGatewayRequestRoutingRule `
    -Name "apim-portal-rule" `
    -RuleType Basic `
    -HttpListener $portalListener `
    -BackendAddressPool $apimProxyBackendPool `
    -BackendHttpSettings $apimPoolPortalSetting


    # Step 11 - change Application Gateway SKU and instances (# instances can be configured as required)
$sku = New-AzApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 1

# Step 12 - configure WAF to be in prevention mode
$config = New-AzApplicationGatewayWebApplicationFirewallConfiguration `
    -Enabled $true `
    -FirewallMode "Detection"


    # Deploy the Application Gateway
$appgwName = "agDemoApim"

$appgw = New-AzApplicationGateway `
    -Name $appgwName `
    -ResourceGroupName $resGroupName `
    -Location $location `
    -BackendAddressPools $apimProxyBackendPool, $sinkpool `
    -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting `
    -FrontendIpConfigurations $fipconfig01 `
    -GatewayIpConfigurations $gipconfig `
    -FrontendPorts $fp01 `
    -HttpListeners $listener, $portalListener `
    -RequestRoutingRules $rule01 `
    -Sku $sku `
    -WebApplicationFirewallConfig $config `
    -SslCertificates $cert, $certPortal `
    -AuthenticationCertificates $authcert `
    -Probes $apimprobe, $apimPortalProbe

    # Configure redirection rules.

    # Get existing Application Gateway config
$appgw = Get-AzApplicationGateway `
-ResourceGroupName $resGroupName `
-Name $appgwName

$listener = Get-AzApplicationGatewayHttpListener `
-Name "apim-api-listener" `
-ApplicationGateway $appgw

$sinkpool = Get-AzApplicationGatewayBackendAddressPool `
-ApplicationGateway $appgw `
-Name "sinkpool"

$pool = Get-AzApplicationGatewayBackendAddressPool `
-ApplicationGateway $appgw `
-Name "apimbackend"

$poolSettings = Get-AzApplicationGatewayBackendHttpSettings `
-ApplicationGateway $appgw `
-Name "apim-api-poolsetting"

$pathRule = New-AzApplicationGatewayPathRuleConfig `
-Name "external" `
-Paths "/external/*" `
-BackendAddressPool $pool `
-BackendHttpSettings $poolSettings

$appgw = Add-AzApplicationGatewayUrlPathMapConfig `
-ApplicationGateway $appgw `
-Name "external-urlpathmapconfig" `
-PathRules $pathRule `
-DefaultBackendAddressPool $sinkpool `
-DefaultBackendHttpSettings $poolSettings

$appgw = Set-AzApplicationGateway `
-ApplicationGateway $appgw

$pathmap = Get-AzApplicationGatewayUrlPathMapConfig `
-ApplicationGateway $appgw `
-Name "external-urlpathmapconfig"

$appgw = Add-AzApplicationGatewayRequestRoutingRule `
-ApplicationGateway $appgw `
-Name "apim-api-external-rule" `
-RuleType PathBasedRouting `
-HttpListener $listener `
-BackendAddressPool $Pool `
-BackendHttpSettings $poolSettings `
-UrlPathMap $pathMap

# Update Application Gateway with the new configuration

$appgw = Set-AzApplicationGateway `
    -ApplicationGateway $appgw