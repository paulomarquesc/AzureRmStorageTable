
<#
.SYNOPSIS
	AzureRmStorageTableCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Table rows/entities.
.DESCRIPTION
  	AzureRmStorageTableCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Table rows/entities.
.NOTES
	This module depends on Az.Accounts, Az.Resources and Az.Storage PowerShell modules	

	If running this module from Azure Automation, please make sure you check out this blog post for more information:
	https://blogs.technet.microsoft.com/paulomarques/2017/01/17/working-with-azure-storage-tables-from-powershell/
	
#>

# Loading DLLS
$path = $PSScriptRoot
[System.Reflection.Assembly]::LoadFrom((join-path $path 'Microsoft.OData.Core.dll'))
[System.Reflection.Assembly]::LoadFrom((join-path $path 'Microsoft.OData.Edm.dll'))
[System.Reflection.Assembly]::LoadFrom((join-path $path 'Microsoft.Spatial.dll'))
[System.Reflection.Assembly]::LoadFrom((join-path $path 'Newtonsoft.Json.dll'))
[System.Reflection.Assembly]::LoadFrom((join-path $path 'Microsoft.Azure.DocumentDB.Core.dll'))
[System.Reflection.Assembly]::LoadFrom((join-path $path 'Microsoft.Azure.Cosmos.Table.dll'))

# Module Functions

function Test-AzureStorageTableEmptyKeys
{
	[CmdletBinding()]
	param
	(
		[string]$partitionKey,
        [String]$rowKey
	)
    
    $CosmosEmptyKeysErrorMessage = "Cosmos DB table API does not accept empty partition or row keys when using CloudTable.Execute operation, because of this we are disabling this capability in this module and it will not proceed." 

    if ([string]::IsNullOrEmpty($partitionKey) -or [string]::IsNullOrEmpty($rowKey))
    {
        Throw $CosmosEmptyKeysErrorMessage
    }
}

function Get-AzureStorageTableTable
{
	<#
	.SYNOPSIS
		Gets a Table object, it can be from Azure Storage Table or Cosmos DB in preview support.
	.DESCRIPTION
		Gets a Table object, it can be from Azure Storage Table or Cosmos DB in preview support.
	.PARAMETER resourceGroup
        Resource Group where the Azure Storage Account or Cosmos DB are located
    .PARAMETER tableName
        Name of the table to retrieve
    .PARAMETER storageAccountName
        Storage Account name where the table lives
	.EXAMPLE
		# Getting storage table object
		$resourceGroup = "myResourceGroup"
		$storageAccount = "myStorageAccountName"
		$tableName = "table01"
		$table = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -storageAccountName $storageAccount
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName="AzTableStorage",Mandatory=$true)]
		[string]$resourceGroup,
		
		[Parameter(Mandatory=$true)]
        [String]$tableName,

		[Parameter(ParameterSetName="AzTableStorage",Mandatory=$true)]
        [String]$storageAccountName
	)
	
	$nullTableErrorMessage = [string]::Empty

	$keys = Invoke-AzResourceAction -Action listKeys -ResourceType "Microsoft.Storage/storageAccounts" -ApiVersion "2017-10-01" -ResourceGroupName $resourceGroup -Name $storageAccountName -Force

	if ($keys -ne $null)
	{
		if ($PSCmdlet.ParameterSetName -eq "AzTableStorage" )
		{
			$key = $keys.keys[0].value
			$endpoint = "https://{0}.table.core.windows.net"
			$nullTableErrorMessage = "Table $tableName could not be retrieved from $storageAccountName on resource group $resourceGroupName"
		}
		else
		{
			# Future Cosmos implementation
			# $key = $keys.primaryMasterKey
			# $endpoint = "https://{0}.table.Cosmos.azure.com"
			# $nullTableErrorMessage = "Table $tableName could not be retrieved from $<<<TDB VAR>>> on resource group $resourceGroupName"
		}
	}
	else
	{
		throw "An error ocurred while obtaining keys from $storageAccountName."    
	}

	$connString = [string]::Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};TableEndpoint=$endpoint",$storageAccountName,$key)
	[Microsoft.Azure.Cosmos.Table.CloudStorageAccount]$storageAccount = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($connString)
	[Microsoft.Azure.Cosmos.Table.CloudTableClient]$tableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($storageAccount.TableEndpoint,$storageAccount.Credentials)
	[Microsoft.Azure.Cosmos.Table.CloudTable]$table = [Microsoft.Azure.Cosmos.Table.CloudTable]$tableClient.GetTableReference($tableName)

	$table.CreateIfNotExistsAsync() | Out-Null

    # Checking if there a table got returned
    if ($table -eq $null)
    {
        throw $nullTableErrorMessage
    }
	
	return $table
}

