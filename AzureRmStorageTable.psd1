@{

# ID used to uniquely identify this module
GUID = '8a32725b-b220-42a5-89d4-17646534dba9'

# Author of this module
Author = 'Paulo Marques (MSFT)'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '© Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Sample functions to add/retrieve/update entities on Azure Storage Tables from PowerShell. It requires latest Azure PowerShell module installed, which can be downloaded from http://aka.ms/webpi-azps.'

# HelpInfo URI of this module
HelpInfoUri = 'https://blogs.technet.microsoft.com/paulomarques/2017/01/17/working-with-azure-storage-tables-from-powershell/'

# Version number of this module
ModuleVersion = '1.0.0.23'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0'

# Script module or binary module file associated with this manifest
#ModuleToProcess = ''

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('AzureRmStorageTableCoreHelper.psm1')

FunctionsToExport = @(  'Add-StorageTableRow',
                        'Get-AzureStorageTableRowAll',
                        'Get-AzureStorageTableRowByPartitionKey',
                        'Get-AzureStorageTableRowByColumnName',
                        'Get-AzureStorageTableRowByCustomFilter',
                        'Update-AzureStorageTableRow',
                        'Remove-AzureStorageTableRow',
                        'Get-AzureStorageTableTable'
                        )

VariablesToExport = ''

}
