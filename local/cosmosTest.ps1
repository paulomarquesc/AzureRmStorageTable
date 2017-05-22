
# Install NugetPS and run
# C:\github\azurermstoragetable> nuget install WindowsAzure.Storage-PremiumTable -Prerelease

#--------------------------
# Raw tests
[System.Reflection.Assembly]::LoadFile("C:\github\azurermstoragetable\WindowsAzure.Storage-PremiumTable.0.1.0-preview\lib\net45\Microsoft.WindowsAzure.Storage.dll")
[System.Reflection.Assembly]::LoadFile("C:\github\azurermstoragetable\Microsoft.Data.Services.Client.5.8.2\lib\net40\Microsoft.Data.Services.Client.dll")
[System.Reflection.Assembly]::LoadFile("C:\github\azurermstoragetable\Microsoft.Azure.DocumentDB.1.14.0\lib\net45\Microsoft.Azure.Documents.Client.dll")
[System.Reflection.Assembly]::LoadFile("C:\github\azurermstoragetable\Newtonsoft.Json.6.0.8\lib\net45\Newtonsoft.Json.dll")


$path = "C:\github\azurermstoragetable"

$requiredDlls = @(".\Microsoft.WindowsAzure.Storage.dll",
                    ".\Microsoft.Data.Services.Client.dll",
                    ".\Microsoft.Azure.Documents.Client.dll",
                    ".\Newtonsoft.Json.dll",
                    ".\Microsoft.Data.Edm.dll",
                    ".\Microsoft.Data.OData.dll",
                    ".\Microsoft.OData.Core.dll",
                    ".\Microsoft.OData.Edm.dll",
                    ".\Microsoft.Spatial.dll")
                
foreach ($dll in $requiredDlls)
{
    [System.Reflection.Assembly]::LoadFile((Join-Path $path $dll))
}

$connString = "DefaultEndpointsProtocol=https;AccountName=pmccosmos;AccountKey=AI8QpH9yINJGp6MtPeZgN9zwsvRr1ddbHv2ljqFyZGNRNuwAidk8Y6fXNUxNvikpb95pwPaVbnenwXOXFLQNiA==;TableEndpoint=https://pmccosmos.documents.azure.com"
$storage = [Microsoft.WindowsAzure.Storage.CloudStorageAccount,Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Parse($connString)                                                
$tableClient = $storage.CreateCloudTableClient()                                                                                   
$tableClient.ListTables()  

$table = $tableClient.GetTableReference("table01")

# Adding entity with empty string partition and row keys
$entity = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ArgumentList "", ""
$entity.Properties.Add("column1", "value1")
$entity.Properties.Add("column2", "value2")

$table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Insert($entity))

# Retrieving rows with partition and row keys empty
$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
$tableQuery.FilterString = "(PartitionKey eq '') and (RowKey eq '')"
$table.ExecuteQuery($tableQuery)

# Updating a row
$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
$tableQuery.FilterString = "(PartitionKey eq '') and (RowKey eq '')"
$result = $table.ExecuteQuery($tableQuery)
$currentEntity= @()
$currentEntity += $result[0]

$updatedEntity = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ArgumentList $currentEntity.PartitionKey, $currentEntity.RowKey
$updatedEntity.Properties.Add("column1", "new value1")
$updatedEntity.Properties.Add("column2", "new value2")
$updatedEntity.ETag = "*"

$table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Replace($updatedEntity))

# This operation fails
# Exception calling "Execute" with "1" argument(s): "The resource name can't end with space."
# At line:1 char:8
# + return ($table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOpe ...
# +        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
#     + FullyQualifiedErrorId : StorageException

# Deleting Rows
$partitionKey = ""
$rowKey = ""
$entityToDelete = [Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]($table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Retrieve($partitionKey,$rowKey))).Result
# This operation fails with the error message
# Exception calling "Execute" with "1" argument(s): "PartitionKey value must be supplied for this operation."
# At line:1 char:1
# + $entityToDelete = [Microsoft.WindowsAzure.Storage.Table.DynamicTableE ...
# + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
#     + FullyQualifiedErrorId : StorageException

$table.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Delete($entityToDelete))

# Second part

$tableQuery = New-Object -TypeName "Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"

[string]$partitionFilter = `
    [Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::GenerateFilterCondition("PartitionKey",`
    [Microsoft.WindowsAzure.Storage.Table.QueryComparisons, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Equal,$partitionKey)

