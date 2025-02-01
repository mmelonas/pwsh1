using module VMware.PowerCLI.Sdk.Types
using module VMware.PowerCLI.VCenter.Types.CertificateManagement
using namespace VMware.VimAutomation.ViCore.Types.V1
using namespace VMware.VimAutomation.ViCore.Types.V1.Inventory
using namespace System.Security.Cryptography.X509Certificates
using namespace VMware.VimAutomation.Sdk.Util10Ps.BaseCmdlet

. (Join-Path $PSScriptRoot "../utils/Connection.ps1")
. (Join-Path $PSScriptRoot "../utils/Report-CommandUsage.ps1")
. (Join-Path $PSScriptRoot "../types/builders/New-TrustedCertificateInfo.ps1")

<#
.SYNOPSIS

This cmdlet adds a certificate or certificate chain to the vCenter Server or ESXi trusted stores.

.DESCRIPTION

This cmdlet adds a certificate or certificate chain to the vCenter Server or ESXi trusted stores.

To use this cmdlet, you must connect to vCenter Server through the Connect-VIServer cmdlet.

Note: The certificate or certificate chain will be added to both the vCenter Server instance and the connected ESXi hosts unless you use the VCenterOnly or EsxOnly parameters.

.PARAMETER PemCertificateOrChain

Specifies a certificate or certificate chain in PEM format to be added to the vCenter Server and/or ESXi trusted stores.

.PARAMETER X509Certificate

Specifies a certificate as an X509Certificate object to be added to the vCenter Server and/or ESXi trusted stores.

.PARAMETER X509Chain

Specifies a certificate chain as an X509Chain object to be added to the vCenter Server and/or ESXi trusted stores.

.PARAMETER VMHost

Specifies one or more ESXi hosts to whose trusted stores you want to add the certificate or certificate chain.

.PARAMETER VCenterOnly

Specifies that the certificate or certificate chain must be added only to the trusted store of the vCenter Server instance.

.PARAMETER EsxOnly

Specifies that the certificate or certificate chain must be added only to the trusted store of the ESXi hosts.


.EXAMPLE
PS C:\> $caPem = Get-Content ca.pem -Raw
PS C:\> Add-VITrustedCertificate -PemCertificateOrChain $caPem

Adds the certificate from ca.pem to the trusted certificate stores of the vCenter Server and all the ESXi hosts connected to the vCenter system.


.EXAMPLE
PS C:\> $caPem = Get-Content ca.pem -Raw
PS C:\> Add-VITrustedCertificate -PemCertificateOrChain $caPem -VCenterOnly

Adds the certificate from ca.pem to the trusted certificate store of the vCenter Server system.


.EXAMPLE
PS C:\> $caPem = Get-Content ca.pem -Raw
PS C:\> Add-VITrustedCertificate -PemCertificateOrChain $caPem -EsxOnly

Adds the certificate from ca.pem to the trusted certificate stores of the ESXi hosts of the vCenter Server system, but not to the vCenter itself.


.EXAMPLE
PS C:\> $caPem = Get-Content ca.pem -Raw
PS C:\> Add-VITrustedCertificate -VMHost 'MyHost' -PemCertificateOrChain $caPem

Adds the certificate from ca.pem to the trusted certificate store of the 'MyHost' ESXi host.


.OUTPUTS

One or more TrustedCertificateInfo objects


.LINK

https://developer.vmware.com/docs/powercli/latest/vmware.powercli.vcenter/commands/add-vitrustedcertificate

