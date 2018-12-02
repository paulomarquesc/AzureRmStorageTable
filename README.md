# AzureRmStorageTable
Repository for a sample module to manipulate Azure Storage Table rows/entities.

For more information, please visit the following blog post:
https://blogs.technet.microsoft.com/paulomarques/2017/01/17/working-with-azure-storage-tables-from-powershell/

This module supports *Azure Storage Tables*. Cosmos DB support was removed.

For PowerShell Core version of this module, please refer to a great community contribution by JakeDenyer below:
https://github.com/jakedenyer/AzStorageTable


## Quick Setup
1. In a Windows 10/2016 execute the following cmdlets in order to install required modules
    ```powershell
    Install-Module AzureRm.Storage -AllowClobber -Force
    Install-Module AzureRM.Profile  -AllowClobber -Force
    Install-Module AzureRM.Resources -AllowClobber -Force   
    Install-Module Azure.Storage -AllowClobber -Force
    ```
    
1. Install AzureRmStorageTable
    ```powershell
    Install-Module AzureRmStorageTable
    ```

Below you will get the help content of every function that is exposed through the AzureRmStorageTable module.

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
$resourceGroup = "myResourceGroup"
$storageAccount = "myStorageAccountName"
$tableName = "table01"
$table = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -storageAccountName $storageAccount
```

### -------------------------- EXAMPLE 2 --------------------------
```
# Getting Cosmos DB table object
$resourceGroup = "myResourceGroup"
$databaseName = "myCosmosDbName"
$tableName = "table01"
$table01 = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -databaseName $databaseName
```

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

# Add-StorageTableRow

## SYNOPSIS
Adds a row/entity to a specified table

## SYNTAX

```
Add-StorageTableRow [-table] <AzureStorageTable> [-partitionKey] <String> [-rowKey] <String>
 [-property] <Hashtable>
```

## DESCRIPTION
Adds a row/entity to a specified table

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Adding a row
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey (\[guid\]::NewGuid().tostring()) -property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity will be added

```yaml
Type: AzureStorageTable
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

# Get-AzureStorageTableRowAll

## SYNOPSIS
Returns all rows/entities from a storage table - no filtering

## SYNTAX

```
Get-AzureStorageTableRowAll [-table] <AzureStorageTable>
```

## DESCRIPTION
Returns all rows/entities from a storage table - no filtering

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting all rows
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowAll -table $table
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities

```yaml
Type: AzureStorageTable
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

# Get-AzureStorageTableRowByColumnName

## SYNOPSIS
Returns one or more rows/entities based on a specified column and its value

## SYNTAX

```
Get-AzureStorageTableRowByColumnName [-table] <AzureStorageTable> [-columnName] <String> [-value] <String>
 [-operator] <String>
```

## DESCRIPTION
Returns one or more rows/entities based on a specified column and its value

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting row by firstname
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByColumnName -table $table -columnName "firstName" -value "Paulo" -operator Equal
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities

```yaml
Type: AzureStorageTable
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -columnName
Column name to compare the value to

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

### -value
Value that will be looked for in the defined column

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

### -operator
Supported comparison operator.
Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

# Get-AzureStorageTableRowByCustomFilter

## SYNOPSIS
Returns one or more rows/entities based on custom filter.

## SYNTAX

```
Get-AzureStorageTableRowByCustomFilter [-table] <AzureStorageTable> [-customFilter] <String>
```

## DESCRIPTION
Returns one or more rows/entities based on custom filter.
This custom filter can be
built using the Microsoft.WindowsAzure.Storage.Table.TableQuery class or direct text.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting row by firstname by using the class Microsoft.WindowsAzure.Storage.Table.TableQuery
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
```

### -------------------------- EXAMPLE 2 --------------------------
```
# Getting row by firstname by using text filter directly (oData filter format)
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByCustomFilter -table $table -customFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities

```yaml
Type: AzureStorageTable
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

# Get-AzureStorageTableRowByPartitionKey

## SYNOPSIS
Returns one or more rows/entities based on Partition Key

## SYNTAX

```
Get-AzureStorageTableRowByPartitionKey [-table] <AzureStorageTable> [-partitionKey] <String>
```

## DESCRIPTION
Returns one or more rows/entities based on Partition Key

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Getting rows by partition Key
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext
Get-AzureStorageTableRowByPartitionKey -table $table -partitionKey $newPartitionKey
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities

```yaml
Type: AzureStorageTable
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

# Remove-AzureStorageTableRow

## SYNOPSIS
Remove-AzureStorageTableRow - Removes a specified table row

## SYNTAX

### byEntityPSObjectObject
```
Remove-AzureStorageTableRow -table <AzureStorageTable> -entity <Object>
```

### byPartitionandRowKeys
```
Remove-AzureStorageTableRow -table <AzureStorageTable> -partitionKey <String> -rowKey <String>
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
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
\[string\]$filter1 = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::GenerateFilterCondition("firstName",\[Microsoft.WindowsAzure.Storage.Table.QueryComparisons\]::Equal,"Paulo")
\[string\]$filter2 = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::GenerateFilterCondition("lastName",\[Microsoft.WindowsAzure.Storage.Table.QueryComparisons\]::Equal,"Marques")
\[string\]$finalFilter = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::CombineFilters($filter1,"and",$filter2)
$personToDelete = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
$personToDelete | Remove-AzureStorageTableRow -table $table
```

### -------------------------- EXAMPLE 2 --------------------------
```
# Deleting an entry by using partitionkey and row key directly
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
Remove-AzureStorageTableRow -table $table -partitionKey "TableEntityDemoFullList" -rowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"
```

### -------------------------- EXAMPLE 3 --------------------------
```
# Deleting everything
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
Get-AzureStorageTableRowAll -table $table | Remove-AzureStorageTableRow -table $table
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity exists

```yaml
Type: AzureStorageTable
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

# Update-AzureStorageTableRow

## SYNOPSIS
Updates a table entity

## SYNTAX

```
Update-AzureStorageTableRow [-table] <AzureStorageTable> [-entity] <Object>
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
$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
\[string\]$filter = \[Microsoft.WindowsAzure.Storage.Table.TableQuery\]::GenerateFilterCondition("firstName",\[Microsoft.WindowsAzure.Storage.Table.QueryComparisons\]::Equal,"User1")
$person = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $filter
$person.lastName = "New Last Name"
$person | Update-AzureStorageTableRow -table $table
```

## PARAMETERS

### -table
Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity exists

```yaml
Type: AzureStorageTable
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

# Running automated tests

## Prerequisites

* [Pester](https://github.com/pester/Pester) - PowerShell BDD style testing framework
* [Azure Storage Emulator](https://docs.microsoft.com/en-us/azure/storage/storage-use-emulator) or [Azure Subscription](https://azure.microsoft.com/en-us/free/)
* [Azure Power Shell](https://docs.microsoft.com/en-us/powershell/azure/overview)

## How to run automated tests

### Before you run

Please make sure that your Azure Storage Emulator is up and running if you want to run all tests agains it.

### Run

```
PS> Invoke-Pester
```

![Invoke-Pester](AzureRmStorageTable-Pester.gif)
