---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVSite

## SYNOPSIS
renames a new site within a Horizon View Pod Federation (Cloud Pod Architecture)

## SYNTAX

```
Set-HVSite [-sitename] <String> [-name] <String> [-description] <String> [[-HvServer] <Object>]
 [<CommonParameters>]
```

## DESCRIPTION
renames a new site within a Horizon View Pod Federation (Cloud Pod Architecture)

## EXAMPLES

### EXAMPLE 1
```
set-hvsite -site "CURRENTSITENAME" -name "NAME" -description "DESCRIPTION"
```

Returns information about the sites within a Horizon View Pod Federation.

## PARAMETERS

### -sitename
Name of the site to be edited

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -name
New name of the site (required)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -description
New description of the site (required)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the virtual machines from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
| | |
|-|-|
| Author | Wouter Kursten |
| Author email | wouter@retouw.nl |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.3.2,7.4 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
