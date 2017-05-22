---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Update-AzureStorageTableRow

## SYNOPSIS
Updates a table entity

## SYNTAX

```
Update-AzureStorageTableRow [-table] <Object> [-entity] <Object>
```

## DESCRIPTION
Updates a table entity.
To work with this cmdlet, you need first retrieve an entity with one of the Get-AzureStorageTableRow cmdlets available
and store in an object, change the necessary properties and then perform the update passing this modified entity back, through Pipeline or as argument.
Notice that this cmdlet accepts only one entity per execution.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Updating an entity
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
\[string\]$filter = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::GenerateFilterCondition("firstName",\[Microsoft.WindowsAzure.Storage.Table.QueryComparisons\]::Equal,"User1")
$person = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $filter
$person.lastName = "New Last Name"
$person | Update-AzureStorageTableRow -table $table

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity exists

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

### -entity
The entity/row with new values to perform the update.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

