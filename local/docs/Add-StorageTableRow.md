---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Add-StorageTableRow

## SYNOPSIS
Adds a row/entity to a specified table

## SYNTAX

```
Add-StorageTableRow [-table] <Object> [-partitionKey] <String> [-rowKey] <String> [-property] <Hashtable>
```

## DESCRIPTION
Adds a row/entity to a specified table

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Adding a row
```

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey (\[guid\]::NewGuid().tostring()) -property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity will be added

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

### -rowKey
Identifies a row within a partition

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

### -property
Hashtable with the columns that will be part of the entity.
e.g.
@{"firstName"="Paulo";"lastName"="Marques"}

```yaml
Type: Hashtable
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

