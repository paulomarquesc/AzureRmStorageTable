---
external help file: AzureRmStorageTableCoreHelper-help.xml
online version: 
schema: 2.0.0
---

# Get-AzureStorageTableTable

## SYNOPSIS
Gets a Table object, it can be from Azure Storage Table or Cosmos DB in preview support.

## SYNTAX

### AzureTableStorage
```
Get-AzureStorageTableTable -resourceGroup <String> -tableName <String> -storageAccountName <String>
```

### AzureCosmosDb
```
Get-AzureStorageTableTable -resourceGroup <String> -tableName <String> -databaseName <String>
```

## DESCRIPTION
Gets a Table object, it can be from Azure Storage Table or Cosmos DB in preview support.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting storage table object
```

$resourceGroup = "myResourceGroup"
$storageAccount = "myStorageAccountName"
$tableName = "table01"
$table = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -storageAccountName $storageAccount

### -------------------------- EXAMPLE 2 --------------------------
```
# Getting Cosmos DB table object
```

$resourceGroup = "myResourceGroup"
$databaseName = "myCosmosDbName"
$tableName = "table01"
$table01 = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -databaseName $databaseName

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

### -tableName
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
Parameter Sets: AzureTableStorage
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -databaseName
CosmosDB database where the table lives

```yaml
Type: String
Parameter Sets: AzureCosmosDb
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

