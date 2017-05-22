---
external help file: Microsoft.Azure.Commands.ResourceManager.Cmdlets.dll-Help.xml
online version: 
schema: 2.0.0
---

# New-AzureRmPolicyAssignment

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### Policy assignment without parameters (Default)
```
New-AzureRmPolicyAssignment -Name <String> -Scope <String> [-DisplayName <String>] -PolicyDefinition <PSObject>
 [-ApiVersion <String>] [-Pre]
```

### Policy assignment with parameters via policy parameter object
```
New-AzureRmPolicyAssignment -Name <String> -Scope <String> [-DisplayName <String>] -PolicyDefinition <PSObject>
 -PolicyParameterObject <Hashtable> [-ApiVersion <String>] [-Pre]
```

### Policy assignment with parameters via policy parameter string
```
New-AzureRmPolicyAssignment -Name <String> -Scope <String> [-DisplayName <String>] -PolicyDefinition <PSObject>
 -PolicyParameter <String> [-ApiVersion <String>] [-Pre]
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

### -ApiVersion
When set, indicates the version of the resource provider API to use.
If not specified, the API version is automatically determined as the latest available.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
The description for policy assignment.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The policy assignment name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PolicyDefinition
The policy definition object.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PolicyParameter
The policy parameter file path or policy parameter string.

```yaml
Type: String
Parameter Sets: Policy assignment with parameters via policy parameter string
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PolicyParameterObject
The policy parameter object.

```yaml
Type: Hashtable
Parameter Sets: Policy assignment with parameters via policy parameter object
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pre
When set, indicates that the cmdlet should use pre-release API versions when automatically determining which version to use.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
The scope for policy assignment.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

### System.String
System.Management.Automation.PSObject


## OUTPUTS

### System.Management.Automation.PSObject


## NOTES

## RELATED LINKS

