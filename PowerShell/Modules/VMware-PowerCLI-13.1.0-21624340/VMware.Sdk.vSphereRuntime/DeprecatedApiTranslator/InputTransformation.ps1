<#
.SYNOPSIS
Creates empty input transformation sctructure

.DESCRIPTION
Input transformation structure contains information Path, Header, Query, and Body input of an API operation

.EXAMPLE
New-InputTransformationStructure

#>
function New-InputTransformationStructure {
    [PSCustomObject]@{
        Path = $null
        Header = $null
        Query = $null
        Body = $null
    }
}

<#
.SYNOPSIS
Adds Path, Header, Query, or Body to an existing InputTransformationStructure

.DESCRIPTION
Combines two InputTransformationStructure incrementing the $Base InputTransformationStructure with the content from the $additionInputStructure

.PARAMETER Base
The InputTransformationStructure that will be extended with the data from $Addition

.PARAMETER Addition
InputTransformationStructure which content will be added to the $Base

.EXAMPLE
Join-InputTransformationStructure -Base [ref]$baseInputStructure -Addition $additionInputStructure
#>
function Join-InputTransformationStructure {
    param(
        [Parameter(Mandatory)]
        [ref]
        $Base,

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Addition)

    foreach ($htProperty in 'Path', 'Header', 'Query') {
        if ($null -ne $Addition.$htProperty) {
            if ($null -eq $Base.Value.$htProperty) {
                $Base.Value.$htProperty = $Addition.$htProperty
            } else {
                foreach ($htKeyValue in $Addition.$htProperty.GetEnumerator()) {
                    $Base.Value.$htProperty[$htKeyValue.Key] = $htKeyValue.Value
                }
            }
        }
    }

    if ($null -ne $Addition.Body) {
        if ($null -eq $Base.Value.Body) {
            $Base.Value.Body = $Addition.Body
        } else {
            $propsToAdd = $Addition.Body | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            foreach ($prop in $propsToAdd) {
                $Base.Value.Body | Add-Member -MemberType NoteProperty -Name $prop -Value $Addition.Body.$prop
            }
        }
    }
}

<#
.SYNOPSIS
Rearranges Path input of an API operation

.DESCRIPTION
Rearranges Path API operation input to Header, Query, and Body if needed from the OperationTranslateSchema

.PARAMETER OperationTranslateSchema
Translation Schema Object retrieved from Get-OperationTranslationSchema

