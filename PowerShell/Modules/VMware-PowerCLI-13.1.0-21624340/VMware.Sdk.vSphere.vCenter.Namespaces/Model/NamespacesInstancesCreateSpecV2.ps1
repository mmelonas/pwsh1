#
# Namespaces Paths
# The vcenter namespaces package provides services for managing namespaces related operations.
# Contact: powercli@vmware.com
# Generated by OpenAPI Generator: https://openapi-generator.tech
#

<#
.DESCRIPTION

The Instances.CreateSpecV2 structure contains the specification required to set up a namespace on a Supervisor cluster.

.PARAMETER Supervisor
Identifier for the sSupervisor hosting the namespace. When clients pass a value of this structure as a parameter, the field must be an identifier for the resource type: com.vmware.vcenter.namespace_management.supervisor.Supervisor. When operations return a value of this structure as a result, the field will be an identifier for the resource type: com.vmware.vcenter.namespace_management.supervisor.Supervisor.
.PARAMETER Namespace
Identifier of the namespace. This has DNS_LABEL restrictions as specified in . This must be an alphanumeric (a-z and 0-9) string and with maximum length of 63 characters and with the '-' character allowed anywhere except the first or last character. This name is unique across all Namespaces in this vCenter server. In this version, this maps to the name of a Kubernetes namespace. When clients pass a value of this structure as a parameter, the field must be an identifier for the resource type: com.vmware.vcenter.namespaces.Instance. When operations return a value of this structure as a result, the field will be an identifier for the resource type: com.vmware.vcenter.namespaces.Instance.
.PARAMETER Description
Description for the namespace. If unset, no description is added to the namespace.
.PARAMETER ResourceSpec
Resource quota on the namespace. Refer to com.vmware.vcenter.namespace_management.NamespaceResourceOptions.Info#createResourceQuotaType and use com.vmware.vcenter.namespace_management.NamespaceResourceOptions#get for retrieving the type for the value for this field. For an example of this, see ResourceQuotaOptionsV1. If unset, no resource limits will be set on the namespace.
.PARAMETER AccessList
Access controls associated with the namespace. If unset, only users with Administrator role can access the namespace.
.PARAMETER StorageSpecs
Storage associated with the namespace. If unset, storage policies will not be associated with the namespace which will prevent users from being able to provision pods with persistent storage on the namespace. Users will be able to provision pods which use local storage.
.PARAMETER Networks
vSphere Namespaces network objects to be associated with the namespace. The values of this list need to reference names of pre-existing com.vmware.vcenter.namespace_management.Networks.Info structures. The field must be left unset if the cluster hosting the namespace uses NSXT_CONTAINER_PLUGIN as the network provider, since the network(s) for this namespace will be managed by NSX-T Container Plugin. If field is unset when the cluster hosting the namespace uses VSPHERE_NETWORK as its network provider, the namespace will automatically be associated with the cluster's Supervisor Primary Workload Network. The field currently accepts at most only 1 vSphere Namespaces network object reference. When clients pass a value of this structure as a parameter, the field must contain identifiers for the resource type: com.vmware.vcenter.namespace_management.Network. When operations return a value of this structure as a result, the field will contain identifiers for the resource type: com.vmware.vcenter.namespace_management.Network.
.PARAMETER VmServiceSpec
No description available.
.PARAMETER Creator
No description available.
.PARAMETER NamespaceNetwork
No description available.
.OUTPUTS

NamespacesInstancesCreateSpecV2<PSCustomObject>

.LINK

Online Version: https://developer.vmware.com/docs/vsphere-automation/latest/vcenter/data-structures/Namespaces/Instances/CreateSpecV2/
#>

