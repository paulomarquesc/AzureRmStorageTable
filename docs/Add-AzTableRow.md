---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Add-AzTableRow

## SYNOPSIS
Adds a row/entity to a specified table or batch operation

## SYNTAX

### Table
```powershell
Add-AzTableRow -Table <Object> -PartitionKey <String> -RowKey <String> [-Property <Hashtable>]
 [-UpdateExisting] [<CommonParameters>]
```

### Batch
```powershell
Add-AzTableRow -Batch <Object> -PartitionKey <String> -RowKey <String> [-Property <Hashtable>]
 [-UpdateExisting] [<CommonParameters>]
```

## DESCRIPTION
Adds a row/entity to a specified table or batch operation

## EXAMPLES

### EXAMPLE 1
```powershell
# Adding a row
Add-AzTableRow -Table $Table -PartitionKey $PartitionKey -RowKey ([guid]::NewGuid().tostring()) -Property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
```

### EXAMPLE 2
```powershell
# Adding a row with a batch operation
$batch = New-AzTableBatch
$entity = @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
Add-AzTableRow -Batch $batch -PartitionKey $PartitionKey -RowKey ([guid]::NewGuid().tostring()) -Property $entity
Invoke-AzTableBatch -Table $Table -Batch $batch
```

## PARAMETERS

### -Table
Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity will be added

```yaml
Type: Object
Parameter Sets: Table
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Batch
Table batch operation object of type Microsoft.Azure.Cosmos.Table.TableBatchOperation where the entity will be added

```yaml
Type: Object
Parameter Sets: Batch
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PartitionKey
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

### -RowKey
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

### -Property
Hashtable with the columns that will be part of the entity. E.g. `@{"firstName"="Paulo";"lastName"="Marques"}`

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateExisting
Signalizes that command should update existing row, if such found by PartitionKey and RowKey.
If not found, new row is added.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
