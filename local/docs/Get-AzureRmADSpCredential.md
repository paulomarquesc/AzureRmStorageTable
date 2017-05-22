---
external help file: Microsoft.Azure.Commands.Resources.dll-Help.xml
online version: 
schema: 2.0.0
---

# Get-AzureRmADSpCredential

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### ObjectIdParameterSet (Default)
```
Get-AzureRmADSpCredential -ObjectId <String>
```

### SPNParameterSet
```
Get-AzureRmADSpCredential -ServicePrincipalName <String>
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ObjectId
The servicePrincipal object id.

```yaml
Type: String
Parameter Sets: ObjectIdParameterSet
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ServicePrincipalName
The servicePrincipal name.

```yaml
Type: String
Parameter Sets: SPNParameterSet
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

### System.String


## OUTPUTS

### Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADCredential


## NOTES

## RELATED LINKS

