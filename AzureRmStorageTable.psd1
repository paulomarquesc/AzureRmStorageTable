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
Description = 'Sample functions to add/retrieve/update entities on Azure Storage Tables from PowerShell. It requires latest PowerShell Az module installed. Instructions at https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.6.0.'

# HelpInfo URI of this module
HelpInfoUri = 'https://paulomarquesc.github.io/working-with-azure-storage-tables-from-powershell/'

# Version number of this module
ModuleVersion = '2.0.2'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0'


RequiredModules = @(
    @{ModuleName="Az.Resources"; ModuleVersion="1.2.0"; GUID="48bb344d-4c24-441e-8ea0-589947784700"},
    @{ModuleName="Az.Storage"; ModuleVersion="1.1.0"; GUID="dfa9e4ea-1407-446d-9111-79122977ab20"}
)
# Script module or binary module file associated with this manifest
#ModuleToProcess = ''

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('AzureRmStorageTableCoreHelper.psm1')

FunctionsToExport = @(  'Add-AzTableRow',
                        'Get-AzTableRow',
                        'Get-AzTableRowAll',
                        'Get-AzTableRowByPartitionKeyRowKey',
                        'Get-AzTableRowByPartitionKey',
                        'Get-AzTableRowByColumnName',
                        'Get-AzTableRowByCustomFilter',
                        'Update-AzTableRow',
                        'Remove-AzTableRow',
                        'Get-AzTableTable'
                        )

VariablesToExport = ''

AliasesToExport = '*'
}