#>
function Add-VITrustedCertificate {
   [CmdletBinding(
      ConfirmImpact = "High",
      DefaultParameterSetName = "Default",
      SupportsShouldProcess = $True)]
   [OutputType([TrustedCertificateInfo])]
   Param (
      [Parameter(ValueFromPipeline = $true)]
      [String[]]
      $PemCertificateOrChain,

      [Parameter()]
      [X509Certificate[]]
      $X509Certificate,

      [Parameter()]
      [X509Chain[]]
      $X509Chain,

      [Parameter(Mandatory = $true, ParameterSetName = "PerEsx")]
      [ObnArgumentTransformation([VMHost])]
      [VMHost[]]
      $VMHost,

      [Parameter(Mandatory = $true, ParameterSetName = 'VCenterOnly')]
      [switch]
      $VCenterOnly,

      [Parameter(Mandatory = $true, ParameterSetName = 'EsxOnly')]
      [switch]
      $EsxOnly,

      [Parameter()]
      [ObnArgumentTransformation([VIServer], Critical = $true)]
      [VIServer]
      $Server
   )

   Begin {
      Report-CommandUsage $MyInvocation
      
      # Handle Server obn first
      if($Server) {
         $resolvedServer = Resolve-ObjectByName `
            -Object $Server `
            -Type ([VIServer]) `
            -OneObjectExpected

         $Server = [VIServer] $resolvedServer
      }

      $activeServer = GetActiveServer($Server)
      ValidateApiVersionSupported -server $activeServer -major 7 -minor 0

      # Collect OBN for parameter 'VMHost'
      if($VMHost) {
         $resolvedVMHost = Resolve-ObjectByName -Object $VMHost `
            -Type ([VMHost]) `
            -CollectorCmdlet 'Get-VMHost' `
            -OneOrMoreObjectsExpected `
            -Server $activeServer

         $VMHost = [VMHost[]] $resolvedVMHost
      }

      # Validate that only one of:
      #   PemCertificateOrChain
      #   X509Certificate
      #   X509Chain
      # is present

      $counter = 0
      if ($PemCertificateOrChain) {
         $PemCertificateOrChain | Confirm-PemContainsCertificates
         $counter += 1
      }

      if ($X509Certificate) {
         $counter += 1
      }

      if ($X509Chain) {
         $counter += 1
      }

      if ($counter -eq 0) {
         Write-PowerCLIError `
            -ErrorObject 'One of the parameters PemCertificateOrChain, X509Certificate or X509Chain must be supplied.' `
            -Terminating
      } elseif ($counter -gt 1) {
         Write-PowerCLIError `
            -ErrorObject 'Only one of the parameters PemCertificateOrChain, X509Certificate or X509Chain must be supplied.' `
            -Terminating
      }
   }

   Process {
      # Validate all objects are from the same server
      if($VMHost) {
         $VMHost | ValidateSameServer -ExpectedServer $activeServer
      }

      $updateVc = $PsCmdlet.ParameterSetName -eq 'Default' -or `
         ($PsCmdlet.ParameterSetName -eq 'VCenterOnly' -and $VCenterOnly.ToBool())

      $updateEsx = $PsCmdlet.ParameterSetName -eq 'Default' -or `
         ($PsCmdlet.ParameterSetName -eq 'EsxOnly' -and $EsxOnly.ToBool())

      if ($updateEsx) {
         $tempVMHost = Get-VMHost -Server $activeServer
         if ($tempVMHost) {
            $VMHost = $tempVMHost
         }
      }

      $pemCertArray = [System.Collections.ArrayList]::new()

      if ($PemCertificateOrChain) {
         $PemCertificateOrChain | Read-PemCertificate | % {
            $pemCertArray.Add($_) | Out-Null
         }
         if ($pemCertArray.Count -eq 0) {
            Write-PowerCLIError `
               -ErrorObject 'No certificate found in the PemCertificateOrChain.' `
               -ErrorId "PowerCLI_VITrustedCertificate_NoCertificateFoundInPemCertificateOrChain"
         }
      } elseif ($X509Certificate) {
         $X509Certificate | ConvertTo-PemCertificate | % {
            $pemCertArray.Add($_) | Out-Null
         }
      } elseif ($X509Chain) {
         $X509Chain | % { $_.ChainElements } | % {
            ConvertTo-PemCertificate -X509Certificate $_.Certificate
         } | % {
            $pemCertArray.Add($_) | Out-Null
         }
         if ($pemCertArray.Count -eq 0) {
            Write-PowerCLIError `
               -ErrorObject 'No certificates found in the X509Chain' `
               -ErrorId "PowerCLI_VITrustedCertificate_NoCertificateFoundInx509Chain"
         }
      }

      if ($pemCertArray.Count -gt 0) {
         $vcName = ''
         if ($updateVc) {
            $vcName = $activeServer.Name
         }

         $shouldProcessDescription = Get-ShouldProcessMessage $pemCertArray $vcName ($VMHost | Select-Object -ExpandProperty Name)
         $shouldProcessWarning = Get-ShouldProcessMessage $pemCertArray $vcName ($VMHost | Select-Object -ExpandProperty Name) -warning

         if($PSCmdlet.ShouldProcess(
            $shouldProcessDescription,
            $shouldProcessWarning,
            "Add certificate")) {

            if ($updateVc) {
               $apiServer = GetApiServer($activeServer)
               
               try {
                  $trustedChainIds =
                     $pemCertArray | % {
                        Initialize-CertificateManagementX509CertChain -CertChain ([string[]]@($_))
                     } | `
                     Initialize-CertificateManagementVcenterTrustedRootChainsCreateSpec | `
                     Invoke-CreateCertificateManagementTrustedRootChains `
                        -Server $apiServer `
                        -ErrorAction:Stop

                  Get-VITrustedCertificate `
                     -Id ($trustedChainIds | % {
                        $UidUtil.Append($activeServer.Uid, "ViTrustedCertificate", $_)
                     }) | `
                     Write-Output
               } catch {
                  Write-PowerCLIError `
                     -ErrorObject $_ `
                     -ErrorId "PowerCLI_VITrustedCertificate_FailedToAddVcTrustChains"
               }
            }

            if ($VMHost) {
               foreach ($currentVMHost in $VMHost) {
                  try {
                     $certificateManager = Get-View $currentVMHost.ExtensionData.ConfigManager.CertificateManager -Server $activeServer
                     $addingCertificatesThumbprints = [System.Collections.ArrayList]::new()
                     $trustedCertificates = [System.Collections.ArrayList]::new()

                     $pemCertArray | % {
                        $trustedCertificates.Add($_) | Out-Null
                        $_ | ConvertTo-X509Certificate | %{
                           $addingCertificatesThumbprints.Add($_.Thumbprint) | Out-Null
                        }
                     }

                     $currentTrustedCertificates = $certificateManager.ListCACertificates()
                     if ($currentTrustedCertificates) {
                        $trustedCertificates.AddRange($currentTrustedCertificates)
                     }

                     $certificateManager.ReplaceCACertificatesAndCRLs(
                        $trustedCertificates.ToArray(), $null) | Out-Null

                     Get-ViTrustedCertificate -Id ($addingCertificatesThumbprints | % {
                        $UidUtil.Append($currentVMHost.Uid, "ViTrustedCertificate", $_)
                     })
                  } catch {
                     Write-PowerCLIError `
                        -ErrorObject $_ `
                        -ErrorId "PowerCLI_VITrustedCertificate_FailedToAddEsxTrustChains"
                  }
               }
            }
         }
      }
   }
}

function Read-PemCertificate {
   param(
      [Parameter(ValueFromPipeline = $true)]
      [string]
      $pem
   )

   $beginStr = '-----BEGIN CERTIFICATE-----'
   $endStr = '-----END CERTIFICATE-----'
   $beginIndex = $pem.IndexOf($beginStr)
   while ($beginIndex -ge 0) {
      $endIndex = $pem.IndexOf($endStr, $beginIndex)
      if ($endIndex -gt $beginIndex) {
         $pem.Substring($beginIndex, $endIndex + $endStr.Length - $beginIndex) | Write-Output
         $beginIndex = $pem.IndexOf($beginStr, $endIndex)
      } else {
         Write-PowerCLIError `
            -ErrorObject @"
The PEM:
---------------------------
$pem
---------------------------
Contains '$beginStr' with missing '$endStr'.
"@ `
            -ErrorId 'PowerCLI_VITrustedCertificate_MissingEndCertificate'
         # END CERTIFICATE not found no need to continue
         break
      }
   }
}