function Initialize-NamespacesInstancesCreateSpecV2 {
    [CmdletBinding(HelpURI = "https://developer.vmware.com/docs/vsphere-automation/latest/vcenter/data-structures/Namespaces/Instances/CreateSpecV2/")]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -is [string] })]
        ${Supervisor},
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -is [string] })]
        ${Namespace},
        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -is [string] })]
        ${Description},
        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        ${ResourceSpec},
        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]
        ${AccessList},
        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]
        ${StorageSpecs},
        [Parameter(Mandatory = $false)]
        [String[]]
        ${Networks},
        [Parameter(Mandatory = $false)]
        [PSTypeName("NamespacesInstancesVMServiceSpec")]
        [PSCustomObject]
        ${VmServiceSpec},
        [Parameter(Mandatory = $false)]
        [PSTypeName("NamespacesInstancesPrincipal")]
        [PSCustomObject]
        ${Creator},
        [Parameter(Mandatory = $false)]
        [PSTypeName("NamespacesInstancesNetworkCreateSpec")]
        [PSCustomObject]
        ${NamespaceNetwork}
    )

    Process {
        'Creating PSCustomObject: VMware.Sdk.vSphere.vCenter.Namespaces => vSphereNamespacesInstancesCreateSpecV2' | Write-Debug


        $PSO = [PSCustomObject]@{
            "PSTypeName" = "NamespacesInstancesCreateSpecV2"
            "supervisor" = ${Supervisor}
            "namespace" = ${Namespace}
            "description" = ${Description}
            "resource_spec" = ${ResourceSpec}
            "access_list" = ${AccessList}
            "storage_specs" = ${StorageSpecs}
            "networks" = ${Networks}
            "vm_service_spec" = ${VmServiceSpec}
            "creator" = ${Creator}
            "namespace_network" = ${NamespaceNetwork}
        }


        return $PSO
    }
}


