
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

# Deprecated Message
$DeprecatedMessage = "IMPORTANT: This function is deprecated and will be removed in the next release, please use Get-AzureStorageTableRow instead."

# Module Functions

function TestAzureStorageTableEmptyKeys($PartitionKey, $RowKey)
{
    $CosmosEmptyKeysErrorMessage = "Cosmos DB table API does not accept empty partition or row keys when using CloudTable.Execute operation, because of this we are disabling this capability in this module and it will not proceed." 

    if ([string]::IsNullOrEmpty($PartitionKey) -or [string]::IsNullOrEmpty($RowKey))
    {
        Throw $CosmosEmptyKeysErrorMessage
    }
}

function ExecuteQueryAsync($TableQuery)
{
	# Internal function
	# Executes query in async mode

	if ($TableQuery -ne $null)
	{
		do
		{
			$Results = $Table.ExecuteQuerySegmentedAsync($TableQuery, $token)
			$token = $Results.ContinuationToken
		} while ($token -ne $null)
	
		return $Results
	}
}

function GetPSObjectFromEntity($entityList)
{
	# Internal function
	# Converts entities output from the ExecuteQuery method of table into an array of PowerShell Objects

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
		$TableName = "table01"
		$Table = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $TableName -storageAccountName $storageAccount
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName="AzTableStorage",Mandatory=$true)]
		[string]$resourceGroup,
		
		[Parameter(Mandatory=$true)]
        [String]$TableName,

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
			$nullTableErrorMessage = "Table $TableName could not be retrieved from $storageAccountName on resource group $resourceGroupName"
		}
		else
		{
			# Future Cosmos implementation
			# $key = $keys.primaryMasterKey
			# $endpoint = "https://{0}.table.Cosmos.azure.com"
			# $nullTableErrorMessage = "Table $TableName could not be retrieved from $<<<TDB VAR>>> on resource group $resourceGroupName"
		}
	}
	else
	{
		throw "An error ocurred while obtaining keys from $storageAccountName."    
	}

	$connString = [string]::Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};TableEndpoint=$endpoint",$storageAccountName,$key)
	[Microsoft.Azure.Cosmos.Table.CloudStorageAccount]$storageAccount = [Microsoft.Azure.Cosmos.Table.CloudStorageAccount]::Parse($connString)
	[Microsoft.Azure.Cosmos.Table.CloudTableClient]$TableClient = [Microsoft.Azure.Cosmos.Table.CloudTableClient]::new($storageAccount.TableEndpoint,$storageAccount.Credentials)
	[Microsoft.Azure.Cosmos.Table.CloudTable]$Table = [Microsoft.Azure.Cosmos.Table.CloudTable]$TableClient.GetTableReference($TableName)

	$Table.CreateIfNotExistsAsync() | Out-Null

    # Checking if there a table got returned
    if ($Table -eq $null)
    {
        throw $nullTableErrorMessage
    }
	
	return $Table
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
		Signalizes that command should update existing row, if such found by PartitionKey and RowKey. If not found, new row is added.
	.EXAMPLE
		# Adding a row
		Add-StorageTableRow -Table $Table -PartitionKey $PartitionKey -RowKey ([guid]::NewGuid().tostring()) -property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,
		
		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [String]$PartitionKey,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
        [String]$RowKey,

		[Parameter(Mandatory=$false)]
        [hashtable]$property,
		[Switch]$UpdateExisting
	)
	
	# Creates the table entity with mandatory PartitionKey and RowKey arguments
	$entity = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList $PartitionKey, $RowKey
    
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
		return ($Table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($entity)))
	}
	else
	{
 		return ($Table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity)))
	}
 
}

