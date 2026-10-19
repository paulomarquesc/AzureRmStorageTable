
<#
.SYNOPSIS
	AzureRmStorageTableCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Table rows/entities.
.DESCRIPTION
  	AzureRmStorageTableCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Table rows/entities.
.NOTES
	This module depends on Az.Accounts, Az.Resources and Az.Storage PowerShell modules
#>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Requires -modules Az.Storage, Az.Resources

# Deprecated Message
$DeprecatedMessage = "IMPORTANT: This function is deprecated and will be removed in the next release, please use Get-AzTableRow instead."

# Module Functions

function TestAzTableEmptyKeys
{
	param
	(
		[Parameter(Mandatory=$true)]
		$PartitionKey,

		[Parameter(Mandatory=$true)]
		$RowKey
	)

    $EmptyKeysErrorMessage = "Table API does not accept empty partition or row keys when using table operations, because of this we are disabling this capability in this module and it will not proceed."

    if ([string]::IsNullOrEmpty($PartitionKey) -or [string]::IsNullOrEmpty($RowKey))
    {
        Throw $EmptyKeysErrorMessage
    }
}

function ExecuteQueryAsync
{
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$false)]
		[string]$Filter = $null,

		[Parameter(Mandatory=$false)]
		$SelectColumn = $null,

		[Parameter(Mandatory=$false)]
		[Nullable[int]]$Top = $null,

		[Parameter(Mandatory=$false)]
		$TableQuery = $null
	)
	# Internal function
	# Executes table query

	if ($null -ne $TableQuery)
	{
		if ($TableQuery -is [string])
		{
			$Filter = $TableQuery
		}
		else
		{
			if ($TableQuery.FilterString) { $Filter = $TableQuery.FilterString }
			if ($TableQuery.SelectColumns) { $SelectColumn = $TableQuery.SelectColumns }
			if ($TableQuery.TakeCount) { $Top = $TableQuery.TakeCount }
		}
	}

	$AllRows = [System.Collections.Generic.List[Azure.Data.Tables.TableEntity]]::new()
	$count = 0
	[string]$queryString = if ([string]::IsNullOrEmpty($Filter)) { $null } else { $Filter }
	$results = $Table.Query[Azure.Data.Tables.TableEntity]($queryString, [Nullable[int]]$null, $SelectColumn, [System.Threading.CancellationToken]::None)

	foreach ($row in $results)
	{
		$AllRows.Add($row)
		$count++
		if (($null -ne $Top) -and ($count -ge $Top))
		{
			break
		}
	}

	return ,$AllRows
}

function GetPSObjectFromEntity($entityList)
{
	# Internal function
	# Converts entities output from TableClient into an array of PowerShell Objects

	$returnObjects = @()

	if ($null -ne $entityList)
	{
		if ($entityList -is [Azure.Data.Tables.TableEntity])
		{
			$entities = [System.Collections.Generic.List[Azure.Data.Tables.TableEntity]]::new()
			$entities.Add($entityList)
		}
		else
		{
			$entities = $entityList
		}

		foreach ($entity in $entities)
		{
			if ($entity -is [Azure.Data.Tables.TableEntity])
			{
				$entityNewObj = New-Object -TypeName psobject

				foreach ($key in $entity.Keys)
				{
					if ($key -ne "PartitionKey" -and $key -ne "RowKey" -and $key -ne "Timestamp" -and $key -ne "odata.etag")
					{
						Add-Member -InputObject $entityNewObj -Name $key -Value $entity[$key] -MemberType NoteProperty
					}
				}

				# Adding table entity other attributes
				Add-Member -InputObject $entityNewObj -Name "PartitionKey" -Value $entity.PartitionKey -MemberType NoteProperty
				Add-Member -InputObject $entityNewObj -Name "RowKey" -Value $entity.RowKey -MemberType NoteProperty
				Add-Member -InputObject $entityNewObj -Name "TableTimestamp" -Value $entity.Timestamp -MemberType NoteProperty
				$etag = if ($null -ne $entity.ETag) { $entity.ETag.ToString() } else { "" }
				Add-Member -InputObject $entityNewObj -Name "Etag" -Value $etag -MemberType NoteProperty

				$returnObjects += $entityNewObj
			}
		}
	}

	return $returnObjects
}


