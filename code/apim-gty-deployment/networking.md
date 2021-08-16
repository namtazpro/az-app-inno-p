# APIM with Application Gateway

6th and 7th June 2021. Experimentation for LSE project:

Implementation in rg: [rg-apim-appgtw](https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/1d753eb4-5ec5-4e40-a89b-99c7ab6dfc14/resourceGroups/rg-apim-appgtw/overview)

 1- First a simple configuration of an application gateway:
https://docs.microsoft.com/en-gb/azure/application-gateway/quick-create-portal

2 - Then add SSL, but only for the front-end for now. https://docs.microsoft.com/en-gb/azure/application-gateway/create-ssl-portal
```
New-SelfSignedCertificate `
  -certstorelocation cert:\localmachine\my `
  -dnsname "www.contoso1media.com"
```
I get this result:
```

   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\my

Thumbprint                                Subject
----------                                -------
BEA736E2AE2363CA9D33BF3D5F2C45822BDAF485  CN=www.contoso1media.com
```
Then I generate the pfx file:
```

$pwd = ConvertTo-SecureString -String Grenadine1234! -Force -AsPlainText
Export-PfxCertificate `
  -cert cert:\localMachine\my\BEA736E2AE2363CA9D33BF3D5F2C45822BDAF485 `
  -FilePath C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\appgwTestcert.pfx `
  -Password $pwd
```

  3 - Next try with route by URL. https://docs.microsoft.com/en-us/azure/application-gateway/create-url-route-portal

4 - Next try with SSL in back-end and for connecting with APIM. Using the article in [APIM Docs](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway)

Note: The other example is in the [article](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/apis/protect-apis) in reference architecture but harder to implement. The one I tried (early July 2021) in file https://github.com/namtazpro/az-app-inno-p/blob/main/code/apim-gty-deployment.ps1


The article refers to creating certificates. I used the certificate created above (.pfx) and followed instructions in https://docs.microsoft.com/en-us/azure/application-gateway/certificates-for-backend-authentication#export-trusted-root-certificate-for-v2-sku to get the .cer

The APIM is installed in an Internal mode.

Configure for api only for now:

- create certificate for api.contoso1media.com
```
New-SelfSignedCertificate `
  -certstorelocation cert:\localmachine\my `
  -dnsname "api.contoso1media.com"
```
I get this result:
```

   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\my

Thumbprint                                Subject
----------                                -------
BD95B7E10001C44313E65C06B06AF8B90A2AD182  CN=api.contoso1media.com
```
Then I generate the pfx file:
```

$pwd = ConvertTo-SecureString -String Grenadine1234! -Force -AsPlainText
Export-PfxCertificate `
  -cert cert:\localMachine\my\BD95B7E10001C44313E65C06B06AF8B90A2AD182 `
  -FilePath C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\gateway.pfx `
  -Password $pwd
```

- create certificate for contoso1media.com
```
New-SelfSignedCertificate `
  -certstorelocation cert:\localmachine\my `
  -dnsname "contoso1media.com"
```
I get this result:
   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\my

Thumbprint                                Subject
----------                                -------
242D684C9562852505E27641AAC226A777DFCC64  CN=contoso1media.com

=> follow the method described in article https://docs.microsoft.com/en-us/azure/application-gateway/certificates-for-backend-authentication#export-trusted-root-certificate-for-v2-sku  to extract the .cer file

- Initialise variables
```
$gatewayHostname = "api.contoso1media.com"                 # API gateway host
$gatewayCertPfxPath = "C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\gateway.pfx" # full path to api.contoso.net .pfx file
$gatewayCertPfxPassword = "Grenadine1234!"   # password for api.contoso.net pfx certificate
# Path to trusted root CER file used in Application Gateway HTTP settings
$trustedRootCertCerPath = "C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\contoso1media_trustedroot.cer" 

$certGatewayPwd = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force
```

- create and set hostname configuration objects for APIM:
```
$gatewayHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname `
  -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $certGatewayPwd

$apimService.ProxyCustomHostnameConfiguration = $gatewayHostnameConfig

Set-AzApiManagement -InputObject $apimService

```

- Configure a private zone for DNS resolution in vnet
```
$myZone = New-AzPrivateDnsZone -Name "contoso1media.com" -ResourceGroupName $resGroupName 
$link = New-AzPrivateDnsVirtualNetworkLink -ZoneName contoso1media.com `
  -ResourceGroupName $resGroupName -Name "mylink" `
  -VirtualNetworkId $vnet.id
  ```

  - create A-records
  ```
  $apimIP = $apimService.PrivateIPAddresses[0]