function Get-AzureStorageTableRowAll
{
	<#
	.SYNOPSIS
		Returns all rows/entities from a storage table - no Filtering
	.DESCRIPTION
		Returns all rows/entities from a storage table - no Filtering
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.EXAMPLE
		# Getting all rows
		Get-AzureStorageTableRowAll -Table $Table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table
	)

	Write-Verbose $DeprecatedMessage -Verbose

	# No Filtering

	$Result = Get-AzureStorageTableRow -Table $Table

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
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
		Get-AzureStorageTableRowByPartitionKey -Table $Table -PartitionKey $newPartitionKey
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$PartitionKey
	)
	
	Write-Verbose $DeprecatedMessage -Verbose

	# Filtering by Partition Key
	$Result = Get-AzureStorageTableRow -Table $Table -PartitionKey $PartitionKey

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
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
		Get-AzStorageTableRowByPartitionKeyRowKey -Table $Table -PartitionKey $newPartitionKey -RowKey $newRowKey
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$PartitionKey,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$RowKey
	)
	
	# Filtering by Partition Key and Row Key

	Write-Verbose $DeprecatedMessage -Verbose

	$Result = Get-AzureStorageTableRow -Table $Table -PartitionKey $PartitionKey -RowKey $RowKey

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
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
	.PARAMETER GuidValue
		Value that will be looked for in the defined column as Guid
	.PARAMETER Operator
		Supported comparison Operator. Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"
	.EXAMPLE
		# Getting row by firstname
		Get-AzureStorageTableRowByColumnName -Table $Table -ColumnName "firstName" -value "Paulo" -Operator Equal
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true)]
		[string]$ColumnName,

		[Parameter(ParameterSetName="byString",Mandatory=$true)]
		[AllowEmptyString()]
		[string]$Value,

		[Parameter(ParameterSetName="byGuid",Mandatory=$true)]
		[guid]$GuidValue,

		[Parameter(Mandatory=$true)]
		[validateSet("Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual")]
		[string]$Operator
	)

	Write-Verbose $DeprecatedMessage -Verbose

	# Filtering by Columnn Name

	if ($PSCmdlet.ParameterSetName -eq "byString")
	{			
		Get-AzureStorageTableRow -Table $Table -ColumnName $ColumnName -value $Value -Operator $Operator
	}
	else
	{
		Get-AzureStorageTableRow -Table $Table -ColumnName $ColumnName -GuidValue $GuidValue -Operator $Operator
	}

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}
}

function Get-AzureStorageTableRowByCustomFilter
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on custom Filter.
	.DESCRIPTION
		Returns one or more rows/entities based on custom Filter. This custom Filter can be
		built using the Microsoft.Azure.Cosmos.Table.TableQuery class or direct text.
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.PARAMETER CustomFilter
		Custom Filter string.
	.EXAMPLE
		# Getting row by firstname by using the class Microsoft.Azure.Cosmos.Table.TableQuery
		$saContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$Table = Get-AzureStorageTable -Name $TableName -Context $saContext
		Get-AzureStorageTableRowByCustomFilter -Table $Table -CustomFilter $finalFilter
	.EXAMPLE
		# Getting row by firstname by using text Filter directly (oData Filter format)
		Get-AzureStorageTableRowByCustomFilter -Table $Table -CustomFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true)]
		[string]$CustomFilter
	)
	
	Write-Verbose $DeprecatedMessage -Verbose

	# Custom Filter

	$Result = Get-AzureStorageTableRow -Table $Table -CustomFilter $CustomFilter

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}
}

