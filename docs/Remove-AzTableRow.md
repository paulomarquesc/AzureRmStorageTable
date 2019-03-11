---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Remove-AzTableRow

## SYNOPSIS
Remove-AzTableRow - Removes a specified table row

## SYNTAX

### byEntityPSObjectObject
```
Remove-AzTableRow -Table <Object> -entity <Object> [<CommonParameters>]
```

### byPartitionandRowKeys
```
Remove-AzTableRow -Table <Object> -PartitionKey <String> -RowKey <String> [<CommonParameters>]
```

## DESCRIPTION
Remove-AzTableRow - Removes a specified table row.
It accepts multiple deletions through the Pipeline when passing entities returned from the Get-AzTableRow
available cmdlets.
It also can delete a row/entity using Partition and Row Key properties directly.

## EXAMPLES

### EXAMPLE 1
```
# Deleting an entry by entity PS Object
```

\[string\]$Filter1 = \[Microsoft.Azure.Cosmos.Table.TableQuery\]::GenerateFilterCondition("firstName",\[Microsoft.Azure.Cosmos.Table.QueryComparisons\]::Equal,"Paulo")
\[string\]$Filter2 = \[Microsoft.Azure.Cosmos.Table.TableQuery\]::GenerateFilterCondition("lastName",\[Microsoft.Azure.Cosmos.Table.QueryComparisons\]::Equal,"Marques")
\[string\]$finalFilter = \[Microsoft.Azure.Cosmos.Table.TableQuery\]::CombineFilters($Filter1,"and",$Filter2)
$personToDelete = Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $finalFilter
$personToDelete | Remove-AzTableRow -Table $Table

### EXAMPLE 2
```
# Deleting an entry by using PartitionKey and row key directly
```

Remove-AzTableRow -Table $Table -PartitionKey "TableEntityDemoFullList" -RowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"

### EXAMPLE 3
```
# Deleting everything
```

Get-AzTableRowAll -Table $Table | Remove-AzTableRow -Table $Table

## PARAMETERS

### -Table
Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity exists

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
{{ Fill entity Description }}

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

### -PartitionKey
{{ Fill PartitionKey Description }}

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

### -RowKey
{{ Fill RowKey Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