New-AzPrivateDnsRecordSet -Name api -RecordType A -ZoneName contoso1media.com `
  -ResourceGroupName $resGroupName -Ttl 3600 `
  -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)
  ```

  - Create Public IP
  ```
  $publicip = New-AzPublicIpAddress -ResourceGroupName $resGroupName `
  -name "publicIP01" -location $location -AllocationMethod Static -Sku Standard
  ```

  - App gateway configuration

  ```
  $gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $appGatewaySubnetData
  $fp01 = New-AzApplicationGatewayFrontendPort -Name "port01"  -Port 443
  $fipconfig01 = New-AzApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip

  # certificate for Application Gateway
  $certGateway = New-AzApplicationGatewaySslCertificate -Name "gatewaycert" `
  -CertificateFile $gatewayCertPfxPath -Password $certGatewayPwd

  # Create HTTP listener
  $gatewayListener = New-AzApplicationGatewayHttpListener -Name "gatewaylistener" `
  -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 `
  -SslCertificate $certGateway -HostName $gatewayHostname -RequireServerNameIndication true

  # Create custom probe
$apimGatewayProbe = New-AzApplicationGatewayProbeConfig -Name "apimgatewayprobe" `
  -Protocol "Https" -HostName $gatewayHostname -Path "/status-0123456789abcdef" `
  -Interval 30 -Timeout 120 -UnhealthyThreshold 8

  # Upload trusted root certificate
  Note: we use "C:\Users\virouet\source\repos\az-app-inno-p\code\apim-gty-deployment\contoso1media_trustedroot.cer" 
  $trustedRootCert = New-AzApplicationGatewayTrustedRootCertificate -Name "whitelistcert1" -CertificateFile $trustedRootCertCerPath

  # Configure back-end settings
  $apimPoolGatewaySetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolGatewaySetting" `
  -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimGatewayProbe `
  -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180

  # backend IP address pool
  $apimGatewayBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "gatewaybackend" `
  -BackendFqdns $gatewayHostname

  # Gateway rule
  $gatewayRule = New-AzApplicationGatewayRequestRoutingRule -Name "gatewayrule" `
  -RuleType Basic -HttpListener $gatewayListener -BackendAddressPool $apimGatewayBackendPool `
  -BackendHttpSettings $apimPoolGatewaySetting

  # App gateway sku
  $sku = New-AzApplicationGatewaySku -Name "WAF_v2" -Tier "WAF_v2" -Capacity 2
  $config = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"

  # Create Application Gateway
  $appgwName = "apim-app-gw"
$appgw = New-AzApplicationGateway -Name $appgwName -ResourceGroupName $resGroupName -Location $location `
  -BackendAddressPools $apimGatewayBackendPool `
  -BackendHttpSettingsCollection $apimPoolGatewaySetting `
  -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 `
  -HttpListeners $gatewayListener `
  -RequestRoutingRules $gatewayRule `
  -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $certGateway `
  -TrustedRootCertificate $trustedRootCert -Probes $apimGatewayProbe



  ------------------- Test on 14/07/2021 WORKS --------------------

https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/application-gateway/self-signed-certificates.md


  
1 -  Create the certificate Key:
openssl ecparam -out contoso1media.key -name prime256v1 -genkey

You get a contoso1media.key file

2 -  Create the Certificate Signing Request. This is what you need to create a certificate with the CA
  openssl req -new -sha256 -key contoso1media.key -out contoso1media.csr

You get a contoso1media.csr file

3 - On the Digicert site, create a certificate with the CA. You need to prove that your own the domain via email

4 - Download the .cer and .crt files 

star_contoso1media_com_147473498TrustedRoot.cer

star_contoso1media_com_147473498DigiCertCA.cer
star_contoso1media_com_147473498DigiCertCA.crt

star_contoso1media_com_147473498star_contoso1media_com.cer
star_contoso1media_com_147473498star_contoso1media_com.crt


5 - Generate a private key
  openssl pkcs12 -export -out star_contoso1media.pfx -inkey contoso1media.key -in star_contoso1media_com_147473498star_contoso1media_com.crt

Get the file star_contoso1media.pfx


Do 1:

- Upload the pfx in APIM and in 




