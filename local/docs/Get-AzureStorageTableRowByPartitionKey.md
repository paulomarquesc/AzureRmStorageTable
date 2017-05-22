---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Get-AzureStorageTableRowByPartitionKey

## SYNOPSIS
Returns one or more rows/entities based on Partition Key

## SYNTAX

```
Get-AzureStorageTableRowByPartitionKey [-table] <Object> [-partitionKey] <String>
```

## DESCRIPTION
Returns one or more rows/entities based on Partition Key

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting rows by partition Key
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByPartitionKey -table $table -partitionKey $newPartitionKey

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

### -partitionKey
Identifies the table partition

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