function Get-AzTableTable
{
	<#
	.SYNOPSIS
		Gets a Table object to be used in all other cmdlets.
	.DESCRIPTION
		Gets a Table object to be used in all other cmdlets.
	.PARAMETER resourceGroup
        Resource Group where the Azure Storage Account is located
    .PARAMETER tableName
        Name of the table to retrieve
    .PARAMETER storageAccountName
        Storage Account name where the table lives
	.EXAMPLE
		# Getting storage table object
		$resourceGroup = "myResourceGroup"
		$storageAccount = "myStorageAccountName"
		$TableName = "table01"
		$Table = Get-AzTabletable -resourceGroup $resourceGroup -tableName $TableName -storageAccountName $storageAccount
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName="AzTableStorage",Mandatory=$true)]
		[string]$resourceGroup,

		[Parameter(Mandatory=$true)]
        [String]$TableName,

		[Parameter(ParameterSetName="AzTableStorage",Mandatory=$true)]
		[String]$storageAccountName,

		[Parameter(ParameterSetName="AzStorageEmulator",Mandatory=$true)]
        [switch]$UseStorageEmulator
	)

	# Validating name
	if ($TableName.Contains("_") -or $TableName.Contains("-"))
	{
		throw "Invalid table name: $TableName"
	}

	$nullTableErrorMessage = [string]::Empty

	if ($PSCmdlet.ParameterSetName -ne "AzStorageEmulator")
	{
		$keys = Invoke-AzResourceAction -Action listKeys -ResourceType "Microsoft.Storage/storageAccounts" -ApiVersion "2017-10-01" -ResourceGroupName $resourceGroup -Name $storageAccountName -Force

		if ($keys -ne $null)
		{
			if ($PSCmdlet.ParameterSetName -eq "AzTableStorage" )
			{
				$key = $keys.keys[0].value
				$endpoint = "https://{0}.table.core.windows.net"
				$nullTableErrorMessage = "Table $TableName could not be retrieved from $storageAccountName on resource group $resourceGroupName"
			}
		}
		else
		{
			throw "An error ocurred while obtaining keys from $storageAccountName."
		}

		$connString = [string]::Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};TableEndpoint=$endpoint",$storageAccountName,$key)
		[Azure.Data.Tables.TableClient]$Table = [Azure.Data.Tables.TableClient]::new($connString, $TableName)
		$Table.CreateIfNotExists() | Out-Null
	}
	else
	{
		# https://docs.microsoft.com/en-us/azure/storage/common/storage-use-emulator
		$nullTableErrorMessage = "Table $TableName could not be retrieved from Azure Storage Emulator"
		$connString = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
		[Azure.Data.Tables.TableClient]$Table = [Azure.Data.Tables.TableClient]::new($connString, $TableName)
		$Table.CreateIfNotExists() | Out-Null
	}

	# Checking if there a table got returned
	if ($Table -eq $null)
	{
		throw $nullTableErrorMessage
	}

	return $Table
}

function Add-AzTableRow
{
	<#
	.SYNOPSIS
		Adds a row/entity to a specified table
	.DESCRIPTION
		Adds a row/entity to a specified table
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient where the entity will be added
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
		Add-AzTableRow -Table $Table -PartitionKey $PartitionKey -RowKey ([guid]::NewGuid().tostring()) -property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
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
	$entity = [Azure.Data.Tables.TableEntity]::new($PartitionKey, $RowKey)

	# Adding the additional columns to the table entity
	if ($null -ne $property)
	{
		foreach ($prop in $property.Keys)
		{
			if ($prop -ne "TableTimestamp")
			{
				$entity[$prop] = $property.Item($prop)
			}
		}
	}

	if ($UpdateExisting)
	{
		return ($Table.UpsertEntity($entity, [Azure.Data.Tables.TableUpdateMode]::Replace, [System.Threading.CancellationToken]::None))
	}
	else
	{
		return ($Table.AddEntity($entity, [System.Threading.CancellationToken]::None))
	}
}