function Add-StorageTableRow
{
	<#
	.SYNOPSIS
		Adds a row/entity to a specified table
	.DESCRIPTION
		Adds a row/entity to a specified table
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity will be added
	.PARAMETER PartitionKey
		Identifies the table partition
	.PARAMETER RowKey
		Identifies a row within a partition
	.PARAMETER Property
		Hashtable with the columns that will be part of the entity. e.g. @{"firstName"="Paulo";"lastName"="Marques"}
	.PARAMETER UpdateExisting
		Signalizes that command should update existing row, if such found by partitionKey and rowKey. If not found, new row is added.
	.EXAMPLE
		# Adding a row
		Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,
		
		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [String]$partitionKey,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [String]$rowKey,

		[Parameter(Mandatory=$false)]
        [hashtable]$property,
		[Switch]$UpdateExisting
	)
	
	# Creates the table entity with mandatory partitionKey and rowKey arguments
	$entity = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList $partitionKey, $rowKey
    
    # Adding the additional columns to the table entity
	foreach ($prop in $property.Keys)
	{
		if ($prop -ne "TableTimestamp")
		{
			$entity.Properties.Add($prop, $property.Item($prop))
		}
	}

    if ($UpdateExisting)
	{
		return ($table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($entity)))
	}
	else
	{
 		return ($table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity)))
	}
 
}

function Get-PSObjectFromEntity
{
	# Internal function
	# Converts entities output from the ExecuteQuery method of table into an array of PowerShell Objects

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$entityList
	)

	$returnObjects = @()

	if (-not [string]::IsNullOrEmpty($entityList))
	{
		foreach ($entity in $entityList)
		{
			$entityNewObj = New-Object -TypeName psobject
			$entity.Properties.Keys | ForEach-Object {Add-Member -InputObject $entityNewObj -Name $_ -Value $entity.Properties[$_].PropertyAsObject -MemberType NoteProperty}

			# Adding table entity other attributes
			Add-Member -InputObject $entityNewObj -Name "PartitionKey" -Value $entity.PartitionKey -MemberType NoteProperty
			Add-Member -InputObject $entityNewObj -Name "RowKey" -Value $entity.RowKey -MemberType NoteProperty
			Add-Member -InputObject $entityNewObj -Name "TableTimestamp" -Value $entity.Timestamp -MemberType NoteProperty
			Add-Member -InputObject $entityNewObj -Name "Etag" -Value $entity.Etag -MemberType NoteProperty

			$returnObjects += $entityNewObj
		}
	}

	return $returnObjects

}

function Get-AzureStorageTableRowAll
{
	<#
	.SYNOPSIS
		Returns all rows/entities from a storage table - no filtering
	.DESCRIPTION
		Returns all rows/entities from a storage table - no filtering
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.EXAMPLE
		# Getting all rows
		Get-AzureStorageTableRowAll -table $table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table
	)

	# No filtering

	$tableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	do
	{
		$results = $table.ExecuteQuerySegmentedAsync($tableQuery, $token)
		$token = $results.ContinuationToken
	} while ($token -ne $null)

	if (-not [string]::IsNullOrEmpty($results.Result.Results))
	{
		return (Get-PSObjectFromEntity -entityList $results.Result.Results)
	}

}

function Get-AzureStorageTableRowByPartitionKey
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on Partition Key
	.DESCRIPTION
		Returns one or more rows/entities based on Partition Key
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.PARAMETER PartitionKey
		Identifies the table partition
	.EXAMPLE
		# Getting rows by partition Key
		Get-AzureStorageTableRowByPartitionKey -table $table -partitionKey $newPartitionKey
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$partitionKey
	)
	
	# Filtering by Partition Key
	$tableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	[string]$filter = `
		[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
		[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$partitionKey)

	$tableQuery.FilterString = $filter

	$token = $null
	do
	{
		$result = $table.ExecuteQuerySegmentedAsync($tableQuery, $token)
		$token = $result.ContinuationToken

	} while ($token -ne $null)


	if (-not [string]::IsNullOrEmpty($result.Result.Results))
	{
		return (Get-PSObjectFromEntity -entityList $result.Result.Results)
	}
}
function Get-AzureStorageTableRowByPartitionKeyRowKey
{
	<#
	.SYNOPSIS
		Returns one entitie based on Partition Key and RowKey
	.DESCRIPTION
		Returns one entitie based on Partition Key and RowKey
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.PARAMETER PartitionKey
		Identifies the table partition
	.PARAMETER RowKey
        Identifies the row key in the partition
	.EXAMPLE
		# Getting rows by Partition Key and Row Key
		Get-AzStorageTableRowByPartitionKeyRowKey -table $table -partitionKey $newPartitionKey -rowKey $newRowKey
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$partitionKey,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$rowKey

	)
	
	# Filtering by Partition Key and Row Key

	$tableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	[string]$filter1 = `
		[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
		[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$partitionKey)

	[string]$filter2 = `
		[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("RowKey",`
		[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$rowKey)

    [string]$filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($filter1,"and",$filter2)

	$tableQuery.FilterString = $filter

	$token = $null
	do
	{
		$result = $table.ExecuteQuerySegmentedAsync($tableQuery, $token)
		$token = $result.ContinuationToken

	} while ($token -ne $null)

	if (-not [string]::IsNullOrEmpty($result.Result.Results))
	{
		return (Get-PSObjectFromEntity -entityList $result.Result.Results)
	}
}