function Get-ShouldProcessMessage {
   param(
      [string[]]
      $pem,

      [string]
      $vcName,

      [string[]]
      $hostName,

      [switch]
      $warning
   )

   $sb = [System.Text.StringBuilder]::new()

   if ($warning.ToBool()) {
      $sb.Append("Are you sure you want to add ") | Out-Null
   } else {
      $sb.Append("Adding ") | Out-Null
   }

   $pem | ConvertTo-X509Certificate | % {
      $sb.Append("'") | Out-Null
      $sb.Append($_.GetNameInfo([X509NameType]::SimpleName, $false)) | Out-Null
      $sb.Append("'") | Out-Null
      $sb.Append(", ") | Out-Null
   }
   $sb.Remove($sb.Length - 2, 2) | Out-Null

   $sb.Append(" certificate") | Out-Null
   if ($pem.Length -gt 1) {
      $sb.Append("s") | Out-Null
   }
   $sb.Append(" to") | Out-Null

   if(-not [string]::IsNullOrEmpty($vcName)) {
      $sb.Append(" vCenter Server '$vcName'") | Out-Null
      if ($hostName) {
         $sb.Append(" and") | Out-Null
      }
   }

   if ($hostName) {
      $sb.Append(" host") | Out-Null
      if ($hostName.Length -gt 1) {
         $sb.Append("s") | Out-Null
      }
      $sb.Append(" ") | Out-Null

      $hostName | % {
         $sb.Append("'$_', ") | Out-Null
      }

      $sb.Remove($sb.Length - 2, 2) | Out-Null
   }

   if ($warning.ToBool()) {
      $sb.Append("?") | Out-Null
   } else {
      $sb.Append(".") | Out-Null
   }

   $sb.ToString() | Write-Output
}

