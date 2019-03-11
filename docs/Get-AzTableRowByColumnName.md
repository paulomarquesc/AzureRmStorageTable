---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Get-AzTableRowByColumnName

## SYNOPSIS
Returns one or more rows/entities based on a specified column and its value

## SYNTAX

### byString
```powershell
Get-AzTableRowByColumnName -Table <Object> -ColumnName <String> -Value <String> -Operator <String>
 [<CommonParameters>]
```

### byGuid
```powershell
Get-AzTableRowByColumnName -Table <Object> -ColumnName <String> -GuidValue <Guid> -Operator <String>
 [<CommonParameters>]
```

## DESCRIPTION
Returns one or more rows/entities based on a specified column and its value

## EXAMPLES

### EXAMPLE 1
```powershell
# Getting row by firstname
Get-AzTableRowByColumnName -Table $Table -ColumnName "firstName" -value "Paulo" -Operator Equal
```

## PARAMETERS

### -Table
Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ColumnName
Column name to compare the value to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Value that will be looked for in the defined column

```yaml
Type: String
Parameter Sets: byString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GuidValue
Value that will be looked for in the defined column as Guid

```yaml
Type: Guid
Parameter Sets: byGuid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Operator
Supported comparison Operator.
Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