function Get-AzureStorageTableRowByColumnName
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on a specified column and its value
	.DESCRIPTION
		Returns one or more rows/entities based on a specified column and its value
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.PARAMETER ColumnName
		Column name to compare the value to
	.PARAMETER Value
		Value that will be looked for in the defined column
	.PARAMETER Operator
		Supported comparison operator. Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"
	.EXAMPLE
		# Getting row by firstname
		Get-AzureStorageTableRowByColumnName -table $table -columnName "firstName" -value "Paulo" -operator Equal
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true)]
		[string]$columnName,

		[Parameter(ParameterSetName="byString",Mandatory=$true)]
		[AllowEmptyString()]
		[string]$value,

		[Parameter(ParameterSetName="byGuid",Mandatory=$true)]
		[guid]$guidValue,

		[Parameter(Mandatory=$true)]
		[validateSet("Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual")]
		[string]$operator
	)
	
	# Filtering by Partition Key

	$tableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	if ($PSCmdlet.ParameterSetName -eq "byString") {			
		[string]$filter = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition($columnName,[Microsoft.Azure.Cosmos.Table.QueryComparisons]::$operator,$value)
	}

	if ($PSCmdlet.ParameterSetName -eq "byGuid") {
		[string]$filter = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterConditionForGuid($columnName,[Microsoft.Azure.Cosmos.Table.QueryComparisons]::$operator,$guidValue)
	}

	$tableQuery.FilterString = $filter

	$token = $null
	do
	{
		$result = $table.ExecuteQuerySegmentedAsync($tableQuery, $token)
		$token = $result.ContinuationToken

	} while ($token -ne $null)


	if (-not [string]::IsNullOrEmpty($result.Result.Results))
	{
		return (Get-PSObjectFromEntity -entityList $result.Result.Results)
	}
}

function Get-AzureStorageTableRowByCustomFilter
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on custom filter.
	.DESCRIPTION
		Returns one or more rows/entities based on custom filter. This custom filter can be
		built using the Microsoft.Azure.Cosmos.Table.TableQuery class or direct text.
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.PARAMETER customFilter
		Custom filter string.
	.EXAMPLE
		# Getting row by firstname by using the class Microsoft.Azure.Cosmos.Table.TableQuery
		$saContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
		Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
	.EXAMPLE
		# Getting row by firstname by using text filter directly (oData filter format)
		Get-AzureStorageTableRowByCustomFilter -table $table -customFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true)]
		[string]$customFilter
	)
	
	# Filtering by Partition Key
	$tableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	$tableQuery.FilterString = $customFilter

	$token = $null
	do
	{
		$result = $table.ExecuteQuerySegmentedAsync($tableQuery, $token)
		$token = $result.ContinuationToken

	} while ($token -ne $null)

 
	if (-not [string]::IsNullOrEmpty($result.Result.Results))
	{
		return (Get-PSObjectFromEntity -entityList $result.Result.Results)
	}
}

