---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Get-AzureStorageTableRowByColumnName

## SYNOPSIS
Returns one or more rows/entities based on a specified column and its value

## SYNTAX

```
Get-AzureStorageTableRowByColumnName [-table] <Object> [-columnName] <String> [-value] <String>
 [-operator] <String>
```

## DESCRIPTION
Returns one or more rows/entities based on a specified column and its value

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting row by firstname
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByColumnName -table $table -columnName "firstName" -value "Paulo" -operator Equal

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities

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

### -columnName
Column name to compare the value to

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

### -value
Value that will be looked for in the defined column

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

### -operator
Supported comparison operator.
Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

