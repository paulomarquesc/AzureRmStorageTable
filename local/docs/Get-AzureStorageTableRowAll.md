---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Get-AzureStorageTableRowAll

## SYNOPSIS
Returns all rows/entities from a storage table - no filtering

## SYNTAX

```
Get-AzureStorageTableRowAll [-table] <Object>
```

## DESCRIPTION
Returns all rows/entities from a storage table - no filtering

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting all rows
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowAll -table $table

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

