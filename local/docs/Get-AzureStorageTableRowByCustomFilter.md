---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Get-AzureStorageTableRowByCustomFilter

## SYNOPSIS
Returns one or more rows/entities based on custom filter.

## SYNTAX

```
Get-AzureStorageTableRowByCustomFilter [-table] <Object> [-customFilter] <String>
```

## DESCRIPTION
Returns one or more rows/entities based on custom filter.
This custom filter can be
built using the Microsoft.WindowsAzure.Storage.Table.TableQuery class or direct text.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting row by firstname by using the class Microsoft.WindowsAzure.Storage.Table.TableQuery
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter

### -------------------------- EXAMPLE 2 --------------------------
```
# Getting row by firstname by using text filter directly (oData filter format)
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByCustomFilter -table $table -customFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"

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

### -customFilter
Custom filter string.

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