[string]$rowFilter = `
    [Microsoft.WindowsAzure.Storage.Table.TableQuery, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::GenerateFilterCondition("RowKey",`
    [Microsoft.WindowsAzure.Storage.Table.QueryComparisons, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]::Equal,$rowkey)

$tableQuery.FilterString = [Microsoft.WindowsAzure.Storage.Table.TableQuery]::CombineFilters($partitionFilter,"and",$rowFilter)

$entityQueryResult = $table.ExecuteQuery($tableQuery)




#--------------------------

#----------------
# Cosmos DB table
#PS C:\github\azurermstoragetable> $table | fl
#
#ServiceClient : Microsoft.WindowsAzure.Storage.Table.CloudTableClient
#Name          : table01
#Uri           : https://pmccosmos.documents.azure.com/table01
#StorageUri    : Primary = 'https://pmccosmos.documents.azure.com/table01'; Secondary = ''
#PS C:\github\azurermstoragetable> $table | get-member
#TypeName: Microsoft.WindowsAzure.Storage.Table.CloudTable
#PS C:\github\azurermstoragetable> $table.GetType().name
#CloudTable
#-----------------

#------------------
# Regular table
#$resourceGroup = "identity-rg"
#$storageAccount = "oqjntwegylzz6sa1"
#$tableName = "table01"
#$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Context
#$table01 = Get-AzureStorageTable -Name $tableName -Context $saContext
#PS C:\github\azurermstoragetable> $table
#
#CloudTable Uri                                                     Context                                                     Name   
#---------- ---                                                     -------                                                     ----   
#table01    https://oqjntwegylzz6sa1.table.core.windows.net/table01 Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext table01

#PS C:\github\azurermstoragetable> $table | get-member
#TypeName: Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageTable
#PS C:\github\azurermstoragetable> $table01.GetType().name
#AzureStorageTable
#------------------
 
$partitionKey="123pmc"

#Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP01";"osVersion"="Windows 10";"status"="OK"}
#Invoke-AzureRmResourceAction -Action listConnectionStrings -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName "identity-rg" -Name "pmccosmos" -Force
#Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName "identity-rg" -Name "pmccosmos" -Force

#---------------------------------------------
# Getting storage table object

$resourceGroup = "pmcrg01"
$storageAccount = "oqjntwegylzz6sa1"
$tableName = "table01"
$table = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -storageAccountName $storageAccount

Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP01";"osVersion"="Windows 10";"status"="OK"}

#---------------------------------------------


#---------------------------------------------
# Getting cosmos db table
Remove-Module azurermstoragetable
cd C:\github\
cd .\azurermstoragetable\
Import-Module .\AzureRmStorageTable.psd1

$clearTextPassword =  ""
$password = ConvertTo-SecureString -String $clearTextPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("", $password)

add-azurermaccount -credential $creds

$resourceGroup = "pmcrg01"
$databaseName = "pmccosmos"
$tableName = "table01"

$table01 = Get-AzureStorageTabletable -resourceGroup $resourceGroup -tableName $tableName -databaseName $databaseName

$compName = [DateTime]::Now.Ticks.ToString("x")
Add-StorageTableRow -table $table01 -partitionKey "partition1" -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"=$compName;"osVersion"="Windows 10";"status"="OK"}


#Add-StorageTableRow -table $table01 -partitionKey "" -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"=[DateTime]::Now.Ticks.ToString("x");"osVersion"="Windows 10";"status"="OK"} -ErrorAction Continue

Add-StorageTableRow -table $table01 -partitionKey "partition1" -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"=[DateTime]::Now.Ticks.ToString("x");"osVersion"="Windows 10";"status"="OK"}

Write-Verbose "Getting all rows" -verbose
Get-AzureStorageTableRowAll -table $table01 | ft

Write-Verbose "Getting all rows by partition key" -verbose
Get-AzureStorageTableRowByPartitionKey -table $table01 -partitionKey "partition1" | ft

#Get-AzureStorageTableRowByPartitionKey -table $table01 -partitionKey "" -ErrorAction Continue | ft

Write-Verbose "Getting all rows by column" -verbose
Get-AzureStorageTableRowByColumnName -table $table01 -columnName "computerName" -value $compName -operator Equal | ft
#Get-AzureStorageTableRowByColumnName -table $table01 -columnName "partititionkey" -value "" -operator Equal -ErrorAction Continue | ft
#Get-AzureStorageTableRowByColumnName -table $table01 -columnName "rowkey" -value "" -operator Equal -ErrorAction Continue | ft