function Get-AzTableRowAll
{
	<#
	.SYNOPSIS
		Returns all rows/entities from a storage table - no Filtering
	.DESCRIPTION
		Returns all rows/entities from a storage table - no Filtering
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient to retrieve entities
	.EXAMPLE
		# Getting all rows
		Get-AzTableRowAll -Table $Table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table
	)

	Write-Verbose $DeprecatedMessage -Verbose

	# No Filtering

	$Result = Get-AzTableRow -Table $Table

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}

}

function Get-AzTableRowByPartitionKey
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on Partition Key
	.DESCRIPTION
		Returns one or more rows/entities based on Partition Key
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient to retrieve entities
	.PARAMETER PartitionKey
		Identifies the table partition
	.PARAMETER Top
		Return only the first n rows from the query
	.EXAMPLE
		# Getting rows by partition Key
		Get-AzTableRowByPartitionKey -Table $Table -PartitionKey "mypartitionkey"
	.EXAMPLE
		# Getting rows by partition key with a maximum number returned
		Get-AzTableRowByPartitionKey -Table $Table -PartitionKey "mypartitionkey" -Top 10
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$PartitionKey,

		[Parameter(Mandatory=$false)]
		[Nullable[Int32]]$Top = $null
	)

	Write-Verbose $DeprecatedMessage -Verbose

	# Filtering by Partition Key
	$Result = Get-AzTableRow -Table $Table -PartitionKey $PartitionKey -Top $Top

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}

}
function Get-AzTableRowByPartitionKeyRowKey
{
	<#
	.SYNOPSIS
		Returns one entity based on Partition Key and RowKey
	.DESCRIPTION
		Returns one entity based on Partition Key and RowKey
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient to retrieve entities
	.PARAMETER PartitionKey
		Identifies the table partition
	.PARAMETER RowKey
        Identifies the row key in the partition
	.PARAMETER Top
		Return only the first n rows from the query
	.EXAMPLE
		# Getting rows by Partition Key and Row Key
		Get-AzStorageTableRowByPartitionKeyRowKey -Table $Table -PartitionKey "partition1" -RowKey "id12345"
	.EXAMPLE
		# Getting rows by Partition Key and Row Key, with a maximum number returned
		Get-AzStorageTableRowByPartitionKeyRowKey -Table $Table -PartitionKey "partition1" -RowKey "id12345" -Top 10
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
		[string]$RowKey,

		[Parameter(Mandatory=$false)]
		[Nullable[Int32]]$Top = $null
	)

	# Filtering by Partition Key and Row Key

	Write-Verbose $DeprecatedMessage -Verbose

	$Result = Get-AzTableRow -Table $Table -PartitionKey $PartitionKey -RowKey $RowKey -Top $Top

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}
}

function Get-AzTableRowByColumnName
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on a specified column and its value
	.DESCRIPTION
		Returns one or more rows/entities based on a specified column and its value
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient to retrieve entities
	.PARAMETER ColumnName
		Column name to compare the value to
	.PARAMETER Value
		Value that will be looked for in the defined column
	.PARAMETER GuidValue
		Value that will be looked for in the defined column as Guid
	.PARAMETER Operator
		Supported comparison Operator. Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"
	.PARAMETER Top
		Return only the first n rows from the query
	.EXAMPLE
		# Getting row by firstname
		Get-AzTableRowByColumnName -Table $Table -ColumnName "firstName" -value "Paulo" -Operator Equal
	.EXAMPLE
		# Getting row by firstname with a maximum number of rows returned
		Get-AzTableRowByColumnName -Table $Table -ColumnName "firstName" -value "Paulo" -Operator Equal -Top 10
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
		[string]$Operator,

		[Parameter(Mandatory=$false)]
		[Nullable[Int32]]$Top = $null
	)

	Write-Verbose $DeprecatedMessage -Verbose

	# Filtering by Columnn Name

	if ($PSCmdlet.ParameterSetName -eq "byString")
	{
		Get-AzTableRow -Table $Table -ColumnName $ColumnName -value $Value -Operator $Operator -Top $Top
	}
	else
	{
		Get-AzTableRow -Table $Table -ColumnName $ColumnName -GuidValue $GuidValue -Operator $Operator -Top $Top
	}

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}
}