function Get-AzureStorageTableRow
{
	<#
	.SYNOPSIS
		Returns all rows/entities from a storage table - no filtering
	.DESCRIPTION
		Returns all rows/entities from a storage table - no filtering
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.EXAMPLE
		# Getting all rows
		Get-AzureStorageTableRowAll -table $table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true,ParameterSetName="byPartitionKey")]
		[AllowEmptyString()]
		[string]$PartitionKey
	)

	# No filtering

	$tableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	[string]$filter = `
	[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
	[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$partitionKey)

	$tableQuery.FilterString = $filter

	do
	{
		$results = $table.ExecuteQuerySegmentedAsync($tableQuery, $token)
		$token = $results.ContinuationToken
	} while ($token -ne $null)

	if (-not [string]::IsNullOrEmpty($results.Result.Results))
	{
		return (Get-PSObjectFromEntity -entityList $results.Result.Results)
	}

}



function Update-AzureStorageTableRow
{
	<#
	.SYNOPSIS
		Updates a table entity
	.DESCRIPTION
		Updates a table entity. To work with this cmdlet, you need first retrieve an entity with one of the Get-AzureStorageTableRow cmdlets available
		and store in an object, change the necessary properties and then perform the update passing this modified entity back, through Pipeline or as argument.
		Notice that this cmdlet accepts only one entity per execution. 
		This cmdlet cannot update Partition Key and/or RowKey because it uses those two values to locate the entity to update it, if this operation is required
		please delete the old entity and add the new one with the updated values instead.
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity exists
	.PARAMETER Entity
		The entity/row with new values to perform the update.
	.EXAMPLE
		# Updating an entity

		[string]$filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"User1")
		$person = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $filter
		$person.lastName = "New Last Name"
		$person | Update-AzureStorageTableRow -table $table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		$entity
	)
    
    # Only one entity at a time can be updated
    $updatedEntityList = @()
    $updatedEntityList += $entity

    if ($updatedEntityList.Count -gt 1)
    {
        throw "Update operation can happen on only one entity at a time, not in a list/array of entities."
    }

	$updatedEntity = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList $entity.PartitionKey, $entity.RowKey
	
	# Iterating over PS Object properties to add to the updated entity 
	foreach ($prop in $entity.psobject.Properties)
	{
		if (($prop.name -ne "PartitionKey") -and ($prop.name -ne "RowKey") -and ($prop.name -ne "Timestamp") -and ($prop.name -ne "Etag") -and ($prop.name -ne "TableTimestamp"))
		{
			$updatedEntity.Properties.Add($prop.name, $prop.Value)
		}
	}

	$updatedEntity.ETag = $entity.Etag

    # Updating the dynamic table entity to the table
    return ($table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrMerge($updatedEntity)))
  
}

function Remove-AzureStorageTableRow
{
	<#
	.SYNOPSIS
		Remove-AzureStorageTableRow - Removes a specified table row
	.DESCRIPTION
		Remove-AzureStorageTableRow - Removes a specified table row. It accepts multiple deletions through the Pipeline when passing entities returned from the Get-AzureStorageTableRow
		available cmdlets. It also can delete a row/entity using Partition and Row Key properties directly.
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity exists
	.PARAMETER Entity (ParameterSetName=byEntityPSObjectObject)
		The entity/row with new values to perform the deletion.
	.PARAMETER PartitionKey (ParameterSetName=byPartitionandRowKeys)
		Partition key where the entity belongs to.
	.PARAMETER RowKey (ParameterSetName=byPartitionandRowKeys)
		Row key that uniquely identifies the entity within the partition.		 
	.EXAMPLE
		# Deleting an entry by entity PS Object
		[string]$filter1 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Paulo")
		[string]$filter2 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("lastName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Marques")
		[string]$finalFilter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($filter1,"and",$filter2)
		$personToDelete = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
		$personToDelete | Remove-AzureStorageTableRow -table $table
	.EXAMPLE
		# Deleting an entry by using partitionkey and row key directly
		Remove-AzureStorageTableRow -table $table -partitionKey "TableEntityDemoFullList" -rowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"
	.EXAMPLE
		# Deleting everything
		Get-AzureStorageTableRowAll -table $table | Remove-AzureStorageTableRow -table $table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="byEntityPSObjectObject")]
		$entity,

		[Parameter(Mandatory=$true,ParameterSetName="byPartitionandRowKeys")]
		[AllowEmptyString()]
		[string]$partitionKey,

		[Parameter(Mandatory=$true,ParameterSetName="byPartitionandRowKeys")]
		[AllowEmptyString()]
		[string]$rowKey
	)

	begin
	{
		$updatedEntityList = @()
		$updatedEntityList += $entity

		if ($updatedEntityList.Count -gt 1)
		{
			throw "Delete operation cannot happen on an array of entities, altough you can pipe multiple items."
		}
		
		$results = @()
	}
	
	process
	{
		if ($PSCmdlet.ParameterSetName -eq "byEntityPSObjectObject")
		{
			$partitionKey = $entity.PartitionKey
			$rowKey = $entity.RowKey
		}

		$entityToDelete = [Microsoft.Azure.Cosmos.Table.DynamicTableEntity]($table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Retrieve($partitionKey,$rowKey))).Result.Result
   
		if ($entityToDelete -ne $null)
		{
   			$results += $table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Delete($entityToDelete))
		}
	}
	
	end
	{
		return ,$results
	}
}

# Aliases
New-Alias -Name Add-AzureStorageTableRow -Value Add-StorageTableRow
