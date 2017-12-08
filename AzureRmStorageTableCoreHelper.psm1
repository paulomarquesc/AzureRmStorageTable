
<#
.SYNOPSIS
	AzureRmStorageTableCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Table rows/entities.
.DESCRIPTION
  	AzureRmStorageTableCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Table rows/entities.
.NOTES
	Make sure the latest Azure PowerShell module is installed since we have a dependency on Microsoft.WindowsAzure.Storage.dll and 
    Microsoft.WindowsAzure.Commands.Common.Storage.dll.

	If running this module from Azure Automation, please make sure you check out this blog post for more information:
    https://blogs.technet.microsoft.com/paulomarques/2017/01/17/working-with-azure-storage-tables-from-powershell/
#>

#Requires -Modules AzureRM.Profile, AzureRM.Storage, AzureRM.Resources, Azure.Storage

# Module Functions

function GetLatestFullAssemblyName
{
	param
	(
		[string]$dllName
	)

	# getting list of all assemblies
	$assemblies = [appdomain]::currentdomain.getassemblies() | Where-Object {$_.location -like "*$dllName"}
	
	if ($assemblies -eq $null)
	{
		throw "Could not identify any assembly related to DLL named $dllName"
	}

	$sanitazedAssemblyList = @()
	foreach ($assembly in $assemblies)
	{
		[version]$version = $assembly.fullname.split(",")[1].split("=")[1]
		$sanitazedAssemblyList += New-Object -TypeName psobject -Property @{"version"=$version;"fullName"=$assembly.fullname}
	}

	return ($sanitazedAssemblyList | Sort-Object version -Descending)[0]
}

# Getting latest Microsoft.WindowsAzure.Storage.dll full Assembly name 
$assemblySN = (GetLatestFullAssemblyName -dllName Microsoft.WindowsAzure.Storage.dll).fullname