.PARAMETER PathParams
Hashtable with Key name of the path parameter and Value the argument
#>
function Format-PathParams {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $OperationTranslateSchema,


        [Parameter(Mandatory)]
        [hashtable]
        $PathParams
    )

    $result = New-InputTransformationStructure

    if ( $OperationTranslateSchema.OldInPathParams -ne $OperationTranslateSchema.NewInPathParams ) {
        # Process Path parameter from New API to different place in the Old API
        $OperationTranslateSchema.NewInPathParams | Foreach-Object {
            $newPathParam = $_
            if ($null -eq $OperationTranslateSchema.OldInPathParams -or `
                $OperationTranslateSchema.OldInPathParams -notcontains $newPathParam) {
                # Moving Path parameter from New API to different place in the old API

                # Check Body
                if ($null -ne $OperationTranslateSchema.OldInBodyStruct) {
                    $bodyPropNames = $OperationTranslateSchema.OldInBodyStruct | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
                    if ( $bodyPropNames -contains $newPathParam) {
                        if ($null -eq $result.Body) {
                            # initialize body on first param
                            $result.Body = @{}
                        }

                        # fill the argument value in the body
                        $result.Body[$newPathParam] = $PathParams[$newPathParam]
                    }
                }

                # Check Query
                if ($null -ne $OperationTranslateSchema.OldInQueryParams) {
                    if ( $OperationTranslateSchema.OldInQueryParams -contains $newPathParam) {
                        if ($null -eq $result.Query) {
                            # initialize query on first param
                            $result.Query = @{}
                        }

                        # fill the argument value in the query params
                        $result.Query[$newPathParam] = $PathParams[$newPathParam]
                    }
                }

                # Check Header
                if ($null -ne $OperationTranslateSchema.OldInHeaderParams) {
                    if ( $OperationTranslateSchema.OldInHeaderParams -contains $newPathParam) {
                        if ($null -eq $result.Header) {
                            # initialize query on first param
                            $result.Header = @{}
                        }

                        # fill the argument value in the Header params
                        $result.Header[$newPathParam] = $PathParams[$newPathParam]
                    }
                }
            }
        }
    }

    # return
    $result
}

<#
.SYNOPSIS
Rearranges Headers input of an API operation

.DESCRIPTION
Rearranges Headers API operation input to Path, Query, and Body if needed from the OperationTranslateSchema

.PARAMETER OperationTranslateSchema
Translation Schema Object retrieved from Get-OperationTranslationSchema

.PARAMETER Headers
Heashtable with HTTP Headers of an API. The function modifies the headers.
#>
function Format-Headers {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $OperationTranslateSchema,

        [Parameter(Mandatory)]
        [hashtable]
        $Headers
    )

    $result = New-InputTransformationStructure

    if ( $OperationTranslateSchema.OldInHeaderParams -ne $OperationTranslateSchema.NewInHeaderParams ) {
        # Process Header parameter from New API to different place in the Old API
        $OperationTranslateSchema.NewInHeaderParams | Foreach-Object {
            $newHeaderParam = $_
            if ($null -eq $OperationTranslateSchema.OldInHeaderParams -or `
                $OperationTranslateSchema.OldInHeaderParams -notcontains $newPathParam) {

                # Moving Header parameter from New API to different place in the old API

                # Check Path
                if ($null -ne $OperationTranslateSchema.OldInPathParams) {
                    if ( $OperationTranslateSchema.OldInPathParams -contains $newHeaderParam) {
                        if ($null -eq $result.Path) {
                            # initialize query on first param
                            $result.Path = @{}
                        }

                        # fill the argument value in the path params
                        $result.Path[$newHeaderParam] = $Headers[$newHeaderParam]
                        # remove the parameter from headers
                        $Headers.Remove($newHeaderParam)
                    }
                }

                # Check Body
                if ($null -ne $OperationTranslateSchema.OldInBodyStruct) {
                    $bodyPropNames = $OperationTranslateSchema.OldInBodyStruct | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
                    if ( $bodyPropNames -contains $newHeaderParam) {
                        if ($null -eq $result.Body) {
                            # initialize body on first param
                            $result.Body = @{}
                        }

                        # fill the argument value in the body
                        $result.Body[$newHeaderParam] = $Headers[$newHeaderParam]
                        # remove the parameter from headers
                        $Headers.Remove($newHeaderParam)
                    }
                }

                # Check Query
                if ($null -ne $OperationTranslateSchema.OldInQueryParams) {
                    if ( $OperationTranslateSchema.OldInQueryParams -contains $newHeaderParam) {
                        if ($null -eq $result.Query) {
                            # initialize query on first param
                            $result.Query = @{}
                        }

                        # fill the argument value in the query params
                        $result.Query[$newHeaderParam] = $Headers[$newHeaderParam]
                        # remove the parameter from headers
                        $Headers.Remove($newHeaderParam)
                    }
                }
            }
        }
    }

    # return
    $result
}

<#
.SYNOPSIS
Rearranges Body input of an API operation

.DESCRIPTION
Rearranges Body fields of an API operation input to Path, Query, and Headers if needed from the OperationTranslateSchema

.PARAMETER OperationTranslateSchema
Translation Schema Object retrieved from Get-OperationTranslationSchema