function Get-AzureStorageTableRow
{
	<#
	.SYNOPSIS
		Returns all rows/entities from a storage table - no Filtering
	.DESCRIPTION
		Returns all rows/entities from a storage table - no Filtering
	.PARAMETER Table
		Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities
	.EXAMPLE
		# Getting all rows
		Get-AzureStorageTableRowAll -Table $Table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,ParameterSetName="GetAll")]
		[Parameter(ParameterSetName="byPartitionKey")]
		[Parameter(ParameterSetName="byPartRowKeys")]
		[Parameter(ParameterSetName="byColummnString")]
		[Parameter(ParameterSetName="byColummnGuid")]
		[Parameter(ParameterSetName="byCustomFilter")]
		$Table,

		[Parameter(Mandatory=$true,ParameterSetName="byPartitionKey")]
		[Parameter(ParameterSetName="byPartRowKeys")]
		[AllowEmptyString()]
		[string]$PartitionKey,

		[Parameter(Mandatory=$true,ParameterSetName="byPartRowKeys")]
		[AllowEmptyString()]
		[string]$RowKey,

		[Parameter(Mandatory=$true, ParameterSetName="byColummnString")]
		[Parameter(ParameterSetName="byColummnGuid")]
		[string]$ColumnName,

		[Parameter(Mandatory=$true, ParameterSetName="byColummnString")]
		[AllowEmptyString()]
		[string]$Value,

		[Parameter(ParameterSetName="byColummnGuid",Mandatory=$true)]
		[guid]$GuidValue,

		[Parameter(Mandatory=$true, ParameterSetName="byColummnString")]
		[Parameter(ParameterSetName="byColummnGuid")]
		[validateSet("Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual")]
		[string]$Operator,
		
		[Parameter(Mandatory=$true, ParameterSetName="byCustomFilter")]
		[string]$CustomFilter
	)

	$TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

	# Building filters if any
	if ($PSCmdlet.ParameterSetName -eq "byPartitionKey")
	{
		[string]$Filter = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
			[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$PartitionKey)
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byPartRowKeys")
	{
		[string]$FilterA = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
			[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$PartitionKey)

		[string]$FilterB = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("RowKey",`
			[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$RowKey)

		[string]$Filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($FilterA,"and",$FilterB)
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byColummnString")
	{
		[string]$Filter = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition($ColumnName,[Microsoft.Azure.Cosmos.Table.QueryComparisons]::$Operator,$Value)
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byColummnGuid")
	{
		[string]$Filter = `
			[Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterConditionForGuid($ColumnName,[Microsoft.Azure.Cosmos.Table.QueryComparisons]::$Operator,$GuidValue)
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byCustomFilter")
	{
		[string]$Filter = $CustomFilter
	}
	
	# Adding filter if not null
	if (-not [string]::IsNullOrEmpty($Filter))
	{
		$TableQuery.FilterString = $Filter
	}

	# Getting results
	if (($TableQuery.FilterString -ne $null) -or ($PSCmdlet.ParameterSetName -eq "GetAll"))
	{
		$Result = ExecuteQueryAsync($TableQuery)

		if (-not [string]::IsNullOrEmpty($Result.Result.Results))
		{
			return (GetPSObjectFromEntity($Result.Result.Results))
		}
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

		[string]$Filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"User1")
		$person = Get-AzureStorageTableRowByCustomFilter -Table $Table -CustomFilter $Filter
		$person.lastName = "New Last Name"
		$person | Update-AzureStorageTableRow -Table $Table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

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
    return ($Table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrMerge($updatedEntity)))
  
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
		[string]$Filter1 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Paulo")
		[string]$Filter2 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("lastName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Marques")
		[string]$finalFilter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($Filter1,"and",$Filter2)
		$personToDelete = Get-AzureStorageTableRowByCustomFilter -Table $Table -CustomFilter $finalFilter
		$personToDelete | Remove-AzureStorageTableRow -Table $Table
	.EXAMPLE
		# Deleting an entry by using PartitionKey and row key directly
		Remove-AzureStorageTableRow -Table $Table -PartitionKey "TableEntityDemoFullList" -RowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"
	.EXAMPLE
		# Deleting everything
		Get-AzureStorageTableRowAll -Table $Table | Remove-AzureStorageTableRow -Table $Table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="byEntityPSObjectObject")]
		$entity,

		[Parameter(Mandatory=$true,ParameterSetName="byPartitionandRowKeys")]
		[AllowEmptyString()]
		[string]$PartitionKey,

		[Parameter(Mandatory=$true,ParameterSetName="byPartitionandRowKeys")]
		[AllowEmptyString()]
		[string]$RowKey
	)

	begin
	{
		$updatedEntityList = @()
		$updatedEntityList += $entity

		if ($updatedEntityList.Count -gt 1)
		{
			throw "Delete operation cannot happen on an array of entities, altough you can pipe multiple items."
		}
		
		$Results = @()
	}
	
	process
	{
		if ($PSCmdlet.ParameterSetName -eq "byEntityPSObjectObject")
		{
			$PartitionKey = $entity.PartitionKey
			$RowKey = $entity.RowKey
		}

		$entityToDelete = [Microsoft.Azure.Cosmos.Table.DynamicTableEntity]($Table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Retrieve($PartitionKey,$RowKey))).Result.Result
   
		if ($entityToDelete -ne $null)
		{
   			$Results += $Table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Delete($entityToDelete))
		}
	}
	
	end
	{
		return ,$Results
	}
}

# Aliases
New-Alias -Name Add-AzureStorageTableRow -Value Add-StorageTableRow
