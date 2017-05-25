# Release Notes

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