.PARAMETER Body
PSCustomObject with the HTTP Body of an API. The function modifies the body object.
#>
function Format-Body {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $OperationTranslateSchema,

        [Parameter(Mandatory)]
        [ref]
        $Body
    )

    $result = New-InputTransformationStructure

    # Only Top Level Body Fields can be moved to Path, Query, or Headers
    $newBodyPropNames = $null
    if ($null -ne $OperationTranslateSchema.NewInBodyStruct) {
        $newBodyPropNames = $OperationTranslateSchema.NewInBodyStruct | Get-Member -MemberType NoteProperty | Foreach-Object { $_.Name }
    }

    $oldBodyPropNames = $null
    if ($null -ne $OperationTranslateSchema.OldInBodyStruct) {
        $oldBodyPropNames = $OperationTranslateSchema.OldInBodyStruct | Get-Member -MemberType NoteProperty | Foreach-Object { $_.Name }
    }

    $bodyFieldsToRemove = @()
    if ( $oldBodyPropNames -ne $newBodyPropNames ) {
        # Process Body properties from the New API to different place in the Old API
        $newBodyPropNames | Foreach-Object {
            $newBodyProp = $_
            if ($null -eq $oldBodyPropNames -or `
                $oldBodyPropNames -notcontains $newBodyProp) {

                # Moving Body field from New API to different place in the old API

                # Check Path
                if ($null -ne $OperationTranslateSchema.OldInPathParams) {
                    if ( $OperationTranslateSchema.OldInPathParams -contains $newBodyProp) {
                        if ($null -eq $result.Path) {
                            # initialize query on first param
                            $result.Path = @{}
                        }

                        if ($null -ne $Body.Value) {
                            # fill the argument value in the path params
                            $result.Path[$newBodyProp] = $Body.Value.$newBodyProp
                            # Collect body fileds that have to be removed from the Body structure
                            $bodyFieldsToRemove += $newBodyProp
                        }
                    }
                }

                # Check Headers
                if ($null -ne $OperationTranslateSchema.OldInHeaderParams) {
                    if ( $OperationTranslateSchema.OldInHeaderParams -contains $newBodyProp) {
                        if ($null -eq $result.Header) {
                            # initialize query on first param
                            $result.Header = @{}
                        }

                        if ($null -ne $Body.Value) {
                            # fill the argument value in the headers
                            $result.Header[$newBodyProp] = $Body.Value.$newBodyProp
                            # Collect body fileds that have to be removed from the Body structure
                            $bodyFieldsToRemove += $newBodyProp
                        }
                    }
                }

                # Check Query
                if ($null -ne $OperationTranslateSchema.OldInQueryParams) {
                    if ( $OperationTranslateSchema.OldInQueryParams -contains $newBodyProp) {
                        if ($null -eq $result.Query) {
                            # initialize query on first param
                            $result.Query = @{}
                        }

                        if ($null -ne $Body) {
                            # fill the argument value in the query params
                            $result.Query[$newBodyProp] = $Body.Value.$newBodyProp
                            # Collect body fileds that have to be removed from the Body structure
                            $bodyFieldsToRemove += $newBodyProp
                        }
                    }
                }
            }
        }
    }

    # Remove transformed properties from the body structure
    if ($bodyFieldsToRemove.Count -gt 0 -and $null -ne $Body.Value) {
        $bodyPropNames = $Body.Value | Get-Member -MemberType NoteProperty | Foreach-Object { $_.Name }
        $transformedBody = @{}
        foreach ($bodyProp in $bodyPropNames) {
            if ($bodyFieldsToRemove -notcontains $bodyProp) {
                $transformedBody[$bodyProp] = $Body.Value.$bodyProp
            }
        }

        $Body.Value = [PSCustomObject]$transformedBody
    }

    # return
    $result
}
# SIG # Begin signature block
# MIIohgYJKoZIhvcNAQcCoIIodzCCKHMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDOLpl0Jbn+Cr0B
# y/BCCZ7Vuev3KtlSXHw1nv/RxHXm4qCCDdowggawMIIEmKADAgECAhAIrUCyYNKc
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
# tKncUjJ1xAAtAExGdCh6VD2U5iYxghoCMIIZ/gIBATB9MGkxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1
# c3RlZCBHNCBDb2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA7G
# 8rJ2oUagfQ5tk1e14QgwDQYJYIZIAWUDBAIBBQCggZYwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwKgYKKwYB
# BAGCNwIBDDEcMBqhGIAWaHR0cDovL3d3dy52bXdhcmUuY29tLzAvBgkqhkiG9w0B
# CQQxIgQgeeQKtKzmkt53f+fnmw/Qf0HKd9Er399QQApy1tDiz4MwDQYJKoZIhvcN
# AQEBBQAEggGANKW7gA38/23hCH4qZbN4PUIgn3TvcEuobAezAB7/Ok+x/JUHhSfn
# oait/rKVfnY9nMPVqVpRmZJkG+fyT+XJVpHAzSaEoOLSxgWGa8DrQMtIbvPX/lZp
# k63gE+LnkLJG77TaJI9LvGlSRGbRyS77rJ1813sHnHY5OYh+8oq5o4dr/c0B6rpX
# kbCw95eWRizLirUz6XpR4OICqavgsjqNgCijcJrypAG1Lo21/Jqa4GWqRpUPpVOz
# HlXfEH4VSigQzQBiokeok6cLB5pICq+HkYenBqqY/Kotfq9OtJQYwlZhntD7RvN+
# EVRm7NOaS+TycODflfUYMO8CkqhxH3ZJ6eu3x/ItiplEtMg0u1O0w6eOIvyWEFAI
# SuCriiusHldG8aeJ60cJXhFD/Tx1WNPeSa1USJy+Vg8OitF0ZZGh3EzsivxMnfzp
# y1S6JKva1X+IfPV8zt4QgaYsdTNI5CchLz9sOHlu8zx4IBUDpgBfAca8BeAN/y1N
# U6Z+71SEIJ/eoYIXPTCCFzkGCisGAQQBgjcDAwExghcpMIIXJQYJKoZIhvcNAQcC
# oIIXFjCCFxICAQMxDzANBglghkgBZQMEAgEFADB3BgsqhkiG9w0BCRABBKBoBGYw
# ZAIBAQYJYIZIAYb9bAcBMDEwDQYJYIZIAWUDBAIBBQAEIFo5hDCivJpWUZIbmbm8
# A+HPBLUAVIJmDbnbbSb+tWM8AhBD+FP04wgXPuuPk3kApaEbGA8yMDIzMDQxODE0
# NTE0MlqgghMHMIIGwDCCBKigAwIBAgIQDE1pckuU+jwqSj0pB4A9WjANBgkqhkiG
# 9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGlt
# ZVN0YW1waW5nIENBMB4XDTIyMDkyMTAwMDAwMFoXDTMzMTEyMTIzNTk1OVowRjEL
# MAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSQwIgYDVQQDExtEaWdpQ2Vy
# dCBUaW1lc3RhbXAgMjAyMiAtIDIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQDP7KUmOsap8mu7jcENmtuh6BSFdDMaJqzQHFUeHjZtvJJVDGH0nQl3PRWW
# CC9rZKT9BoMW15GSOBwxApb7crGXOlWvM+xhiummKNuQY1y9iVPgOi2Mh0KuJqTk
# u3h4uXoW4VbGwLpkU7sqFudQSLuIaQyIxvG+4C99O7HKU41Agx7ny3JJKB5MgB6F
# VueF7fJhvKo6B332q27lZt3iXPUv7Y3UTZWEaOOAy2p50dIQkUYp6z4m8rSMzUy5
# Zsi7qlA4DeWMlF0ZWr/1e0BubxaompyVR4aFeT4MXmaMGgokvpyq0py2909ueMQo
# P6McD1AGN7oI2TWmtR7aeFgdOej4TJEQln5N4d3CraV++C0bH+wrRhijGfY59/XB
# T3EuiQMRoku7mL/6T+R7Nu8GRORV/zbq5Xwx5/PCUsTmFntafqUlc9vAapkhLWPl
# WfVNL5AfJ7fSqxTlOGaHUQhr+1NDOdBk+lbP4PQK5hRtZHi7mP2Uw3Mh8y/CLiDX
# gazT8QfU4b3ZXUtuMZQpi+ZBpGWUwFjl5S4pkKa3YWT62SBsGFFguqaBDwklU/G/
# O+mrBw5qBzliGcnWhX8T2Y15z2LF7OF7ucxnEweawXjtxojIsG4yeccLWYONxu71
# LHx7jstkifGxxLjnU15fVdJ9GSlZA076XepFcxyEftfO4tQ6dwIDAQABo4IBizCC
# AYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1Ud
# IwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBRiit7QYfyPMRTt
# lwvNPSqUFN9SnDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1w
# aW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQBVqioa80bzeFc3MPx140/WhSPx
# /PmVOZsl5vdyipjDd9Rk/BX7NsJJUSx4iGNVCUY5APxp1MqbKfujP8DJAJsTHbCY
# idx48s18hc1Tna9i4mFmoxQqRYdKmEIrUPwbtZ4IMAn65C3XCYl5+QnmiM59G7hq
# opvBU2AJ6KO4ndetHxy47JhB8PYOgPvk/9+dEKfrALpfSo8aOlK06r8JSRU1Nlma
# D1TSsht/fl4JrXZUinRtytIFZyt26/+YsiaVOBmIRBTlClmia+ciPkQh0j8cwJvt
# fEiy2JIMkU88ZpSvXQJT657inuTTH4YBZJwAwuladHUNPeF5iL8cAZfJGSOA1zZa
# X5YWsWMMxkZAO85dNdRZPkOaGK7DycvD+5sTX2q1x+DzBcNZ3ydiK95ByVO5/zQQ
# Z/YmMph7/lxClIGUgp2sCovGSxVK05iQRWAzgOAj3vgDpPZFR+XOuANCR+hBNnF3
# rf2i6Jd0Ti7aHh2MWsgemtXC8MYiqE+bvdgcmlHEL5r2X6cnl7qWLoVXwGDneFZ/
# au/ClZpLEQLIgpzJGgV8unG1TnqZbPTontRamMifv427GFxD9dAq6OJi7ngE273R
# +1sKqHB+8JeEeOMIA11HLGOoJTiXAdI/Otrl5fbmm9x+LMz/F0xNAKLY1gEOuIvu
# 5uByVYksJxlh9ncBjDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJ
# KoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQg
# VHJ1c3RlZCBSb290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVow
# YzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQD
# EzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGlu
# ZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklR
# VcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54P
# Mx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupR
# PfDWVtTnKC3r07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvo
# hGS0UvJ2R/dhgxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV
# 5huowWR0QKfAcsW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYV
# VSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6i
# c/rnH1pslPJSlRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/Ci
# PMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5
# K6jzRWC8I41Y99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oi
# qMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuld
# yF4wEr1GnrXTdrnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAG
# AQH/AgEAMB0GA1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAW
# gBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRS
# b290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkq
# hkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvH
# UF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0M
# CIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCK
# rOX9jLxkJodskr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rA
# J4JErpknG6skHibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZ
# xhOACcS2n82HhyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScs
# PT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1M
# rfvElXvtCl8zOYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXse
# GYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWY
# MbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYp
# hwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPww
# ggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9v
# dCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskh
# PfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIP
# Uh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvu
# INXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59U
# WI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4
# AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJoz
# QL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw
# 4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sE
# AMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZD
# pBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsx
# xcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+Y
# HS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQW
# BBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYun
# pyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJ
# KoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqka
# uyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP
# +fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8Lpuny
# NDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiE
# n2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4
# VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN2MIIDcgIBATB3MGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0ECEAxNaXJLlPo8Kko9KQeAPVowDQYJYIZIAWUDBAIBBQCggdEwGgYJKoZIhvcN
# AQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yMzA0MTgxNDUxNDJa
# MCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFPOHIk2GM4KSNamUvL2Plun+HHxzMC8G
# CSqGSIb3DQEJBDEiBCD8V9IcSkjHlXbGS8DcTxaTK+14DCApeajBJOo34OR1LjA3
# BgsqhkiG9w0BCRACLzEoMCYwJDAiBCDH9OG+MiiJIKviJjq+GsT8T+Z4HC1k0EyA
# dVegI7W2+jANBgkqhkiG9w0BAQEFAASCAgAqncDjw+932qscRjwwYxdc1Oz+0h4Y
# rF+PK2qd2YZHl4ke06pbF+drnDHQi1VJUB3h29aRn1Gi3M5mbs2VLRZhEUvNfWv7
# hvts2HTJLqSX1F3BBt1BZOYVX+P6nIAHTY+Ui/KIaj5LLAbZGPTc9NId03dqdZ2M
# OpYbYhMs1LgNL1R6S/GGX93QQxCL694LH14oKi0vwwb7cxWJds3Fyb7qTjRYmxAD
# CEk4DqPQk5/QL8NC22Em9gFY44PJucAHVZyVqatHeEA9bJdBcsXDm5Zkp1O+5uPf
# MH14TU04sjGLI6cKpn+vIt2oju/BvZoK/4dvRvFMVd+6YZRZ3HHEUhWLlKKg2gkG
# Ai/4WpaQ6gy5z6NO9XfoxCb5Dp2f2t4PT4gJRIf4LduJ1d9gzpRV05supPqQDgIo
# 8A3Ggn3VApJ2heYSvwTWRtdupjEMCAsIRqHhCtVdbk6w69db+nl3p2mJpdsAC0TK
# cBe+CqUfzG2RwotLPtecdeqje30gQE6nXcyFVgyOD0O5S520QR4OZtQQ1R+5VMfS
# ZwGP6VgkA9ytx+FUc6GKc00jmd8OaLyipiCv+McQawcKxrWWR/ELJUoOU+BH0PO/
# v69nDTam/xFDyt8+kclhhOpefR0OEnXzAoinsdXT2rTYkE2PinIflY3jUhMQ5xi9
# hiGHgbsCqXNHSw==
# SIG # End signature block