Write-Verbose "Getting all rows by custom filter" -verbose
Get-AzureStorageTableRowByCustomFilter -table $table01 -customFilter "(computerName eq '$compName') and (osVersion eq 'Windows 10')"

Write-Verbose "Updating entity" -verbose
$comp = Get-AzureStorageTableRowByCustomFilter -table $table01 -customFilter "(computerName eq '$compName') and (osVersion eq 'Windows 10')"
$comp.osVersion = "Windows Server 2016"
$comp | Update-AzureStorageTableRow -table $table01
Get-AzureStorageTableRowByColumnName -table $table01 -columnName "computerName" -value $compName -operator Equal

Write-Verbose "Deleting one entity"
Get-AzureStorageTableRowByColumnName -table $table01 -columnName "computerName" -value $compName -operator Equal | Remove-AzureStorageTableRow -table $table01

Write-Verbose "Deleting all entities"
Get-AzureStorageTableRowAll -table $table01 | Remove-AzureStorageTableRow -table $table01

#---------------------------------------------

[system.reflection.assembly]::GetAssembly("Microsoft.WindowsAzure.Storage.Table.CloudTable, Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35") | fl

#CodeBase               : file:///C:/github/azurermstoragetable/WindowsAzure.Storage-PremiumTable.0.1.0-preview/lib/net45/Microsoft.WindowsAzure.Storage.dll
#EntryPoint             : 
#EscapedCodeBase        : file:///C:/github/azurermstoragetable/WindowsAzure.Storage-PremiumTable.0.1.0-preview/lib/net45/Microsoft.WindowsAzure.Storage.dll
#FullName               : Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
#GlobalAssemblyCache    : False
#HostContext            : 0
#ImageFileMachine       : 
#ImageRuntimeVersion    : v4.0.30319
#Location               : C:\github\azurermstoragetable\WindowsAzure.Storage-PremiumTable.0.1.0-preview\lib\net45\Microsoft.WindowsAzure.Storage.dll
#ManifestModule         : Microsoft.WindowsAzure.Storage.dll
#MetadataToken          : 
#PortableExecutableKind : 
#ReflectionOnly         : False

[system.reflection.assembly]::GetAssembly("Microsoft.WindowsAzure.Storage.Table.CloudTableClient") | fl

#CodeBase               : file:///C:/Program Files (x86)/Microsoft SDKs/Azure/PowerShell/Storage/Azure.Storage/Microsoft.WindowsAzure.Storage.DLL
#EntryPoint             : 
#EscapedCodeBase        : file:///C:/Program%20Files%20(x86)/Microsoft%20SDKs/Azure/PowerShell/Storage/Azure.Storage/Microsoft.WindowsAzure.Storage.DLL
#FullName               : Microsoft.WindowsAzure.Storage, Version=8.1.1.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
#GlobalAssemblyCache    : False
#HostContext            : 0
#ImageFileMachine       : 
#ImageRuntimeVersion    : v4.0.30319
#Location               : C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\Storage\Azure.Storage\Microsoft.WindowsAzure.Storage.dll
#ManifestModule         : Microsoft.WindowsAzure.Storage.dll
#MetadataToken          : 
#PortableExecutableKind : 
#ReflectionOnly         : False


#CodeBase               : file:///C:/github/azurermstoragetable/WindowsAzure.Storage-PremiumTable.0.1.0-preview/lib/net45/Microsoft.WindowsAzure.Storage.dll
#EntryPoint             : 
#EscapedCodeBase        : file:///C:/github/azurermstoragetable/WindowsAzure.Storage-PremiumTable.0.1.0-preview/lib/net45/Microsoft.WindowsAzure.Storage.dll
#FullName               : Microsoft.WindowsAzure.Storage, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
#GlobalAssemblyCache    : False
#HostContext            : 0
#ImageFileMachine       : 
#ImageRuntimeVersion    : v4.0.30319
#Location               : C:\github\azurermstoragetable\WindowsAzure.Storage-PremiumTable.0.1.0-preview\lib\net45\Microsoft.WindowsAzure.Storage.dll
#ManifestModule         : Microsoft.WindowsAzure.Storage.dll
#MetadataToken          : 
#PortableExecutableKind : 
#ReflectionOnly         : False