function Test-AzureStorageTableEmptyKeys
{
	[CmdletBinding()]
	param
	(
		[string]$partitionKey,
        [String]$rowKey
	)
    
    $cosmosDBEmptyKeysErrorMessage = "Cosmos DB table API does not accept empty partition or row keys when using CloudTable.Execute operation, because of this we are disabling this capability in this module and it will not proceed." 

    if ([string]::IsNullOrEmpty($partitionKey) -or [string]::IsNullOrEmpty($rowKey))
    {
        Throw $cosmosDBEmptyKeysErrorMessage
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
    .PARAMETER cosmosDbAccount
        CosmosDB account name where the table lives (this parameter was previously called databaseName, which is now an alias of this parameter)
	.EXAMPLE
		# Getting storage table object
		$resourceGroup = "myResourceGroup"
		$storageAccount = "myStorageAccountName"
		$tableName = "table01"
		$table = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -storageAccountName $storageAccount
	.EXAMPLE
		# Getting Cosmos DB table object
		$resourceGroup = "myResourceGroup"
		$databaseName = "myCosmosDbName"
		$tableName = "table01"
		$table01 = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -cosmosDbAccount $databaseName
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName="AzureRmTableStorage",Mandatory=$true)]
		[Parameter(ParameterSetName="AzureCosmosDb",Mandatory=$true)]
		[string]$resourceGroup,
		
		[Parameter(Mandatory=$true)]
        [String]$tableName,

		[Parameter(ParameterSetName="AzureRmTableStorage",Mandatory=$true)]
		[Parameter(ParameterSetName="AzureTableStorage",Mandatory=$true)]
        [String]$storageAccountName,

		[Parameter(ParameterSetName="AzureCosmosDb",Mandatory=$true)]
		[Alias("databaseName")]
        [String]$cosmosDbAccount

	)

    $nullTableErrorMessage = [string]::Empty

    switch ($PSCmdlet.ParameterSetName)
    {
        "AzureRmTableStorage"
            {
				$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName).Context	

                [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable]$table = Get-AzureStorageTable -Name $tableName -Context $saContext -ErrorAction SilentlyContinue

				if ($table -eq $null)
				{
					[Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable]$table = New-AzureStorageTable -Name $tableName -Context $saContext
				}

                $nullTableErrorMessage = "Table $tableName could not be retrieved from Storage Account $storageAccountName on resource group $resourceGroupName"
            }
        "AzureTableStorage"
            {
				$saContext = (Get-AzureStorageAccount -StorageAccountName $storageAccountName).Context

                [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable]$table = Get-AzureStorageTable -Name $tableName -Context $saContext -ErrorAction SilentlyContinue

				if ($table -eq $null)
				{
					[Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable]$table = New-AzureStorageTable -Name $tableName -Context $saContext
				}

                $nullTableErrorMessage = "Table $tableName could not be retrieved from Classic Storage Account $storageAccountName"

            }
        "AzureCosmosDb"
            {
				
                $requiredDlls = @("Microsoft.WindowsAzure.Storage.dll",
                                    "Microsoft.Data.Services.Client.dll",
                                    "Microsoft.Azure.Documents.Client.dll",
                                    "Newtonsoft.Json.dll",
                                    "Microsoft.Data.Edm.dll",
                                    "Microsoft.Data.OData.dll",
                                    "Microsoft.OData.Core.dll",
                                    "Microsoft.OData.Edm.dll",
                                    "Microsoft.Spatial.dll",
				                    "Microsoft.Azure.KeyVault.Core.dll",
                    				"System.Spatial.dll")

                foreach ($dll in $requiredDlls)
                {
                    [System.Reflection.Assembly]::LoadFile((Join-Path $PSScriptRoot $dll)) | Out-Null
                }

                $keys = Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroup -Name $cosmosDbAccount -Force

                if ($keys -eq $null)
                {
                    throw "Cosmos DB Database $cosmosDbAccount didn't return any keys."
                }

                $connString = [string]::Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};TableEndpoint=https://{0}.documents.azure.com",$cosmosDbAccount,$keys.primaryMasterKey)

                [Microsoft.WindowsAzure.Storage.CloudStorageAccount, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]$cosmosDbAcct = `
                    [Microsoft.WindowsAzure.Storage.CloudStorageAccount, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Parse($connString)                                                

                [Microsoft.WindowsAzure.Storage.Table.CloudTableClient, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]$tableClient = `
                    [Microsoft.WindowsAzure.Storage.Table.CloudTableClient, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]$cosmosDbAcct.CreateCloudTableClient()                                                                                   
                
                [Microsoft.WindowsAzure.Storage.Table.CloudTable, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]$table = `
                    [Microsoft.WindowsAzure.Storage.Table.CloudTable, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]$tableClient.GetTableReference($tableName)

				$table.CreateIfNotExists() | Out-Null
    
                $nullTableErrorMessage = "Table $tableName could not be retrieved from Cosmos DB database name $cosmosDbAccount on resource group $resourceGroupName"
            }
    }

    # Checking if there a table got returned
    if ($table -eq $null)
    {
        throw $nullTableErrorMessage
    }

    # Returns the table object
    if (($PSCmdlet.ParameterSetName -eq "AzureTableStorage") -or ($PSCmdlet.ParameterSetName -eq "AzureRmTableStorage"))
    {
        return [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable]$table
    }
    else
    {
        return [Microsoft.WindowsAzure.Storage.Table.CloudTable, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]$table
    }
}

function Add-StorageTableRow
{
	<#
	.SYNOPSIS
		Adds a row/entity to a specified table
	.DESCRIPTION
		Adds a row/entity to a specified table
	.PARAMETER Table
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity will be added
	.PARAMETER PartitionKey
		Identifies the table partition
	.PARAMETER RowKey
		Identifies a row within a partition
	.PARAMETER Property
		Hashtable with the columns that will be part of the entity. e.g. @{"firstName"="Paulo";"lastName"="Marques"}
	.EXAMPLE
		# Adding a row
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
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
        [hashtable]$property
	)
	
	# Creates the table entity with mandatory partitionKey and rowKey arguments
	if ($table.GetType().Name -eq "AzureStorageTable")
	{
		$entity = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity,$assemblySN" -ArgumentList $partitionKey, $rowKey
	}
	else
	{
        Test-AzureStorageTableEmptyKeys -partitionKey $partitionKey -rowKey $rowKey

		$entity = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ArgumentList $partitionKey, $rowKey
	}
    
    # Adding the additional columns to the table entity
	foreach ($prop in $property.Keys)
	{
		$entity.Properties.Add($prop, $property.Item($prop))
	}
    
    # Adding the dynamic table entity to the table
    if ($table.GetType().Name -eq "AzureStorageTable")
    {
       	return ($table.CloudTable.Execute((invoke-expression "[Microsoft.WindowsAzure.Storage.Table.TableOperation,$assemblySN]::insert(`$entity)")))
    }
    else
    {
        return ($table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Insert($entity)))
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
			$entity.Properties.Keys | % {Add-Member -InputObject $entityNewObj -Name $_ -Value $entity.Properties[$_].PropertyAsObject -MemberType NoteProperty}

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
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities
	.EXAMPLE
		# Getting all rows
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
		Get-AzureStorageTableRowAll -table $table
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$false)]
		[string[]]$columns
	)

	# No filtering
    if ($table.GetType().Name -eq "AzureStorageTable")
    {
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery,$assemblySN"
		if ($columns) {
			$list = New-Object System.Collections.Generic.List[string]
			foreach ($column in $columns) {
				$list.Add($column)
			}
			$tableQuery.SelectColumns = $list
		}
	    $result = $table.CloudTable.ExecuteQuery($tableQuery)
    }
    elseif ($table.GetType().Name -eq "CloudTable")
    {
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
		if ($columns) {
			$list = New-Object System.Collections.Generic.List[string]
			foreach ($column in $columns) {
				$list.Add($column)
			}
			$tableQuery.SelectColumns = $list
		}
  	    $result = $table.ExecuteQuery($tableQuery)
    }

	if (-not [string]::IsNullOrEmpty($result))
	{
		return (Get-PSObjectFromEntity -entityList $result)
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
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities
	.PARAMETER PartitionKey
		Identifies the table partition
	.EXAMPLE
		# Getting rows by partition Key
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
		Get-AzureStorageTableRowByPartitionKey -table $table -partitionKey $newPartitionKey
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true)]
		[AllowEmptyString()]
		[string]$partitionKey,

		[Parameter(Mandatory=$false)]
		[string[]]$columns
	)

	# Filtering by Partition Key

    if ($table.GetType().Name -eq "AzureStorageTable")
    {
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery,$assemblySN"

		[string]$filter = `
			[Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
			[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::Equal,$partitionKey)

		$tableQuery.FilterString = $filter

		if ($columns) {
			$list = New-Object System.Collections.Generic.List[string]
			foreach ($column in $columns) {
				$list.Add($column)
			}
			$tableQuery.SelectColumns = $list
		}

	    $result = $table.CloudTable.ExecuteQuery($tableQuery)
    }
    elseif ($table.GetType().Name -eq "CloudTable")
    {
        Test-AzureStorageTableEmptyKeys -partitionKey $partitionKey -rowKey "notapplicable"

		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
	
		[string]$filter = `
			[Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::GenerateFilterCondition("PartitionKey",`
			[Microsoft.WindowsAzure.Storage.Table.QueryComparisons, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Equal,$partitionKey)

		$tableQuery.FilterString = $filter

		if ($columns) {
			$list = New-Object System.Collections.Generic.List[string]
			foreach ($column in $columns) {
				$list.Add($column)
			}
			$tableQuery.SelectColumns = $list
		}

  	    $result = $table.ExecuteQuery($tableQuery)
    }

	if (-not [string]::IsNullOrEmpty($result))
	{
		return (Get-PSObjectFromEntity -entityList $result)
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
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities
	.PARAMETER ColumnName
		Column name to compare the value to
	.PARAMETER Value
		Value that will be looked for in the defined column
	.PARAMETER Operator
		Supported comparison operator. Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual"
	.EXAMPLE
		# Getting row by firstname
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
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

    if ($table.GetType().Name -eq "AzureStorageTable")
    {
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery,$assemblySN"

		if ($PSCmdlet.ParameterSetName -eq "byString") {
			[string]$filter = `
				[Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterCondition($columnName,[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::$operator,$value)
		}

		if ($PSCmdlet.ParameterSetName -eq "byGuid") {
			[string]$filter = `
				[Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterConditionForGuid($columnName,[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::$operator,$guidValue)
		}

		$tableQuery.FilterString = $filter

	    $result = $table.CloudTable.ExecuteQuery($tableQuery)
    }
    elseif ($table.GetType().Name -eq "CloudTable")
    {
        if ($columnName -eq "partitionKey")
        {
            Test-AzureStorageTableEmptyKeys -partitionKey $value -rowKey "notapplicable"
        }
        elseif ($columnName -eq "rowkey")
        {
            Test-AzureStorageTableEmptyKeys -partitionKey "notapplicable" -rowKey $value
        }
        
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"

		if ($PSCmdlet.ParameterSetName -eq "byString") {			
			[string]$filter = `
				[Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::GenerateFilterCondition($columnName,[Microsoft.WindowsAzure.Storage.Table.QueryComparisons, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::$operator,$value)
		}

		if ($PSCmdlet.ParameterSetName -eq "byGuid") {
			[string]$filter = `
				[Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterConditionForGuid($columnName,[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::$operator,$guidValue)
		}

		$tableQuery.FilterString = $filter
  	    $result = $table.ExecuteQuery($tableQuery)
    }

	if (-not [string]::IsNullOrEmpty($result))
	{
		return (Get-PSObjectFromEntity -entityList $result)
	}
}

function Get-AzureStorageTableRowByCustomFilter
{
	<#
	.SYNOPSIS
		Returns one or more rows/entities based on custom filter.
	.DESCRIPTION
		Returns one or more rows/entities based on custom filter. This custom filter can be
		built using the Microsoft.WindowsAzure.Storage.Table.TableQuery class or direct text.
	.PARAMETER Table
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable to retrieve entities
	.PARAMETER customFilter
		Custom filter string.
	.EXAMPLE
		# Getting row by firstname by using the class Microsoft.WindowsAzure.Storage.Table.TableQuery
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
		Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
	.EXAMPLE
		# Getting row by firstname by using text filter directly (oData filter format)
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext
		Get-AzureStorageTableRowByCustomFilter -table $table -customFilter "(firstName eq 'User1') and (lastName eq 'LastName1')"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$table,

		[Parameter(Mandatory=$true)]
		[string]$customFilter,

		[Parameter(Mandatory=$false)]
		[string[]]$columns
	)
	
	# Filtering by Partition Key

    if ($table.GetType().Name -eq "AzureStorageTable")
    {
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery,$assemblySN"

		$tableQuery.FilterString = $customFilter

		if ($columns) {
			$list = New-Object System.Collections.Generic.List[string]
			foreach ($column in $columns) {
				$list.Add($column)
			}
			$tableQuery.SelectColumns = $list
		}

	    $result = $table.CloudTable.ExecuteQuery($tableQuery)
    }
    elseif ($table.GetType().Name -eq "CloudTable")
    {
		$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"

		$tableQuery.FilterString = $customFilter

		if ($columns) {
			$list = New-Object System.Collections.Generic.List[string]
			foreach ($column in $columns) {
				$list.Add($column)
			}
			$tableQuery.SelectColumns = $list
		}

  	    $result = $table.ExecuteQuery($tableQuery)
    }

	if (-not [string]::IsNullOrEmpty($result))
	{
		return (Get-PSObjectFromEntity -entityList $result)
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
	.PARAMETER Table
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity exists
	.PARAMETER Entity
		The entity/row with new values to perform the update.
	.EXAMPLE
		# Updating an entity
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
		[string]$filter = [Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::Equal,"User1")
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

    if ($table.GetType().Name -eq "AzureStorageTable")
	{
		$updatedEntity = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity,$assemblySN" -ArgumentList $entity.PartitionKey, $entity.RowKey
	}
	elseif ($table.GetType().Name -eq "CloudTable")
	{
		$updatedEntity = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ArgumentList $entity.PartitionKey, $entity.RowKey
	}
	# Iterating over PS Object properties to add to the updated entity 
	foreach ($prop in $entity.psobject.Properties)
	{
		if (($prop.name -ne "PartitionKey") -and ($prop.name -ne "RowKey") -and ($prop.name -ne "Timestamp") -and ($prop.name -ne "Etag"))
		{
			$updatedEntity.Properties.Add($prop.name, $prop.Value)
		}
	}

	$updatedEntity.ETag = $entity.Etag

    # Updating the dynamic table entity to the table
    if ($table.GetType().Name -eq "AzureStorageTable")
    {
	    return ($table.CloudTable.Execute((invoke-expression "[Microsoft.WindowsAzure.Storage.Table.TableOperation,$assemblySN]::Replace(`$updatedEntity)")))
    }
    elseif ($table.GetType().Name -eq "CloudTable")
    {
    	return ($table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Replace($updatedEntity)))
    }
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
		Table object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable where the entity exists
	.PARAMETER Entity (ParameterSetName=byEntityPSObjectObject)
		The entity/row with new values to perform the deletion.
	.PARAMETER PartitionKey (ParameterSetName=byPartitionandRowKeys)
		Partition key where the entity belongs to.
	.PARAMETER RowKey (ParameterSetName=byPartitionandRowKeys)
		Row key that uniquely identifies the entity within the partition.		 
	.EXAMPLE
		# Deleting an entry by entity PS Object
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
		[string]$filter1 = [Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::Equal,"Paulo")
		[string]$filter2 = [Microsoft.WindowsAzure.Storage.Table.TableQuery]::GenerateFilterCondition("lastName",[Microsoft.WindowsAzure.Storage.Table.QueryComparisons]::Equal,"Marques")
		[string]$finalFilter = [Microsoft.WindowsAzure.Storage.Table.TableQuery]::CombineFilters($filter1,"and",$filter2)
		$personToDelete = Get-AzureStorageTableRowByCustomFilter -table $table -customFilter $finalFilter
		$personToDelete | Remove-AzureStorageTableRow -table $table
	.EXAMPLE
		# Deleting an entry by using partitionkey and row key directly
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
		Remove-AzureStorageTableRow -table $table -partitionKey "TableEntityDemoFullList" -rowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"
	.EXAMPLE
		# Deleting everything
		$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
		$table = Get-AzureStorageTable -Name $tableName -Context $saContext	
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

        if ($table.GetType().Name -eq "AzureStorageTable")
        {
			$entityToDelete = invoke-expression "[Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity,$assemblySN](`$table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation,$assemblySN]::Retrieve(`$partitionKey,`$rowKey))).Result"
        }
        elseif ($table.GetType().Name -eq "CloudTable")
        {
            Test-AzureStorageTableEmptyKeys -PartitionKey $partitionKey -RowKey $rowKey

      		$entityToDelete = [Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]($table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Retrieve($partitionKey,$rowKey))).Result
        }

		if ($entityToDelete -ne $null)
		{
            if ($table.GetType().Name -eq "AzureStorageTable")
            {
    			$results += $table.CloudTable.Execute((invoke-expression "[Microsoft.WindowsAzure.Storage.Table.TableOperation,$assemblySN]::Delete(`$entityToDelete)"))
            }
            elseif ($table.GetType().Name -eq "CloudTable")
            {
    			$results += $table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Delete($entityToDelete))
            }
		}
	}
	
	end
	{
		return ,$results
	}
}

# Aliases
New-Alias -Name Add-AzureStorageTableRow -Value Add-StorageTableRow