function Get-AzTableRowByCustomFilter
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on custom Filter.
	.DESCRIPTION
		Returns one or more rows/entities based on custom Filter. This custom Filter can be
		built using OData filter format or direct text.
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient to retrieve entities
	.PARAMETER CustomFilter
		Custom Filter string.
	.PARAMETER Top
		Return only the first n rows from the query
	.EXAMPLE
		# Getting row by firstname by using custom filter
	$MyFilter = "(firstName eq 'User1')"
		Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $MyFilter
	.EXAMPLE
		# Getting row by firstname by using text Filter directly (oData Filter format)
		Get-AzTableRowByCustomFilter -Table $Table -CustomFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"
	.EXAMPLE
		# Getting row by firstname by using text Filter directly with a maximum number of rows returned
		Get-AzTableRowByCustomFilter -Table $Table -CustomFilter "(firstName eq 'User1') and (lastName eq 'LastName1')" -Top 10
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$Table,

		[Parameter(Mandatory=$true)]
		[string]$CustomFilter,

		[Parameter(Mandatory=$false)]
		[Nullable[Int32]]$Top = $null
	)

	Write-Verbose $DeprecatedMessage -Verbose

	# Custom Filter

	$Result = Get-AzTableRow -Table $Table -CustomFilter $CustomFilter -Top $Top

	if (-not [string]::IsNullOrEmpty($Result))
	{
		return $Result
	}
}