function Confirm-PemContainsCertificates {
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
      [string[]]
      $Pem
   )

   return

   $Pem | %{
      if (!$_.Contains('-----BEGIN CERTIFICATE-----') -or `
         !$_.Contains('-----END CERTIFICATE-----')) {
         Write-PowerCLIError `
            -ErrorObject "PemCertificateOrChain must contain a PEM certificate." `
            -Terminating
      }
   }
}

# SIG # Begin signature block
# MIIi/AYJKoZIhvcNAQcCoIIi7TCCIukCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCvmDAVDZjRpvv/
# 4VnKGm40A7mrKvABYg5JTURQLtJMiqCCDdowggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggciMIIFCqADAgECAhAOxvKydqFGoH0ObZNXteEIMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjEwODEwMDAwMDAwWhcNMjMwODEw
# MjM1OTU5WjCBhzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExEjAQ
# BgNVBAcTCVBhbG8gQWx0bzEVMBMGA1UEChMMVk13YXJlLCBJbmMuMRUwEwYDVQQD
# EwxWTXdhcmUsIEluYy4xITAfBgkqhkiG9w0BCQEWEm5vcmVwbHlAdm13YXJlLmNv
# bTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAMD6lJG8OWkM12huIQpO
# /q9JnhhhW5UyW9if3/UnoFY3oqmp0JYX/ZrXogUHYXmbt2gk01zz2P5Z89mM4gqR
# bGYC2tx+Lez4GxVkyslVPI3PXYcYSaRp39JsF3yYifnp9R+ON8O3Gf5/4EaFmbeT
# ElDCFBfExPMqtSvPZDqekodzX+4SK1PIZxCyR3gml8R3/wzhb6Li0mG7l0evQUD0
# FQAbKJMlBk863apeX4ALFZtrnCpnMlOjRb85LsjV5Ku4OhxQi1jlf8wR+za9C3DU
# ki60/yiWPu+XXwEUqGInIihECBbp7hfFWrnCCaOgahsVpgz8kKg/XN4OFq7rbh4q
# 5IkTauqFhHaE7HKM5bbIBkZ+YJs2SYvu7aHjw4Z8aRjaIbXhI1G+NtaNY7kSRrE4
# fAyC2X2zV5i4a0AuAMM40C1Wm3gTaNtRTHnka/pbynUlFjP+KqAZhOniJg4AUfjX
# sG+PG1LH2+w/sfDl1A8liXSZU1qJtUs3wBQFoSGEaGBeDQIDAQABo4ICJTCCAiEw
# HwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFIhC+HL9
# QlvsWsztP/I5wYwdfCFNMB0GA1UdEQQWMBSBEm5vcmVwbHlAdm13YXJlLmNvbTAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwgbUGA1UdHwSBrTCB
# qjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3Rl
# ZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcmwwU6BRoE+GTWh0
# dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWdu
# aW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMD4GA1UdIAQ3MDUwMwYGZ4EMAQQB
# MCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCBlAYI
# KwYBBQUHAQEEgYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBcBggrBgEFBQcwAoZQaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5j
# cnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEACQAYaQI6Nt2KgxdN
# 6qqfcHB33EZRSXkvs8O9iPZkdDjEx+2fgbBPLUvk9A7T8mRw7brbcJv4PLTYJDFo
# c5mlcmG7/5zwTOuIs2nBGXc/uxCnyW8p7kD4Y0JxPKEVQoIQ8lJS9Uy/hBjyakeV
# ef982JyzvDbOlLBy6AS3ZpXVkRY5y3Va+3v0R/0xJ+JRxUicQhiZRidq2TCiWEas
# d+tLL6jrKaBO+rmP52IM4eS9d4Yids7ogKEBAlJi0NbvuKO0CkgOlFjp1tOvD4sQ
# taHIMmqi40p4Tjyf/sY6yGjROXbMeeF1vlwbBAASPWpQuEIxrNHoVN30YfJyuOWj
# zdiJUTpeLn9XdjM3UlhfaHP+oIAKcmkd33c40SFRlQG9+P9Wlm7TcPxGU4wzXI8n
# Cw/h235jFlAAiWq9L2r7Un7YduqsheJVpGoXmRXJH0T2G2eNFS5/+2sLn98kN2Cn
# J7j6C242onjkZuGL2/+gqx8m5Jbpu9P4IAeTC1He/mX9j6XpIu+7uBoRVwuWD1i0
# N5SiUz7Lfnbr6Q1tHMXKDLFdwVKZos2AKEZhv4SU0WvenMJKDgkkhVeHPHbTahQf
# P1MetR8tdRs7uyTWAjPK5xf5DLEkXbMrUkpJ089fPvAGVHBcHRMqFA5egexOb6sj
# tKncUjJ1xAAtAExGdCh6VD2U5iYxghR4MIIUdAIBATB9MGkxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1
# c3RlZCBHNCBDb2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA7G
# 8rJ2oUagfQ5tk1e14QgwDQYJYIZIAWUDBAIBBQCggZYwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwKgYKKwYB
# BAGCNwIBDDEcMBqhGIAWaHR0cDovL3d3dy52bXdhcmUuY29tLzAvBgkqhkiG9w0B
# CQQxIgQgMf0cniPV/7zdFJLJt6HLYps3xpCrj1/519hPM5XtCHQwDQYJKoZIhvcN
# AQEBBQAEggGAnMRDd5rT8k9rnS4vX5vfKw+cHBWZD91PNthCQeL49iM3+69/yh3T
# sRswFpUO4jtlOB/085KehO5jlBsFIZAECSUJBMdnsNbHvRGje3WlXTdFQ9hPvvD0
# yKj6ii/epHR5e/pTTdB35DeXCnFFt3honySG68QwBJGWhbeYlrSb5U536zbKitqL
# k6EbJNZXlghmg1ea+LFiOG6FbZPTyeaforJYdGoKBU2l5cZCYOMhnxq05DxtN+fV
# YdR2MmY3gw1f1sRyrjVz8oIy1u/sASEEtwdmnmdRsZ/cGGOr1t+xNkVwN1CbWP9r
# u51WP2Z0mmypUkKSq9nHkv673nnTLwNaWxt61Cfn+gcemsUPcoSi3k76za5304uJ
# liMhHqgV+uCAZxMsDknfMwSZUK6/ReXQH57ZZ1uLlz1g5Z5iqNUej40XI1iGxa1j
# 6NsfiW3RPSXTS36lcjETCEuPBZfHlfwZdvq7puAQ0BBB+7jxOAahHTb9jwBPTAxa
# NxmhjiHLRGHdoYIRszCCEa8GCisGAQQBgjcDAwExghGfMIIRmwYJKoZIhvcNAQcC
# oIIRjDCCEYgCAQMxDzANBglghkgBZQMEAgEFADB4BgsqhkiG9w0BCRABBKBpBGcw
# ZQIBAQYJYIZIAYb9bAcBMDEwDQYJYIZIAWUDBAIBBQAEIAfLE8gJgs4Zbo2P04w6
# r0v9swfc5gDjlNa4N6iFA4HwAhEA061E4z2zd7XsNkXrSgAc+RgPMjAyMjA0MDQx
# NDE4NThaoIINfDCCBsYwggSuoAMCAQICEAp6SoieyZlCkAZjOE2Gl50wDQYJKoZI
# hvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRp
# bWVTdGFtcGluZyBDQTAeFw0yMjAzMjkwMDAwMDBaFw0zMzAzMTQyMzU5NTlaMEwx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEkMCIGA1UEAxMb
# RGlnaUNlcnQgVGltZXN0YW1wIDIwMjIgLSAyMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAuSqWI6ZcvF/WSfAVghj0M+7MXGzj4CUu0jHkPECu+6vE43hd
# flw26vUljUOjges4Y/k8iGnePNIwUQ0xB7pGbumjS0joiUF/DbLW+YTxmD4LvwqE
# EnFsoWImAdPOw2z9rDt+3Cocqb0wxhbY2rzrsvGD0Z/NCcW5QWpFQiNBWvhg02Us
# Pn5evZan8Pyx9PQoz0J5HzvHkwdoaOVENFJfD1De1FksRHTAMkcZW+KYLo/Qyj//
# xmfPPJOVToTpdhiYmREUxSsMoDPbTSSF6IKU4S8D7n+FAsmG4dUYFLcERfPgOL2i
# vXpxmOwV5/0u7NKbAIqsHY07gGj+0FmYJs7g7a5/KC7CnuALS8gI0TK7g/ojPNn/
# 0oy790Mj3+fDWgVifnAs5SuyPWPqyK6BIGtDich+X7Aa3Rm9n3RBCq+5jgnTdKEv
# sFR2wZBPlOyGYf/bES+SAzDOMLeLD11Es0MdI1DNkdcvnfv8zbHBp8QOxO9APhk6
# AtQxqWmgSfl14ZvoaORqDI/r5LEhe4ZnWH5/H+gr5BSyFtaBocraMJBr7m91wLA2
# JrIIO/+9vn9sExjfxm2keUmti39hhwVo99Rw40KV6J67m0uy4rZBPeevpxooya1h
# sKBBGBlO7UebYZXtPgthWuo+epiSUc0/yUTngIspQnL3ebLdhOon7v59emsCAwEA
# AaOCAYswggGHMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB
# /wQMMAoGCCsGAQUFBwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwH
# ATAfBgNVHSMEGDAWgBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUjWS3
# iSH+VlhEhGGn6m8cNo/drw0wWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVT
# dGFtcGluZ0NBLmNybDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRp
# bWVTdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAgEADS0jdKbR9fjqS5k/
# AeT2DOSvFp3Zs4yXgimcQ28BLas4tXARv4QZiz9d5YZPvpM63io5WjlO2IRZpbwb
# mKrobO/RSGkZOFvPiTkdcHDZTt8jImzV3/ZZy6HC6kx2yqHcoSuWuJtVqRprfdH1
# AglPgtalc4jEmIDf7kmVt7PMxafuDuHvHjiKn+8RyTFKWLbfOHzL+lz35FO/bgp8
# ftfemNUpZYkPopzAZfQBImXH6l50pls1klB89Bemh2RPPkaJFmMga8vye9A140pw
# SKm25x1gvQQiFSVwBnKpRDtpRxHT7unHoD5PELkwNuTzqmkJqIt+ZKJllBH7bjLx
# 9bs4rc3AkxHVMnhKSzcqTPNc3LaFwLtwMFV41pj+VG1/calIGnjdRncuG3rAM4r4
# SiiMEqhzzy350yPynhngDZQooOvbGlGglYKOKGukzp123qlzqkhqWUOuX+r4DwZC
# nd8GaJb+KqB0W2Nm3mssuHiqTXBt8CzxBxV+NbTmtQyimaXXFWs1DoXW4CzM4Awk
# uHxSCx6ZfO/IyMWMWGmvqz3hz8x9Fa4Uv4px38qXsdhH6hyF4EVOEhwUKVjMb9N/
# y77BDkpvIJyu2XMyWQjnLZKhGhH+MpimXSuX4IvTnMxttQ2uR2M4RxdbbxPaahBu
# H0m3RFu0CAqHWlkEdhGhp3cCExwwggauMIIElqADAgECAhAHNje3JFR82Ees/Shm
# Kl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERp
# Z2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIy
# MzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7
# MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1l
# U3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUG
# SbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOc
# iQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkr
# PkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rw
# N3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSm
# xR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu
# 9Yemj052FVUmcJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirH
# kr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506
# o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklN
# iyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGT
# yYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgA
# DoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0T
# AQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYD
# VR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNV
# HR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1s
# BwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPP
# MFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKW
# b8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpP
# kWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXa
# zPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKv
# xMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl6
# 3f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YB
# T70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4n
# LCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvt
# lUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm
# 2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqh
# K/bt1nz8MYIDdjCCA3ICAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5
# NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAKekqInsmZQpAGYzhNhpedMA0GCWCG
# SAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAcBgkqhkiG
# 9w0BCQUxDxcNMjIwNDA0MTQxODU4WjArBgsqhkiG9w0BCRACDDEcMBowGDAWBBSF
# CPOGUVyz0wd9trS3wH8bSl5B3jAvBgkqhkiG9w0BCQQxIgQg5mxJR5Xsb5XZg2k/
# NoHLn6RcjfgUj47qIUj4jfglCfkwNwYLKoZIhvcNAQkQAi8xKDAmMCQwIgQgnaaQ
# FcNJxsGJeEW6NYKtcMiPpCk722q+nCvSU5J55jswDQYJKoZIhvcNAQEBBQAEggIA
# SahjoW3o43kTsnu65UqH9D1UspuBQyJFmLlfgC1BrZSZpeSfKPLY37N8hsyYQbWu
# A8arxRDc3Bspok5AxOgXCzeyNKuBqizic9v5l0tB5EQWhLDrvrcvUhmjwB+bavbB
# T730dOJ71PWXxQ+goEQwU5s2Cf+WJ4sT4Q8+RZ148B6H10nXtvLPItL9RtSQy3+9
# FIxA7mo4Lk6teQSIce8ZsSpDqsPyiay3ysZs5VdxfiFyhxfTjjIqrvV1Q6ovdoTk
# bPCIkSoDSwjkaaAJHcnldt1fVTJyqu7ZeL22j5x5AIKOXH+OuU3337jVNe2VbpSC
# E+9OaCA1LA4Ft7+crG50xVh5iJdht7vbhSRS3vcWN4bGlby8uNVutKHQ15I1vaEM
# 52NO71TJp/HT4GP4wMN0UYX5H12nZkrOkGtVuzUFQZfvItCSFh/0dAydqEYUGVZn
# D5sHPWABheu+PG2Y+MThD/8sPoTGXND+YqgNNvmjAyuoIbGaZx++Zg9Rgc3/0Gui
# Y+0YKF7eMAGYFyaD7vc63m8ImT3gAKh7Q14XiPQPG0A245BugO+lxjfIui0mAMa8
# SDBRkSLFui6e8B1mRObzKYZ7G5Zu8rsXa0HD8Tk+NR47gVXvBdl9u5AdZCJy0sVt
# Sx4yHjkp27ju9phdrvftor81l74IJhtbuWtgLbhZN9M=
# SIG # End signature block
