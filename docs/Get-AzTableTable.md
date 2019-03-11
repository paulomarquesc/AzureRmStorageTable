---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Get-AzTableTable

## SYNOPSIS
Gets a Table object, it can be from Azure Storage Table or Cosmos DB in preview support.

## SYNTAX

```
Get-AzTableTable -resourceGroup <String> -TableName <String> -storageAccountName <String> [<CommonParameters>]
```

## DESCRIPTION
Gets a Table object, it can be from Azure Storage Table or Cosmos DB in preview support.

## EXAMPLES

### EXAMPLE 1
```
# Getting storage table object
```

$resourceGroup = "myResourceGroup"
$storageAccount = "myStorageAccountName"
$TableName = "table01"
$Table = Get-AzTabletable -resourceGroup $resourceGroup -tableName $TableName -storageAccountName $storageAccount

## PARAMETERS

### -resourceGroup
Resource Group where the Azure Storage Account or Cosmos DB are located

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TableName
Name of the table to retrieve

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -storageAccountName
Storage Account name where the table lives

```yaml
Type: String
Parameter Sets: (All)
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
