---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Remove-AzureStorageTableRow

## SYNOPSIS
Remove-AzureStorageTableRow - Removes a specified table row

## SYNTAX

### byEntityPSObjectObject
```
Remove-AzureStorageTableRow -table <Object> -entity <Object>
```

### byPartitionandRowKeys
```
Remove-AzureStorageTableRow -table <Object> -partitionKey <String> -rowKey <String>
```

## DESCRIPTION
Remove-AzureStorageTableRow - Removes a specified table row.
It accepts multiple deletions through the Pipeline when passing entities returned from the Get-AzureStorageTableRow
available cmdlets.
It also can delete a row/entity using Partition and Row Key properties directly.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Deleting an entry by entity PS Object
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
\[string\]$filter1 = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::GenerateFilterCondition("firstName",\[Microsoft.WindowsAzure.Storage.Table.QueryComparisons\]::Equal,"Paulo")
\[string\]$filter2 = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::GenerateFilterCondition("lastName",\[Microsoft.WindowsAzure.Storage.Table.QueryComparisons\]::Equal,"Marques")
\[string\]$finalFilter = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::CombineFilters($filter1,"and",$filter2)
$personToDelete = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
$personToDelete | Remove-AzureStorageTableRow -table $table

### -------------------------- EXAMPLE 2 --------------------------
```
# Deleting an entry by using partitionkey and row key directly
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
Remove-AzureStorageTableRow -table $table -partitionKey "TableEntityDemoFullList" -rowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"

### -------------------------- EXAMPLE 3 --------------------------
```
# Deleting everything
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
Get-AzureStorageTableRowAll -table $table | Remove-AzureStorageTableRow -table $table

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity exists

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

### -entity
{{Fill entity Description}}

```yaml
Type: Object
Parameter Sets: byEntityPSObjectObject
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -partitionKey
{{Fill partitionKey Description}}

```yaml
Type: String
Parameter Sets: byPartitionandRowKeys
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -rowKey
{{Fill rowKey Description}}

```yaml
Type: String
Parameter Sets: byPartitionandRowKeys
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

