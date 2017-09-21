# Release Notes

## Version 1.0.0.17
* Fixed a bug with Get-AzureStorageTableTable function where it was returning two objects a boolean and the cloudtable when using Cosmos DB.

## Version 1.0.0.16
* Fixed an issue with the parameter set for the Cosmos DB, it was missing the resource group parameter on it and therefore causing an error saying that the parameterset could not be identified.

## Version 1.0.0.15
* Included etag on returned PSObject entities
* Removed extra query to the table when updating an entity in order to be able to make optimistic locking work (it will trigger error 412 if someone else changed the entity), for locking mechanism, please refer to https://azure.microsoft.com/en-us/blog/managing-concurrency-in-microsoft-azure-storage-2/

## Version 1.0.0.11
* Fixed issue with Add-AzureStorageTableRow cmdlet related to a reference to inexisting object.

## Version 1.0.0.10
* Included new cmdlet called Get-AzureStorageTableTable.
* Included preview support for Azure Cosmos DB Table API.
* Created a script called Install-CosmosDbInstallPreReqs.ps1 that adds the necessary assemblies for Cosmos DB.

### Version 1.0.0.9
* Allowed empty strings on Partition and Row keys.
* Included Pester test cases script.

### Version 1.0.0.8
* Returned entities as PS Objects now include a Timestamp attribute.

### Previous versions
* General bug fixes.
* Inclusion of #Requires statement for required modules.
* Initial publication of the module.