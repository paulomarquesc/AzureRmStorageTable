Import-Module .\AzureRmStorageTable.psd1 -Force

$choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Y","&N")
$useEmulator = $Host.UI.PromptForChoice("Use local Azure Storage Emulator?", "", $choices, 0)
$useEmulator = $useEmulator -eq 0

$uniqueString = Get-Date -UFormat "PsTest%Y%m%dT%H%M%S"

Describe "AzureRmStorageTable" {
    BeforeAll {
        if ($useEmulator)
        {
            $context = New-AzureStorageContext -Local
        }
        else
        {
            $subscriptionName = Read-Host "Enter Azure Subscription name"                
            $locationName = Read-Host "Enter Azure Location name"

            Write-Host -for DarkGreen "Login to Azure"
            #Login-AzureRmAccount
            Select-AzureRmSubscription -SubscriptionName $subscriptionName

            Write-Host -for DarkGreen "Creating resource group $($uniqueString)"
            New-AzureRmResourceGroup -Name $uniqueString -Location $locationName

            # Write-Host -for DarkGreen "Creating storage account $($uniqueString.ToLower())"
            # New-AzureRmStorageAccount -ResourceGroupName $uniqueString -Name $uniqueString.ToLower() -Location $locationName -SkuName Standard_LRS

            # $storage = Get-AzureRmStorageAccount -ResourceGroupName $uniqueString -Name $uniqueString
            # $context = $storage.Context

            Write-Host -for DarkGreen "Creating Cosmos DB account $([string]::Format("cdb{0}",$uniqueString).ToLower())"
            $comosDbuniqueString = [string]::Format("cdb{0}",$uniqueString).ToLower()
            # $locations = @(@{"locationName"=$locationName; "failoverPriority"=0})
            # $CosmosDBProperties = @{"databaseAccountOfferType"="Standard"; "locations"=$locations}
            # New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion  -ResourceGroupName $uniqueString -location $locationName -Name $comosDbuniqueString -PropertyObject $CosmosDBProperties -Force

            $cosmosDbJsonTemplate = '{"resources":[{"name":"","type":Microsoft.DocumentDB/databaseAccounts","apiVersion":"2015-04-08","location":"","kind":"GlobalDocumentDB","properties":{"locations":[{"locationName":"","failoverPriority":0}],"databaseAccountOfferType":"Standard"}}]}'
            $cosmosDbObj = $cosmosDbJsonTemplate | ConvertFrom-Json
            $cosmosDbObj.resources.name = $comosDbuniqueString
            $cosmosDbObj.resources.name = $comosDbuniqueString

            Write-Host -for DarkGreen "Installing Cosmos Db Dependencies"
            .\Install-CosmosDbInstallPreReqs.ps1

            Write-Host -for DarkGreen "Loading Cosmos Db assemblies"

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

        }

        # Storage Table
        $tables = [System.Collections.ArrayList]@()
        $tableNames = @("$($uniqueString)insert", "$($uniqueString)delete")
        foreach ($tableName in $tableNames) {
            Write-Host -for DarkGreen "Creating Storage Table $($tableName)"
            $table = New-AzureStorageTable -Name $tableName -Context $context
            $tables.Add($table)
        }

        # if (-not $useEmulator)
        # {
        #     # Cosmos Db Tables
        #     $cdbTables = [System.Collections.ArrayList]@()
        #     $cdbTableNames = @("$($uniqueString)insert", "$($uniqueString)delete")
        #     foreach ($cdbTableName in $cdbTableNames) {
        #         Write-Host -for DarkGreen "Creating Comos Db table $($tableName)"
        #         $table = New-AzureStorageTable -Name $tableName -Context $context
        #         $tables.Add($table)
        #     }
        # }
    }

    # Context "Get-AzureStorageTableTable" {

        
    # }

    # Context "Add-StorageTableRow" {
    #     BeforeAll {
    #         $tableInsert = $tables | Where-Object -Property Name -EQ "$($uniqueString)insert"
    #     }

    #     It "Can add entity" {
    #         $expectedPK = "pk"
    #         $expectedRK = "rk"

    #         Add-StorageTableRow -table $tableInsert `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowAll -table $tableInsert

    #         $entity.PartitionKey | Should be $expectedPK
    #         $entity.RowKey | Should be $expectedRK
    #     }

    #     It "Can add entity with empty partition key" {
    #         $expectedPK = ""
    #         $expectedRK = "rk"

    #         Add-StorageTableRow -table $tableInsert `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowByPartitionKey -table $tableInsert `
    #             -partitionKey $expectedPK

    #         $entity.PartitionKey | Should be $expectedPK
    #         $entity.RowKey | Should be $expectedRK
    #     }

    #     It "Can add entity with empty row key" {
    #         $expectedPK = "pk"
    #         $expectedRK = ""

    #         Add-StorageTableRow -table $tableInsert `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowByColumnName -table $tableInsert `
    #             -columnName "RowKey" -value $expectedRK -operator Equal

    #         $entity.PartitionKey | Should be $expectedPK
    #         $entity.RowKey | Should be $expectedRK
    #     }

    #     It "Can add entity with empty partition and row keys" {
    #         $expectedPK = ""
    #         $expectedRK = ""

    #         Add-StorageTableRow -table $tableInsert `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowByCustomFilter -table $tableInsert `
    #             -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

    #         $entity.PartitionKey | Should be $expectedPK
    #         $entity.RowKey | Should be $expectedRK
    #     }
    # }

    # Context "Remove-AzureStorageTableRow" {
    #     BeforeAll {
    #         $tableDelete = $tables | Where-Object -Property Name -EQ "$($uniqueString)delete"
    #     }

    #     It "Can delete entity" {
    #         $expectedPK = "pk"
    #         $expectedRK = "rk"

    #         Add-StorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowAll -table $tableDelete

    #         $entity | Should Not Be $null

    #         Remove-AzureStorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK -rowKey $expectedRK

    #         $entity = Get-AzureStorageTableRowAll -table $tableDelete

    #         $entity | Should Be $null
    #     }

    #     It "Can delete entity with empty partition key" {
    #         $expectedPK = ""
    #         $expectedRK = "rk"

    #         Add-StorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowByPartitionKey -table $tableDelete `
    #             -partitionKey $expectedPK

    #         $entity | Should Not Be $null

    #         Remove-AzureStorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK -rowKey $expectedRK

    #         $entity = Get-AzureStorageTableRowByPartitionKey -table $tableDelete `
    #             -partitionKey $expectedPK

    #         $entity | Should Be $null
    #     }

    #     It "Can delete entity with empty row key" {
    #         $expectedPK = "pk"
    #         $expectedRK = ""

    #         Add-StorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowByColumnName -table $tableDelete `
    #             -columnName "RowKey" -value $expectedRK -operator Equal

    #         $entity | Should Not Be $null

    #         Remove-AzureStorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK -rowKey $expectedRK

    #         $entity = Get-AzureStorageTableRowByColumnName -table $tableDelete `
    #             -columnName "RowKey" -value $expectedRK -operator Equal

    #         $entity | Should Be $null
    #     }

    #     It "Can delete entity with empty partition and row keys" {
    #         $expectedPK = ""
    #         $expectedRK = ""

    #         Add-StorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK `
    #             -rowKey $expectedRK `
    #             -property @{}

    #         $entity = Get-AzureStorageTableRowByCustomFilter -table $tableDelete `
    #             -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

    #         $entity | Should Not Be $null

    #         Remove-AzureStorageTableRow -table $tableDelete `
    #             -partitionKey $expectedPK -rowKey $expectedRK

    #         $entity = Get-AzureStorageTableRowByCustomFilter -table $tableDelete `
    #             -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

    #         $entity | Should Be $null
    #     }
    # }

    AfterAll { 
        Write-Host -for DarkGreen "Cleanup in process"

        if ($useEmulator)
        {
            foreach ($tableName in $tableNames)
            {
                Remove-AzureStorageTable -Context $context -Name $tableName -Force
            }
        }
        else
        {
            Remove-AzureRmResourceGroup -Name $uniqueString -Force
        }

        Write-Host -for DarkGreen "Done"
    }
}