# SIG # Begin signature block
# MIIrHQYJKoZIhvcNAQcCoIIrDjCCKwoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDyMsw0TtrGuxD2
# yt0qzyIfC9PP9JVKjZ1VMtdY5g6C66CCDdowggawMIIEmKADAgECAhAIrUCyYNKc
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
# tKncUjJ1xAAtAExGdCh6VD2U5iYxghyZMIIclQIBATB9MGkxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1
# c3RlZCBHNCBDb2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA7G
# 8rJ2oUagfQ5tk1e14QgwDQYJYIZIAWUDBAIBBQCggZYwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwKgYKKwYB
# BAGCNwIBDDEcMBqhGIAWaHR0cDovL3d3dy52bXdhcmUuY29tLzAvBgkqhkiG9w0B
# CQQxIgQgpAZeeuz4cchG58pUuK/yTPtiuziKwzE6cRNOgGXYP88wDQYJKoZIhvcN
# AQEBBQAEggGAjDBbxXUhYw3KVCg8j3Vdbb/of71803upSutop9XJN8bo3XNwwNoU
# CwUT8EjZEKJYIjLcOaYY0YazMyVTZcSD8dH5Wm6DomDFeiKYT++l8r+QpRf2aHCi
# 0Vm70VImsngNEM0HMbaavWOE74VFRaUkL+iZMImlVS1dyZp71ucT5BcjDnSJulQR
# JVf55djUqoDzcpRqe8NP3qyTx+kkfgyxJCVUFpPgD784x+zt5n3JAp0tMqpSgbif
# dfmorJbUp8zNsJu5t9Wy0mBI0D4ekrZkplIkU8zS8J2u+4i0TzR4ncIhVPDibbt5
# /RObwEl7mu/XFQFPYHHTGG5ggJjbsIHOLlc6/BepGghuVmPutQfeq8Xjgzm0UNKS
# j9MwFPtqbyfWoEq108r6zKKNKrsTGSPbNzJAGzblbSSiv47p1WKgG2OBSY8qBkVH
# SbiGY2GVYr2E+1SVYI2fHrDZXNfuOPKM+iF+JEColoURJyJjk1IlVmdMzPJ461x4
# uHkJJLA/0qkqoYIZ1DCCGdAGCisGAQQBgjcDAwExghnAMIIZvAYJKoZIhvcNAQcC
# oIIZrTCCGakCAQMxDTALBglghkgBZQMEAgEwgdwGCyqGSIb3DQEJEAEEoIHMBIHJ
# MIHGAgEBBgkrBgEEAaAyAgMwMTANBglghkgBZQMEAgEFAAQgeITmhT9DPLp8qZwf
# ol/0c4FojIodc8sEun+CRpq1eOsCFATvIuvn33fxLufW8umer7nFFsmqGA8yMDIz
# MDQxODE0NDc0MlowAwIBAaBXpFUwUzELMAkGA1UEBhMCQkUxGTAXBgNVBAoMEEds
# b2JhbFNpZ24gbnYtc2ExKTAnBgNVBAMMIEdsb2JhbHNpZ24gVFNBIGZvciBBZHZh
# bmNlZCAtIEc0oIIVZzCCBlgwggRAoAMCAQICEAHCnHr0eqYCWA6vMrEjsR0wDQYJ
# KoZIhvcNAQELBQAwWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# Mzg0IC0gRzQwHhcNMjIwNDA2MDc0NDEyWhcNMzMwNTA4MDc0NDEyWjBTMQswCQYD
# VQQGEwJCRTEZMBcGA1UECgwQR2xvYmFsU2lnbiBudi1zYTEpMCcGA1UEAwwgR2xv
# YmFsc2lnbiBUU0EgZm9yIEFkdmFuY2VkIC0gRzQwggGiMA0GCSqGSIb3DQEBAQUA
# A4IBjwAwggGKAoIBgQCj3qYhEhYSvCjgBPez1LDTAWiPU7YYWFtxoF7Y1kxz4Ffw
# uQwH94e5KYP+8NV1oUj/PbAcQLyCVWhIOgxG6z/DLJg0z8SYm3AbhhGNXhV8oQ3a
# 1nd9r+x+nBTspb8pauuKKRr+Dp8suhZNWFpjcQzbLrRwCudGEELue0V8/mRFlK/g
# 61CyUmcfcUM38eIYg0AQV5oV1/Lya56byVbbZ4MYePdlpAXM5hOFFP5fiWcBYfva
# xoMo1o1O3TQsGAMBhEjdFngl4dZIaa1cNZYhHqDDTxMAF8vCXtySTQRiyXj13qex
# hAqedDqC3ICUtwFtq6g5nhpdwXwBBl2Qez5dSijKKRCxs1nPAbghMMfZtfSXLDau
# UsezMiNug6b51CT3VvhhdXRO8garIoTI/WTlXxWl3Cd0qtLQ6bRIeNeYzLsf+NZG
# w3V1+p5FxpV1awcHqETdVnYozkpNAnlrT5Hi/Kyd67yKr3prbGQ0RvHMeBy8J/R1
# aKczyToXfopORD6D870CAwEAAaOCAZ4wggGaMA4GA1UdDwEB/wQEAwIHgDAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDAdBgNVHQ4EFgQUSTtntVeimeZ0GXoMWSw+COog
# e4swTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6
# Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wDAYDVR0TAQH/BAIwADCB
# kAYIKwYBBQUHAQEEgYMwgYAwOQYIKwYBBQUHMAGGLWh0dHA6Ly9vY3NwLmdsb2Jh
# bHNpZ24uY29tL2NhL2dzdHNhY2FzaGEzODRnNDBDBggrBgEFBQcwAoY3aHR0cDov
# L3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQvZ3N0c2FjYXNoYTM4NGc0LmNy
# dDAfBgNVHSMEGDAWgBTqFsZp5+PLV0U5M6TwQL7Qw71lljBBBgNVHR8EOjA4MDag
# NKAyhjBodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2NhL2dzdHNhY2FzaGEzODRn
# NC5jcmwwDQYJKoZIhvcNAQELBQADggIBAAiIpOqFiDNYa378AFUi029DaW98/r5D
# hjcOn1PaUZ7QPOMbmddRURkPUZAO2+6aRs99CuDG7BWC6z6uzAP6We2PpUqiGT7C
# X/0WgzFWUihLX8RFg2HrlgwgMKJ9ReqWbbL8dLj9TGGUaqew6qm/OI6YdnUHpvul
# 3AtvdXpk6TDXkZBi0OHLGeToLyeIQIyH2z/bFbBIjeKNlYwn86xJh7B86cSl4Nnc
# vvYNFbjeY519liutpK6UYDfQSJmo270vTvQAj7f8SNq2EEDEPznbVXe9CzysNqBK
# mRTg0DEeidInCnBQ3a1vZPpvjRr2UPQWEzAMGM7YaELVVeNaX8CggbwZvESwY4p+
# wCseVW7nHR4TZJlmZAmD6YHmPiv95HzsQ7ubbzVik2Sau1i4rwRuKLsKWOOFOSXU
# 44sVcwE6HctdkfyeRS6HtfBGnJTDaK36DutH2akl1ooK2J7vrKJepi6cWNG9Ub8S
# ctARm0zPm1K/p+pKlCL82nSzRdSzCdZoREAqH4ps2uVpcQAS+Mnf6pipKmqP1Jrg
# H6yZ4ehdPnk8RaQOCoYUoBXlkiCB8oKO86rJnF8cSXT8IbUo4IEN/7d/mIPAYNMB
# xWbMYbzCpAsDNzaaMiXCxeaDlPzQeb+D07xTteP+z+FxPgXbYo8kve9TqvKeUww/
# fGvw6iU4X3KqMIIGWTCCBEGgAwIBAgINAewckkDe/S5AXXxHdDANBgkqhkiG9w0B
# AQwFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSNjETMBEGA1UE
# ChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xODA2MjAwMDAw
# MDBaFw0zNDEyMTAwMDAwMDBaMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIFNIQTM4NCAtIEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# 8ALiMCP64BvhmnSzr3WDX6lHUsdhOmN8OSN5bXT8MeR0EhmW+s4nYluuB4on7lej
# xDXtszTHrMMM64BmbdEoSsEsu7lw8nKujPeZWl12rr9EqHxBJI6PusVP/zZBq6ct
# /XhOQ4j+kxkX2e4xz7yKO25qxIjw7pf23PMYoEuZHA6HpybhiMmg5ZninvScTD9d
# W+y279Jlz0ULVD2xVFMHi5luuFSZiqgxkjvyen38DljfgWrhsGweZYIq1CHHlP5C
# ljvxC7F/f0aYDoc9emXr0VapLr37WD21hfpTmU1bdO1yS6INgjcZDNCr6lrB7w/V
# mbk/9E818ZwP0zcTUtklNO2W7/hn6gi+j0l6/5Cx1PcpFdf5DV3Wh0MedMRwKLSA
# e70qm7uE4Q6sbw25tfZtVv6KHQk+JA5nJsf8sg2glLCylMx75mf+pliy1NhBEsFV
# /W6RxbuxTAhLntRCBm8bGNU26mSuzv31BebiZtAOBSGssREGIxnk+wU0ROoIrp1J
# ZxGLguWtWoanZv0zAwHemSX5cW7pnF0CTGA8zwKPAf1y7pLxpxLeQhJN7Kkm5XcC
# rA5XDAnRYZ4miPzIsk3bZPBFn7rBP1Sj2HYClWxqjcoiXPYMBOMp+kuwHNM3dITZ
# HWarNHOPHn18XpbWPRmwl+qMUJFtr1eGfhA3HWsaFN8CAwEAAaOCASkwggElMA4G
# A1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTqFsZp
# 5+PLV0U5M6TwQL7Qw71lljAfBgNVHSMEGDAWgBSubAWjkxPioufi1xzWx/B/yGdT
# oDA+BggrBgEFBQcBAQQyMDAwLgYIKwYBBQUHMAGGImh0dHA6Ly9vY3NwMi5nbG9i
# YWxzaWduLmNvbS9yb290cjYwNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5n
# bG9iYWxzaWduLmNvbS9yb290LXI2LmNybDBHBgNVHSAEQDA+MDwGBFUdIAAwNDAy
# BggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9y
# eS8wDQYJKoZIhvcNAQEMBQADggIBAH/iiNlXZytCX4GnCQu6xLsoGFbWTL/bGwdw
# xvsLCa0AOmAzHznGFmsZQEklCB7km/fWpA2PHpbyhqIX3kG/T+G8q83uwCOMxoX+
# SxUk+RhE7B/CpKzQss/swlZlHb1/9t6CyLefYdO1RkiYlwJnehaVSttixtCzAsw0
# SEVV3ezpSp9eFO1yEHF2cNIPlvPqN1eUkRiv3I2ZOBlYwqmhfqJuFSbqtPl/Kufn
# SGRpL9KaoXL29yRLdFp9coY1swJXH4uc/LusTN763lNMg/0SsbZJVU91naxvSsgu
# arnKiMMSME6yCHOfXqHWmc7pfUuWLMwWaxjN5Fk3hgks4kXWss1ugnWl2o0et1sv
# iC49ffHykTAFnM57fKDFrK9RBvARxx0wxVFWYOh8lT0i49UKJFMnl4D6SIknLHni
# POWbHuOqhIKJPsBK9SH+YhDtHTD89szqSCd8i3VCf2vL86VrlR8EWDQKie2CUOTR
# e6jJ5r5IqitV2Y23JSAOG1Gg1GOqg+pscmFKyfpDxMZXxZ22PLCLsLkcMe+97xTY
# FEBsIB3CLegLxo1tjLZx7VIh/j72n585Gq6s0i96ILH0rKod4i0UnfqWah3GPMrz
# 2Ry/U02kR1l8lcRDQfkl4iwQfoH5DZSnffK1CfXYYHJAUJUg1ENEvvqglecgWbZ4
# xqRqqiKbMIIFRzCCBC+gAwIBAgINAfJAQkDO/SLb6Wxx/DANBgkqhkiG9w0BAQwF
# ADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzETMBEGA1UEChMK
# R2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xOTAyMjAwMDAwMDBa
# Fw0yOTAzMTgxMDAwMDBaMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAt
# IFI2MRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAlQfoc8pm+ewUyns89w0I8bRF
# CyyCtEjG61s8roO4QZIzFKRvf+kqzMawiGvFtonRxrL/FM5RFCHsSt0bWsbWh+5N
# OhUG7WRmC5KAykTec5RO86eJf094YwjIElBtQmYvTbl5KE1SGooagLcZgQ5+xIq8
# ZEwhHENo1z08isWyZtWQmrcxBsW+4m0yBqYe+bnrqqO4v76CY1DQ8BiJ3+QPefXq
# oh8q0nAue+e8k7ttU+JIfIwQBzj/ZrJ3YX7g6ow8qrSk9vOVShIHbf2MsonP0KBh
# d8hYdLDUIzr3XTrKotudCd5dRC2Q8YHNV5L6frxQBGM032uTGL5rNrI55KwkNrfw
# 77YcE1eTtt6y+OKFt3OiuDWqRfLgnTahb1SK8XJWbi6IxVFCRBWU7qPFOJabTk5a
# C0fzBjZJdzC8cTflpuwhCHX85mEWP3fV2ZGXhAps1AJNdMAU7f05+4PyXhShBLAL
# 6f7uj+FuC7IIs2FmCWqxBjplllnA8DX9ydoojRoRh3CBCqiadR2eOoYFAJ7bgNYl
# +dwFnidZTHY5W+r5paHYgw/R/98wEfmFzzNI9cptZBQselhP00sIScWVZBpjDnk9
# 9bOMylitnEJFeW4OhxlcVLFltr+Mm9wT6Q1vuC7cZ27JixG1hBSKABlwg3mRl5HU
# Gie/Nx4yB9gUYzwoTK8CAwEAAaOCASYwggEiMA4GA1UdDwEB/wQEAwIBBjAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBSubAWjkxPioufi1xzWx/B/yGdToDAfBgNV
# HSMEGDAWgBSP8Et/qC5FJK5NUPpjmove4t0bvDA+BggrBgEFBQcBAQQyMDAwLgYI
# KwYBBQUHMAGGImh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9yb290cjMwNgYD
# VR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9yb290LXIz
# LmNybDBHBgNVHSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93
# d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQEMBQADggEB
# AEmsXsWD81rLYSpNl0oVKZ/kFJCqCfnEep81GIoKMxVtcociTkE/bQqeGK7b4l/8
# ldEsmBQ7jsHwNll5842Bz3T2GKTk4WjP739lWULpylU5vNPFJu5xOPrXIQMPt07Z
# W2BqQ7R9CdBgYd2q7QBeTjIe4LJsnjyywruY05B2ammtGtyoidpYT9LCizJKzlT7
# OOk7Bwt1ChHbC3wlJ/GsJs8RU+bcxuJhNTL0zt2D4xk668Joo3IAyCQ8TrhTPLEX
# q+Y1LPnTQinmX2ADrEJhprFXajNC3zUxhso+NyvaxNok9U4S8ra5t0fquyCtYRa3
# oDPjLYmnvLM8AX8jGoAJNOkwggNfMIICR6ADAgECAgsEAAAAAAEhWFMIojANBgkq
# hkiG9w0BAQsFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzET
# MBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0wOTAz
# MTgxMDAwMDBaFw0yOTAzMTgxMDAwMDBaMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24g
# Um9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9i
# YWxTaWduMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzCV2kHkGeCIW
# 9cCDtoTKKJ79BXYRxa2IcvxGAkPHsoqdBF8kyy5L4WCCRuFSqwyBR3Bs3WTR6/Us
# ow+CPQwrrpfXthSGEHm7OxOAd4wI4UnSamIvH176lmjfiSeVOJ8G1z7JyyZZDXPe
# sMjpJg6DFcbvW4vSBGDKSaYo9mk79svIKJHlnYphVzesdBTcdOA67nIvLpz70Lu/
# 9T0A4QYz6IIrrlOmOhZzjN1BDiA6wLSnoemyT5AuMmDpV8u5BJJoaOU4JmB1sp93
# /5EU764gSfytQBVI0QIxYRleuJfvrXe3ZJp6v1/BE++bYvsNbOBUaRapA9pu6YOT
# cXbGaYWCFwIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB
# /zAdBgNVHQ4EFgQUj/BLf6guRSSuTVD6Y5qL3uLdG7wwDQYJKoZIhvcNAQELBQAD
# ggEBAEtA28BQqv7IDO/3llRFSbuWAAlBrLMThoYoBzPKa+Z0uboALa6kCtP18fEP
# ir9zZ0qDx0R7eOCvbmxvAymOMzlFw47kuVdsqvwSluxTxi3kJGy5lGP73FNoZ1Y+
# g7jPNSHDyWj+ztrCU6rMkIrp8F1GjJXdelgoGi8d3s0AN0GP7URt11Mol37zZwQe
# FdeKlrTT3kwnpEwbc3N29BeZwh96DuMtCK0KHCz/PKtVDg+Rfjbrw1dJvuEuLXxg
# i8NBURMjnc73MmuUAaiZ5ywzHzo7JdKGQM47LIZ4yWEvFLru21Vv34TuBQlNvSjY
# cs7TYlBlHuuSl4Mx2bO1ykdYP18xggNJMIIDRQIBATBvMFsxCzAJBgNVBAYTAkJF
# MRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWdu
# IFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4NCAtIEc0AhABwpx69HqmAlgOrzKxI7Ed
# MAsGCWCGSAFlAwQCAaCCAS0wGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMCsG
# CSqGSIb3DQEJNDEeMBwwCwYJYIZIAWUDBAIBoQ0GCSqGSIb3DQEBCwUAMC8GCSqG
# SIb3DQEJBDEiBCAG83D3SgYSPgxHlGdW0V8e7416NOU/KWAL5DRx0EQQ5TCBsAYL
# KoZIhvcNAQkQAi8xgaAwgZ0wgZowgZcEIK+AMe1uyzkUREiVvQsdDOsSlZTbXgws
# bfa+crElQkfQMHMwX6RdMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxT
# aWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAt
# IFNIQTM4NCAtIEc0AhABwpx69HqmAlgOrzKxI7EdMA0GCSqGSIb3DQEBCwUABIIB
# gASsG9LXhXbj5gpCf5AcQ8aC+I4FjN4qYyeN/ra2OzqBs7UIs6MHTiTw1Zy0npVw
# 0iFqnAo5qvZgs0BC+twpmqO5F9AoBy6hT9TrQatHG+HSYJ27op2WENZKVXYcaMcA
# gC913cZxYi75MGqfwQP4/1u0pkr2GiZSkvtP8VPO6Pw4dWqDdcY8O+U+lcLppf+X
# Isqlrnr2uZed21QyLq5ytVd+ke70mqa9v5Eks/i3vS7Wj6RlciYX6KuSr4FmWb/P
# A3I0a7Ak3I3kIVT1laBC9MjphS1WkTAHc91MlV/JROZoz1ePd8C5F9XXO0ng6iGJ
# wvZv9SGkt4zCx/M1WnJmVOjONvTyd4AqKqbEycpg9BwxBW78+mPThFtrMvLwBIky
# +FGaLBL3qe63Z3IB44d66J5I381F6zNw5XUCkl3KlSSysbPfoG+g5uKtVkv3/k6H
# ra8P11vx6ziUnQ1snnj8tg8pUIcZVK4ymBMgnh3EhWYt8GGnTNu7ICxUkdOZlF/U
# tg==
# SIG # End signature block
