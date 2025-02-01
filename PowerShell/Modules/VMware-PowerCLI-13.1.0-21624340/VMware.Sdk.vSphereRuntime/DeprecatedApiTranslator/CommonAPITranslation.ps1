
# The algorithm searches for matching substructs in the translation scheme
# comparing the first property of the Old and New structure scheme
# There is a risk of wrong translation if in the New structure scheme
# a property is added in front. Meaning the New APIs extend existing structure
# with new property added on the first position.

function ConvertFrom-DeprecatedBodyCommon {
    # Output body translation is always old -> new direction
    param(
        [Parameter()]
        [PSCustomObject]
        $OperationTranslateSchema,

        [Parameter()]
        [PSCustomObject]
        $OperationOutputObject
    )
    $convertArrayToPSObject = $false

    if ($OperationOutputObject -is [array]) {
        if ($OperationOutputObject.Count -eq 0) {
            $result = @()
            return , $result
        }
        else {
            if ($null -ne $OperationTranslateSchema.OldOutBodyStruct) {
                $oldSchemaProperties = $OperationTranslateSchema.OldOutBodyStruct | Get-Member -MemberType NoteProperty
                $convertArrayToPSObject = ($null -ne $oldSchemaProperties -and `
                        $oldSchemaProperties.Count -eq 2 -and `
                        $oldSchemaProperties[0].Name -eq 'key' -and `
                        $oldSchemaProperties[1].Name -eq 'value')
            }
        }
    }

    if ($convertArrayToPSObject) {
        $resultObject = New-Object PSCustomObject

        foreach ($outputObject in $OperationOutputObject) {
            $translationSchema = [PSCustomObject]@{
                'OldOutBodyStruct' = $($OperationTranslateSchema.OldOutBodyStruct.value)
                'NewOutBodyStruct' = $($OperationTranslateSchema.NewOutBodyStruct)
            }
            $resultObject | Add-Member -MemberType NoteProperty -Name $outputObject.Key -Value (ConvertFrom-DeprecatedBodyCommon $translationSchema $outputObject.value)
        }

        $resultObject

    }
    else {

        foreach ($outputObject in $OperationOutputObject) {

            if (-not $OperationTranslateSchema.OldOutBodyStruct -and -not $OperationTranslateSchema.NewOutBodyStruct) {
                # No Translation Needed
                # return
                $outputObject
            }

            if (-not $OperationTranslateSchema.OldOutBodyStruct -and $OperationTranslateSchema.NewOutBodyStruct) {
                # Translation Impossible
                # return
                $outputObject
            }

            if ($OperationTranslateSchema.OldOutBodyStruct -and -not $OperationTranslateSchema.NewOutBodyStruct) {
                # Old Operation Presents Simple Type as a Structure

                $oldSchemaProperties = $OperationTranslateSchema.OldOutBodyStruct | Get-Member -MemberType NoteProperty
                if ($null -ne $oldSchemaProperties -and $oldSchemaProperties.Count -eq 1) {
                    # Value Wrapper Pattern

                    foreach ($element in $outputObject) {
                        if ($element -is [array] -and $element.Length -eq 0) {
                            # empty array isconverted to empty object
                            $result = New-Object PSCustomObject
                            # return
                            $result
                        }
                        else {
                            # return
                            $element.$($oldSchemaProperties[0].Name)
                        }
                    }
                }

                if ($null -ne $oldSchemaProperties -and `
                        $oldSchemaProperties.Count -eq 2 -and `
                        $oldSchemaProperties[0].Name -eq 'key' -and `
                        $oldSchemaProperties[1].Name -eq 'value') {

                    $result = New-Object PSCustomObject

                    # Map to Array Pattern
                    foreach ($element in $outputObject) {
                        if ($element -is [array] -and $element.Length -eq 0) {
                            # empty array isconverted to empty object
                        }
                        else {
                            $result = New-Object PSCustomObject
                            $result | Add-Member -MemberType NoteProperty -Name $element.key -Value $element.Value
                        }
                    }

                    # return
                    $result
                }
            }


            if ($OperationTranslateSchema.OldOutBodyStruct -and $OperationTranslateSchema.NewOutBodyStruct) {
                # Structure to Structure Translation
                $oldStructProps = $OperationTranslateSchema.OldOutBodyStruct | Get-Member -MemberType NoteProperty
                $newStructProps = $OperationTranslateSchema.NewOutBodyStruct | Get-Member -MemberType NoteProperty
                if ($null -ne $newStructProps -and $null -ne $oldStructProps) {
                    if ($newStructProps[0].Name -eq $oldStructProps[0].Name) {
                        # Structures match no translation needed
                        # Traverse and Translate each property

                        $resultObject = New-Object PSCustomObject

                        foreach ($prop in $oldStructProps) {
                            $translationSchema = [PSCustomObject]@{
                                'OldOutBodyStruct' = $($OperationTranslateSchema.OldOutBodyStruct.$($prop.Name))
                                'NewOutBodyStruct' = $($OperationTranslateSchema.NewOutBodyStruct.$($prop.Name))
                            }

                            $translatedValue = (ConvertFrom-DeprecatedBodyCommon $translationSchema $outputObject.($prop.Name))

                            if ($null -ne $translatedValue) {
                                $resultObject | Add-Member `
                                    -MemberType NoteProperty `
                                    -Name $prop.Name `
                                    -Value $translatedValue
                            }
                        }

                        # return
                        $resultObject
                    }
                    else {
                        if ($oldStructProps.Count -eq 1) {
                            # Value Wrapper Pattern
                            $translationSchema = [PSCustomObject]@{
                                'OldOutBodyStruct' = $($OperationTranslateSchema.OldOutBodyStruct.$($oldStructProps[0].Name))
                                'NewOutBodyStruct' = $($OperationTranslateSchema.NewOutBodyStruct)
                            }

                            # return
                            (ConvertFrom-DeprecatedBodyCommon $translationSchema $outputObject.($oldStructProps[0].Name))
                        }

                        if ($oldStructProps.Count -eq 2 -and `
                                $oldStructProps[0].Name -eq 'key' -and `
                                $oldStructProps[1].Name -eq 'value') {
                            # Map to Array pattern

                            # Handle Empty array
                            if ($outputObject -is [array] -and $outputObject.Length -eq 0) {
                                # empty array isconverted to empty object
                                $result = New-Object PSCustomObject
                                # return
                                $result
                            }
                            else {
                                $result = New-Object PSCustomObject

                                foreach ($element in $outputObject) {
                                    $translationSchema = [PSCustomObject]@{
                                        'OldOutBodyStruct' = $($OperationTranslateSchema.OldOutBodyStruct.value)
                                        'NewOutBodyStruct' = $($OperationTranslateSchema.NewOutBodyStruct)
                                    }

                                    $result | Add-Member `
                                        -MemberType NoteProperty `
                                        -Name $element.key `
                                        -Value (ConvertFrom-DeprecatedBodyCommon $translationSchema ($element.value))
                                }

                                # return
                                $result
                            }
                        }
                    }
                }

                if ($null -eq $newStructProps -and $null -ne $oldStructProps) {
                    # Old Operation Presents Simple Type as a Structure
                    foreach ($element in $outputObject) {
                        $noteProperties = $element | Get-Member -MemberType NoteProperty
                        if ($null -ne $noteProperties -and $noteProperties.Count -eq 1) {
                            # Value Wrapper Pattern

                            # return
                            $element.$($noteProperties[0].Name)
                        }

                        if ($null -ne $noteProperties -and `
                                $noteProperties.Count -eq 2 -and `
                                $noteProperties[0].Name -eq 'key' -and `
                                $noteProperties[1].Name -eq 'value') {
                            # Map to Array Pattern
                            $result = New-Object PSCustomObject
                            $result | Add-Member -MemberType NoteProperty -Name $element.key -Value $element.Value
                            # return
                            $result
                        }
                    }
                }

                if ($null -eq $newStructProps -and $null -eq $oldStructProps) {
                    # If the OperationOutputObject is an array, using foreach will result in
                    # returning only the first element of the array, instead of the whole array.
                    if ($OperationOutputObject -is [array]) {
                        # return the whole array and use the comma syntax in the case of array with only one element
                        , $OperationOutputObject
                    } else {
                        # return the current object only
                        $outputObject
                    }
                }
            }
        }
    }
}

function ConvertTo-DeprecatedBodyCommon {
    # Input body translation is always new -> old direction
    param(
        [Parameter()]
        [PSCustomObject]
        $OperationTranslateSchema,

        [Parameter()]
        [PSCustomObject]
        $OperationInputObject
    )
    if ($OperationInputObject -is [array] -and $OperationInputObject.Count -eq 0) {
        return (New-Object PSCustomObject)
    }


    $result = $null
    if ($OperationInputObject -is [array]) {
        $result = @()
    }

    foreach ($inputObject in $OperationInputObject) {
        $singleObjectResult = $null
        if (-not $OperationTranslateSchema.OldInBodyStruct -and -not $OperationTranslateSchema.NewInBodyStruct) {
            # No Translation Needed
            $singleObjectResult = $inputObject
        }

        if (-not $OperationTranslateSchema.OldInBodyStruct -and $OperationTranslateSchema.NewInBodyStruct) {
            # Translation Impossible
            # return and let the server to fail
            $singleObjectResult = $inputObject
        }

        if ($OperationTranslateSchema.OldInBodyStruct -and -not $OperationTranslateSchema.NewInBodyStruct) {
            # Old Operation Presents Simple Type as a Structure
            $oldSchemaProperties = $OperationTranslateSchema.OldInBodyStruct | Get-Member -MemberType NoteProperty
            if ($null -ne $oldSchemaProperties -and $oldSchemaProperties.Count -eq 1) {
                # Value Wrapper Pattern

                foreach ($element in $inputObject) {
                    if ($element -is [PSCustomObject] -and ($element | Get-Member -MemberType NoteProperty).Count -eq 0) {
                        # empty PSCustom Object is converted to empty array
                        # return
                        $singleObjectResult = @()
                    }
                    else {
                        $resultObject = New-Object PSCustomObject
                        $resultObject | Add-Member -MemberType NoteProperty -Name $oldSchemaProperties[0].Name -Value $element
                        # return
                        $singleObjectResult = $resultObject
                    }
                }
            }

            if ($null -ne $oldSchemaProperties -and `
                    $oldSchemaProperties.Count -eq 2 -and `
                    $oldSchemaProperties[0].Name -eq 'key' -and `
                    $oldSchemaProperties[1].Name -eq 'value') {
                # Map to Array Pattern
                foreach ($element in $outputObject) {
                    if ($element -is [PSCustomObject] -and ($element | Get-Member -MemberType NoteProperty).Count -eq 0) {
                        # empty PSCustom Object is converted to empty array
                        # return
                        $singleObjectResult = @()
                    }
                    else {
                        $resultObject = New-Object PSCustomObject
                        $resultObject | Add-Member -MemberType NoteProperty -Name 'key' -Value $element.key
                        $resultObject | Add-Member -MemberType NoteProperty -Name 'value' -Value $element.Value
                        # return
                        $singleObjectResult = $resultObject
                    }
                }
            }
        }

        if ($OperationTranslateSchema.OldInBodyStruct -and $OperationTranslateSchema.NewInBodyStruct) {
            # Structure to Structure Translation
            $oldStructProps = $OperationTranslateSchema.OldInBodyStruct | Get-Member -MemberType NoteProperty
            $newStructProps = $OperationTranslateSchema.NewInBodyStruct | Get-Member -MemberType NoteProperty
            if ($null -ne $newStructProps -and $null -ne $oldStructProps) {
                <#
                    In the deprecated vSphere APIs, the 'client_token' is in the body
                    and in the new vSphere APIs, the 'client_token' is moved to the header parameters.
                    There're 10 vSphere APIs using the 'client_token' and in each the 'client_token' is the
                    first element. So we need to remove it from the body so that the translation algorithm can
                    work as expected - either we're left with matching Structures or the Wrapper Pattern occurs.
                #>
                if ($oldStructProps[0].Name -eq 'client_token') {
                    $oldStructProps = $oldStructProps[1..($oldStructProps.Length - 1)]
                }

                if ($newStructProps[0].Name -eq $oldStructProps[0].Name) {
                    # Structures match no translation needed
                    # Traverse and Translate each property

                    $resultObject = New-Object PSCustomObject

                    foreach ($prop in $oldStructProps) {
                        # Assuming the New Structure has all the properties the old one has
                        # In case the new one has more they won't be translated
                        $translationSchema = [PSCustomObject]@{
                            'OldInBodyStruct' = $($OperationTranslateSchema.OldInBodyStruct.$($prop.Name))
                            'NewInBodyStruct' = $($OperationTranslateSchema.NewInBodyStruct.$($prop.Name))
                        }

                        $translatedValue = (ConvertTo-DeprecatedBodyCommon $translationSchema $inputObject.($prop.Name))

                        if ($null -ne $translatedValue) {
                            $resultObject | Add-Member `
                                -MemberType NoteProperty `
                                -Name $prop.Name `
                                -Value $translatedValue
                        }
                    }

                    # return
                    $singleObjectResult = $resultObject
                }
                else {
                    if ($oldStructProps.Count -eq 1) {
                        # Spec Wrapper Pattern
                        $translationSchema = [PSCustomObject]@{
                            'OldInBodyStruct' = $($OperationTranslateSchema.OldInBodyStruct.$($oldStructProps[0].Name))
                            'NewInBodyStruct' = $($OperationTranslateSchema.NewInBodyStruct)
                        }


                        $translatedValue = (ConvertTo-DeprecatedBodyCommon $translationSchema $inputObject)
                        $resultObject = New-Object PSCustomObject
                        $resultObject | Add-Member `
                            -MemberType NoteProperty `
                            -Name $oldStructProps[0].Name `
                            -Value $translatedValue

                        # return
                        $singleObjectResult = $resultObject
                    }

                    if ($oldStructProps.Count -eq 2 -and `
                            $oldStructProps[0].Name -eq 'key' -and `
                            $oldStructProps[1].Name -eq 'value') {
                        # Array to Map pattern

                        # Handle Empty array
                        if ($inputObject -is [PSCustomObject] -and ($inputObject | Get-Member -MemberType NoteProperty).Count -eq 0) {
                            # empty PSObject is converted to empty array
                            # return
                            $singleObjectResult = @()
                        }
                        else {
                            $singleObjectResult = @()
                            foreach ($element in $inputObject) {
                                $notePropertyMemebers = $element | Get-Member -MemberType NoteProperty
                                if ($notePropertyMemebers.Count -ne 1) {
                                    throw "Input object array to map cannot be translated because element has more than one key note property"
                                }

                                # Note property name is mapped to the 'key' property of the old structure
                                # Note property value is mapped to the 'value' property of the old structure
                                $translationSchema = [PSCustomObject]@{
                                    'OldInBodyStruct' = $($OperationTranslateSchema.OldInBodyStruct.value)
                                    'NewInBodyStruct' = $($OperationTranslateSchema.NewInBodyStruct)
                                }
                                $resultObject = New-Object PSCustomObject
                                $resultObject | Add-Member -MemberType NoteProperty -Name 'key' -Value $notePropertyMemebers[0].Name
                                $resultObject | Add-Member -MemberType NoteProperty -Name 'value' -Value (ConvertTo-DeprecatedBodyCommon $translationSchema ($element.$($notePropertyMemebers[0].Name)))
                                # return
                                $singleObjectResult += $resultObject
                            }
                        }
                    }
                }
            }

            if ($null -eq $newStructProps -and $null -ne $oldStructProps) {
                # Old Operation Presents Simple Type as a Structure
                foreach ($element in $inputObject) {
                    $noteProperties = $element | Get-Member -MemberType NoteProperty
                    if ($noteProperties.Count -eq 1) {
                        # Query Input Array Parameter Pattern
                        $resultObject = [PSCustomObject] @{
                            $noteProperties[0].Name = $element.($noteProperties[0].Name)
                        }

                        $resultObject
                    } elseif ($oldStructProps.Count -eq 1) {
                        # Spec Wrapper Pattern
                        $resultObject = New-Object PSCustomObject
                        $resultObject | Add-Member `
                            -MemberType NoteProperty `
                            -Name $oldStructProps[0].Name `
                            -Value $element

                        # return
                        $singleObjectResult = $resultObject
                    }

                }
            }

            if ($null -eq $newStructProps -and $null -eq $oldStructProps) {
                # return
                $singleObjectResult = $inputObject
            }
        }

        if ($result -is [array]) {
            $result += $singleObjectResult
        } else {
            $result = $singleObjectResult
        }
    }

    # return converted result
    if ($result -is [array] -and $result.Count -eq 1) {
        return , $result
    } else {
        return $result
    }
}

function Convert-StructureDefitionToArrayDefinition {
    <#
    .SYNOPSIS
    Converts structure definition from translation scheme to array definition

    .DESCRIPTION
    The convertor is for the purpose of translating body structure defined in the translation schema to query parameters definition,

    .PARAMETER DataStructureDefinition
    PSCustomObject that represents the InBody definition of a translation schema for an API operation
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]
        $DataStructureDefinition,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ref]$StructureObject
    )

    $newStructureObject =New-Object PSCustomObject

    foreach ($dsDef in $DataStructureDefinition) {
        $dsDef | Get-Member -MemberType NoteProperty | Foreach-Object {
            if ($dsDef.$($_.Name) -is [PSCustomObject]) {
                # For some APIs multiple structures are converted list of query params
                # We assume there are no nested structures in the query params
                # The modst complext case is assumed to be
                #  {
                #      'loc_spec': {
                #            'locaiton': 'string'
                #      }
                #      'filter_spec': {
                #        'max_result': 'integer'
                #      }
                #   }
                #
                # which is converted to @(locaiton, max_result) query parameters
                #
                $parentPropertyName = $_.Name
                $dsDef.$($_.Name) | Get-Member -MemberType NoteProperty | Foreach-Object {
                    $newStructureObject | Add-Member -MemberType NoteProperty -Name "$($parentPropertyName).$($_.Name)" -Value $($StructureObject.Value.$parentPropertyName.$($_.Name))
                    # result
                    "$($parentPropertyName).$($_.Name)"
                }
            } else {
                $newStructureObject | Add-Member -MemberType NoteProperty -Name $($_.Name) -Value $($StructureObject.Value.$($_.Name))
                # result
                $_.Name
            }
        }
    }

    $StructureObject.Value = $newStructureObject
}

function ConvertTo-DeprecatedQueryParamCommon {
    # Converts Query Param object from new -> old direction
    param(
        [Parameter()]
        [PSCustomObject]
        $OperationTranslateSchema,

        [Parameter()]
        [PSCustomObject]
        $OperationQueryInputObject
    )


    if ($null -ne $OperationTranslateSchema.OldInQueryParams -and `
            $null -ne $OperationTranslateSchema.NewInQueryParams -and `
            $OperationQueryInputObject -is [PSCustomObject]) {

        $resultObject = New-Object PSCustomObject

        $newQueryParamDefinition = $null

        if ($OperationTranslateSchema.NewInQueryParams -isnot [array] -and `
            $OperationTranslateSchema.NewInQueryParams -is [PSCustomObject]) {

            $newQueryParamDefinition = (Convert-StructureDefitionToArrayDefinition -DataStructureDefinition $OperationTranslateSchema.NewInQueryParams -StructureObject ([ref]$OperationQueryInputObject))
        } else {
            $newQueryParamDefinition = $OperationTranslateSchema.NewInQueryParams
        }

        foreach ($newQueryParam in $newQueryParamDefinition) {
            foreach ($oldQueryParam in $OperationTranslateSchema.OldInQueryParams) {
                $value = $($OperationQueryInputObject."$newQueryParam")
                if ($null -ne $value) {
                    $propName = $newQueryParam
                    if ($oldQueryParam -eq $newQueryParam) {
                        # leave it as-is
                        $resultObject | Add-Member -MemberType NoteProperty -Name $propName -Value $value
                    }
                    elseif ($oldQueryParam.EndsWith(".$newQueryParam")) {
                        # Use the old property name
                        $propName = $oldQueryParam
                        $resultObject | Add-Member -MemberType NoteProperty -Name $propName -Value $value
                    }
                }
            }
        }

        # return
        $resultObject
    }
    else {
        # The conversion is not possible
        $OperationQueryInputObject
    }
}
# SIG # Begin signature block
# MIIohwYJKoZIhvcNAQcCoIIoeDCCKHQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD0Tpo0XunmJgOu
# mDH1INfpGRqAXwvlDMEjyO1Q3s6bAaCCDdowggawMIIEmKADAgECAhAIrUCyYNKc
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
# tKncUjJ1xAAtAExGdCh6VD2U5iYxghoDMIIZ/wIBATB9MGkxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1
# c3RlZCBHNCBDb2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEA7G
# 8rJ2oUagfQ5tk1e14QgwDQYJYIZIAWUDBAIBBQCggZYwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwKgYKKwYB
# BAGCNwIBDDEcMBqhGIAWaHR0cDovL3d3dy52bXdhcmUuY29tLzAvBgkqhkiG9w0B
# CQQxIgQgPuMrXr2cbM+K38HUa/TQaqCVh+Td8cvz28+/CTF09DswDQYJKoZIhvcN
# AQEBBQAEggGAZ0rNxAJAxBDNjDolsfP06Fn59mbv5Q86LRogLiC+NjXAffle9tQQ
# Q1VCphfUmLCh9gp3xHjEAwense8j383MDc1IbGOXTnwuBjDIhVjsJTFMGL60qdMh
# ssoWOkqdCYdwRH/yPgiasmazSjzU8YgR0Y0faGjxhqPRR+KqKvcxyzx391ddnoc0
# fRw5gY+qcou54IbgUnZaAheWm0euP1GjedTPcFQZLZH3ksik765V7R3+Q4OpBxkB
# ff5r7BrdSXgCc0kjCb0/1JbDUObiTivZ1aPytk1nkgpuVML+r3x3ogNJqlsDZKcJ
# XhGaF4hh3J9p3xElZscH3rXFM+ewVSHnR+D7XQ8TrvUR+9i7Bn/UyIwD1KWljFSH
# Am4RnmGc4ajosqccWjz0DseJOrvq2haw4dvOUIX+juIePrMs+/1VozJpvnCnbeVw
# iohu1LAg4Ubg+DyRMoM+WKCiMqk0v1Ea1VmDOHU3A+TseEEB0x6lWANIJ5K6c5He
# VLTsyjTn3tiloYIXPjCCFzoGCisGAQQBgjcDAwExghcqMIIXJgYJKoZIhvcNAQcC
# oIIXFzCCFxMCAQMxDzANBglghkgBZQMEAgEFADB4BgsqhkiG9w0BCRABBKBpBGcw
# ZQIBAQYJYIZIAYb9bAcBMDEwDQYJYIZIAWUDBAIBBQAEIBwk6o+4WOJ7YmVIQGGh
# Kzh5bNLDIu7/VpDonotXlGTiAhEAhOKHhtmR2Ndinygw4cShqxgPMjAyMzA0MTgx
# NDUxNDJaoIITBzCCBsAwggSooAMCAQICEAxNaXJLlPo8Kko9KQeAPVowDQYJKoZI
# hvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRp
# bWVTdGFtcGluZyBDQTAeFw0yMjA5MjEwMDAwMDBaFw0zMzExMjEyMzU5NTlaMEYx
# CzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDEkMCIGA1UEAxMbRGlnaUNl
# cnQgVGltZXN0YW1wIDIwMjIgLSAyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAz+ylJjrGqfJru43BDZrboegUhXQzGias0BxVHh42bbySVQxh9J0Jdz0V
# lggva2Sk/QaDFteRkjgcMQKW+3KxlzpVrzPsYYrppijbkGNcvYlT4DotjIdCriak
# 5Lt4eLl6FuFWxsC6ZFO7KhbnUEi7iGkMiMbxvuAvfTuxylONQIMe58tySSgeTIAe
# hVbnhe3yYbyqOgd99qtu5Wbd4lz1L+2N1E2VhGjjgMtqedHSEJFGKes+JvK0jM1M
# uWbIu6pQOA3ljJRdGVq/9XtAbm8WqJqclUeGhXk+DF5mjBoKJL6cqtKctvdPbnjE
# KD+jHA9QBje6CNk1prUe2nhYHTno+EyREJZ+TeHdwq2lfvgtGx/sK0YYoxn2Off1
# wU9xLokDEaJLu5i/+k/kezbvBkTkVf826uV8MefzwlLE5hZ7Wn6lJXPbwGqZIS1j
# 5Vn1TS+QHye30qsU5Thmh1EIa/tTQznQZPpWz+D0CuYUbWR4u5j9lMNzIfMvwi4g
# 14Gs0/EH1OG92V1LbjGUKYvmQaRllMBY5eUuKZCmt2Fk+tkgbBhRYLqmgQ8JJVPx
# vzvpqwcOagc5YhnJ1oV/E9mNec9ixezhe7nMZxMHmsF47caIyLBuMnnHC1mDjcbu
# 9Sx8e47LZInxscS451NeX1XSfRkpWQNO+l3qRXMchH7XzuLUOncCAwEAAaOCAYsw
# ggGHMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoG
# CCsGAQUFBwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNV
# HSMEGDAWgBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUYore0GH8jzEU
# 7ZcLzT0qlBTfUpwwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGlu
# Z0NBLmNybDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFt
# cGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAVaoqGvNG83hXNzD8deNP1oUj
# 8fz5lTmbJeb3coqYw3fUZPwV+zbCSVEseIhjVQlGOQD8adTKmyn7oz/AyQCbEx2w
# mIncePLNfIXNU52vYuJhZqMUKkWHSphCK1D8G7WeCDAJ+uQt1wmJefkJ5ojOfRu4
# aqKbwVNgCeijuJ3XrR8cuOyYQfD2DoD75P/fnRCn6wC6X0qPGjpStOq/CUkVNTZZ
# mg9U0rIbf35eCa12VIp0bcrSBWcrduv/mLImlTgZiEQU5QpZomvnIj5EIdI/HMCb
# 7XxIstiSDJFPPGaUr10CU+ue4p7k0x+GAWScAMLpWnR1DT3heYi/HAGXyRkjgNc2
# Wl+WFrFjDMZGQDvOXTXUWT5Dmhiuw8nLw/ubE19qtcfg8wXDWd8nYiveQclTuf80
# EGf2JjKYe/5cQpSBlIKdrAqLxksVStOYkEVgM4DgI974A6T2RUflzrgDQkfoQTZx
# d639ouiXdE4u2h4djFrIHprVwvDGIqhPm73YHJpRxC+a9l+nJ5e6li6FV8Bg53hW
# f2rvwpWaSxECyIKcyRoFfLpxtU56mWz06J7UWpjIn7+NuxhcQ/XQKujiYu54BNu9
# 0ftbCqhwfvCXhHjjCANdRyxjqCU4lwHSPzra5eX25pvcfizM/xdMTQCi2NYBDriL
# 7ubgclWJLCcZYfZ3AYwwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0G
# CSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0
# IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTla
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJ
# UVXHJQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+e
# DzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47q
# UT3w1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL
# 6IRktFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c
# 1eYbqMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052
# FVUmcJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+
# onP65x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/w
# ojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1
# eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uK
# IqjBJgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7p
# XcheMBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgw
# BgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgw
# FoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6
# MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# Um9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJ
# KoZIhvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7
# x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGId
# DAiCqBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7g
# iqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6
# wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx
# 2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5kn
# LD0/a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3it
# TK37xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7
# HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUV
# mDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKm
# KYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8
# MIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBl
# MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
# d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJv
# b3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7J
# IT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxS
# D1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb
# 7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1ef
# VFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoY
# OAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSa
# M0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI
# 8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9L
# BADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfm
# Q6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDr
# McXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15Gkv
# mB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
# FgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGL
# p6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0G
# CSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6p
# Grsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1W
# z/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp
# 8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglo
# hJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8S
# uFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBj
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMT
# MkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5n
# IENBAhAMTWlyS5T6PCpKPSkHgD1aMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3
# DQEJAzENBgsqhkiG9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjMwNDE4MTQ1MTQy
# WjArBgsqhkiG9w0BCRACDDEcMBowGDAWBBTzhyJNhjOCkjWplLy9j5bp/hx8czAv
# BgkqhkiG9w0BCQQxIgQgQsqv9+b0f/jfL1e2wx93OnqPE6yBYPafZQHI25OX2p0w
# NwYLKoZIhvcNAQkQAi8xKDAmMCQwIgQgx/ThvjIoiSCr4iY6vhrE/E/meBwtZNBM
# gHVXoCO1tvowDQYJKoZIhvcNAQEBBQAEggIAn44NLOM+xCLSlEh5h4B5fpCnlJOE
# dVXkg4xPgi1vAatdqEnbFuCTwfTeC8Atiwe1J/PkcWgWeq2x4kCYnARdYuiTnHBl
# gr9NEvpQ+Tct3pPitIUmKIXq86nqsI/WRHxn7+fQM2ng5hWpt2cOu7xDVwvZ144j
# ZwIwjPIRyf/Pa72Z6Tk/A+qQ73Pnx14ol0ZDLe6Dhs9HiMzovVMpEl14ujefv0Fl
# oFo0TJVDw/csVzJOh3UVTIJsqRCT3agGRNf6+6xBUWT38MlujBrXfC5HUIHnLIiu
# kxNJ0osrE4T56nDTSPDUhzsowjqm3gLb/YwsFHNUEFhy+nn7WcJSLDusozYE0TFu
# ZKXj4LdK8dBKWl3y/xVVjcd0uTgdsUlM5dH7DhpRJMfMHxE1733TkSpv58xF7R5Q
# DoquFU6NXYhQaiRTQ6RK7w6kaa4WgerAeINwqF2EnHKMP+rKCEM+Cuhq7uzQV19g
# Kk7FSgYuxZ8TE5Cr12kSRIaVr6vf/iDyHgCAToi1ntttfAOaqQRhu5Cyk7NHKWDJ
# TEOHPT/SNUeQPeKBj4+teA9rzHXeR4dc+I/V+Xw4dWnjyf/3Gt1pWf69tpaWibyG
# fzQVbPLhqX49XAJ6jF/99w58G04IUXwE47UgQdOj7KYhHcOjAp0i+4CqUL9XHH1x
# RovmamdQqfE6Cmc=
# SIG # End signature block