function Get-AzTableRow
{
	<#
	.SYNOPSIS
		Used to return entities from a table with several options, this replaces all other Get-AzTable<XYZ> cmdlets.
	.DESCRIPTION
		Used to return entities from a table with several options, this replaces all other Get-AzTable<XYZ> cmdlets.
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient to retrieve entities (common to all parameter sets)
	.PARAMETER PartitionKey
		Identifies the table partition (byPartitionKey and byPartRowKeys parameter sets)
	.PARAMETER RowKey
		Identifies the row key in the partition (byPartRowKeys parameter set)
	.PARAMETER SelectColumn
		Names of the properties to return for each entity
	.PARAMETER ColumnName
		Column name to compare the value to (byColummnString and byColummnGuid parameter sets)
	.PARAMETER Value
		Value that will be looked for in the defined column (byColummnString parameter set)
	.PARAMETER GuidValue
		Value that will be looked for in the defined column as Guid (byColummnGuid parameter set)
	.PARAMETER Operator
		Supported comparison Operator. Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual" (byColummnString and byColummnGuid parameter sets)
	.PARAMETER CustomFilter
		Custom Filter string (byCustomFilter parameter set)
	.PARAMETER Top
		Return only the first n rows from the query (all parameter sets)
	.EXAMPLE
		# Getting all rows
		Get-AzTableRow -Table $Table
	.EXAMPLE
		# Getting specific properties for all rows
		$columns = ('osVersion', 'computerName')
		Get-AzTableRow -Table $Table -SelectColumn $columns
	.EXAMPLE
		# Getting rows by partition key
		Get-AzTableRow -Table $table -partitionKey NewYorkSite
	.EXAMPLE
		# Getting rows by partition and row key
		Get-AzTableRow -Table $table -partitionKey NewYorkSite -rowKey "afc04476-bda0-47ea-a9e9-7c739c633815"
	.EXAMPLE
		# Getting rows by Columnm Name using Guid columns in table
		Get-AzTableRow -Table $Table -ColumnName "id" -guidvalue "5fda3053-4444-4d23-b8c2-b26e946338b6" -operator Equal
	.EXAMPLE
		# Getting rows by Columnm Name using string columns in table
		Get-AzTableRow -Table $Table -ColumnName "osVersion" -value "Windows NT 4" -operator Equal
	.EXAMPLE
		# Getting rows using Custom Filter
		Get-AzTableRow -Table $Table -CustomFilter "(osVersion eq 'Windows NT 4') and (computerName eq 'COMP07')"
	.EXAMPLE
		# Querying with a maximum number of rows returned
		Get-AzTableRow -Table $Table -partitionKey NewYorkSite -Top 10
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

		[Parameter(ParameterSetName="GetAll")]
		[Parameter(ParameterSetName="byPartitionKey")]
		[Parameter(ParameterSetName="byPartRowKeys")]
		[Parameter(ParameterSetName="byColummnString")]
		[Parameter(ParameterSetName="byColummnGuid")]
		[Parameter(ParameterSetName="byCustomFilter")]
		[System.Collections.Generic.List[string]]$SelectColumn,

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
		[string]$CustomFilter,

		[Parameter(Mandatory=$false)]
		[Nullable[Int32]]$Top = $null
	)

	$OperatorMap = @{
		"Equal"              = "eq"
		"NotEqual"           = "ne"
		"GreaterThan"        = "gt"
		"GreaterThanOrEqual" = "ge"
		"LessThan"           = "lt"
		"LessThanOrEqual"    = "le"
	}

	# Building filters if any
	if ($PSCmdlet.ParameterSetName -eq "byPartitionKey")
	{
		[string]$Filter = "PartitionKey eq '$($PartitionKey.Replace("'", "''"))'"
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byPartRowKeys")
	{
		[string]$Filter = "(PartitionKey eq '$($PartitionKey.Replace("'", "''"))') and (RowKey eq '$($RowKey.Replace("'", "''"))')"
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byColummnString")
	{
		$op = $OperatorMap[$Operator]
		[string]$Filter = "$ColumnName $op '$($Value.Replace("'", "''"))'"
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byColummnGuid")
	{
		$op = $OperatorMap[$Operator]
		[string]$Filter = "$ColumnName $op guid'$GuidValue'"
	}
	elseif ($PSCmdlet.ParameterSetName -eq "byCustomFilter")
	{
		[string]$Filter = $CustomFilter
	}
	else
	{
		[string]$Filter = $null
	}

	# Getting results
	if ((-not [string]::IsNullOrEmpty($Filter)) -or ($PSCmdlet.ParameterSetName -eq "GetAll"))
	{
		$Result = ExecuteQueryAsync -Table $Table -Filter $Filter -SelectColumn $SelectColumn -Top $Top

		if ($null -ne $Result -and $Result.Count -gt 0)
		{
			return (GetPSObjectFromEntity($Result))
		}
	}
}
function Update-AzTableRow
{
	<#
	.SYNOPSIS
		Updates a table entity
	.DESCRIPTION
		Updates a table entity. To work with this cmdlet, you need first retrieve an entity with one of the Get-AzTableRow cmdlets available
		and store in an object, change the necessary properties and then perform the update passing this modified entity back, through Pipeline or as argument.
		Notice that this cmdlet accepts only one entity per execution.
		This cmdlet cannot update Partition Key and/or RowKey because it uses those two values to locate the entity to update it, if this operation is required
		please delete the old entity and add the new one with the updated values instead.
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient where the entity exists
	.PARAMETER Entity
		The entity/row with new values to perform the update.
	.EXAMPLE
		# Updating an entity

		[string]$Filter = "firstName eq 'User1'"
		$person = Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $Filter
		$person.lastName = "New Last Name"
		$person | Update-AzTableRow -Table $Table
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

	$updatedEntity = [Azure.Data.Tables.TableEntity]::new($entity.PartitionKey, $entity.RowKey)

	# Iterating over PS Object properties to add to the updated entity
	foreach ($prop in $entity.psobject.Properties)
	{
		if (($prop.name -ne "PartitionKey") -and ($prop.name -ne "RowKey") -and ($prop.name -ne "Timestamp") -and ($prop.name -ne "Etag") -and ($prop.name -ne "TableTimestamp") -and ($prop.name -ne "odata.etag"))
		{
			$updatedEntity[$prop.name] = $prop.Value
		}
	}

	if (-not [string]::IsNullOrEmpty($entity.Etag))
	{
		$updatedEntity.ETag = [Azure.ETag, Azure.Core]::new($entity.Etag)
	}

	return ($Table.UpsertEntity($updatedEntity, [Azure.Data.Tables.TableUpdateMode]::Merge, [System.Threading.CancellationToken]::None))
}

function Remove-AzTableRow
{
	<#
	.SYNOPSIS
		Remove-AzTableRow - Removes a specified table row
	.DESCRIPTION
		Remove-AzTableRow - Removes a specified table row. It accepts multiple deletions through the Pipeline when passing entities returned from the Get-AzTableRow
		available cmdlets. It also can delete a row/entity using Partition and Row Key properties directly.
	.PARAMETER Table
		Table object of type Azure.Data.Tables.TableClient where the entity exists
	.PARAMETER Entity (ParameterSetName=byEntityPSObjectObject)
		The entity/row with new values to perform the deletion.
	.PARAMETER PartitionKey (ParameterSetName=byPartitionandRowKeys)
		Partition key where the entity belongs to.
	.PARAMETER RowKey (ParameterSetName=byPartitionandRowKeys)
		Row key that uniquely identifies the entity within the partition.
	.EXAMPLE
		# Deleting an entry by entity PS Object
		[string]$Filter = "(firstName eq 'Paulo') and (lastName eq 'Marques')"
		$personToDelete = Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $Filter
		$personToDelete | Remove-AzTableRow -Table $Table
	.EXAMPLE
		# Deleting an entry by using PartitionKey and row key directly
		Remove-AzTableRow -Table $Table -PartitionKey "TableEntityDemoFullList" -RowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"
	.EXAMPLE
		# Deleting everything
		Get-AzTableRowAll -Table $Table | Remove-AzTableRow -Table $Table
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

		try
		{
			$Results += $Table.DeleteEntity($PartitionKey, $RowKey, [Azure.ETag, Azure.Core]::All, [System.Threading.CancellationToken]::None)
		}
		catch [Azure.RequestFailedException]
		{
			if ($_.Exception.Status -ne 404)
			{
				throw $_
			}
		}
	}

	end
	{
		return ,$Results
	}
}

# Aliases
New-Alias -Name Add-StorageTableRow -Value Add-AzTableRow -ErrorAction SilentlyContinue
New-Alias -Name Add-AzureStorageTableRow -Value Add-AzTableRow -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableTable -Value Get-AzTableTable -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableRowAll -Value Get-AzTableRowAll -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableRowByPartitionKey -Value Get-AzTableRowByPartitionKey -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableRowByPartitionKeyRowKey -Value Get-AzTableRowByPartitionKeyRowKey -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableRowByColumnName -Value Get-AzTableRowByColumnName -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableRowByCustomFilter -Value Get-AzTableRowByCustomFilter -ErrorAction SilentlyContinue
New-Alias -Name Get-AzureStorageTableRow -Value Get-AzTableRow -ErrorAction SilentlyContinue
New-Alias -Name Update-AzureStorageTableRow -Value Update-AzTableRow -ErrorAction SilentlyContinue
New-Alias -Name Remove-AzureStorageTableRow -Value Remove-AzTableRow -ErrorAction SilentlyContinue
