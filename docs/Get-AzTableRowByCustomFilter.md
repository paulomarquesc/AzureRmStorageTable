---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Get-AzTableRowByCustomFilter

## SYNOPSIS
Returns one or more rows/entities based on custom Filter.

## SYNTAX

```powershell
Get-AzTableRowByCustomFilter [-Table] <Object> [-CustomFilter] <String> [<CommonParameters>]
```

## DESCRIPTION
Returns one or more rows/entities based on custom Filter.
This custom Filter can be
built using the Microsoft.Azure.Cosmos.Table.TableQuery class or direct text.

## EXAMPLES

### EXAMPLE 1
```powershell
# Getting row by firstname by using the class Microsoft.Azure.Cosmos.Table.TableQuery
$MyFilter = "(firstName eq 'User1')"
Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $MyFilter
```

### EXAMPLE 2
```powershell
# Getting row by firstname by using text Filter directly (oData Filter format)
Get-AzTableRowByCustomFilter -Table $Table -CustomFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"
```

## PARAMETERS

### -Table
Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomFilter
Custom Filter string.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
