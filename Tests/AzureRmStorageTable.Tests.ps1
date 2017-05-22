Import-Module .\AzureRmStorageTable.psd1 -Force

$choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Y","&N")
$useEmulator = $Host.UI.PromptForChoice("Use local Azure Storage Emulator?", "", $choices, 0)
$useEmulator = $useEmulator -eq 0

$uniqueString = Get-Date -UFormat "PsTest%Y%m%dT%H%M%S"

Describe "AzureRmStorageTable" {
    BeforeAll {
        if ($useEmulator) {
            $context = New-AzureStorageContext -Local
        } else {
            $subscriptionName = Read-Host "Enter Azure Subscription name"                
            $locationName = Read-Host "Enter Azure Location name"

            Write-Host -for DarkGreen "Login to Azure"
            Login-AzureRmAccount
            Select-AzureRmSubscription -SubscriptionName $subscriptionName

            Write-Host -for DarkGreen "Creating resource group $($uniqueString)"
            New-AzureRmResourceGroup -Name $uniqueString -Location $locationName

            Write-Host -for DarkGreen "Creating storage account $($uniqueString.ToLower())"
            New-AzureRmStorageAccount -ResourceGroupName $uniqueString -Name $uniqueString.ToLower() -Location $locationName -SkuName Standard_LRS

            $storage = Get-AzureRmStorageAccount -ResourceGroupName $uniqueString -Name $uniqueString
            $context = $storage.Context
        }

        $tables = [System.Collections.ArrayList]@()
        $tableNames = @("$($uniqueString)insert", "$($uniqueString)delete")
        foreach ($tableName in $tableNames) {
            Write-Host -for DarkGreen "Creating table $($tableName)"
            $table = New-AzureStorageTable -Name $tableName -Context $context
            $tables.Add($table)
        }
    }

    Context "Add-StorageTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -EQ "$($uniqueString)insert"
        }

        It "Can add entity" {
            $expectedPK = "pk"
            $expectedRK = "rk"

            Add-StorageTableRow -table $tableInsert `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowAll -table $tableInsert

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with empty partition key" {
            $expectedPK = ""
            $expectedRK = "rk"

            Add-StorageTableRow -table $tableInsert `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowByPartitionKey -table $tableInsert `
                -partitionKey $expectedPK

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with empty row key" {
            $expectedPK = "pk"
            $expectedRK = ""

            Add-StorageTableRow -table $tableInsert `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowByColumnName -table $tableInsert `
                -columnName "RowKey" -value $expectedRK -operator Equal

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with empty partition and row keys" {
            $expectedPK = ""
            $expectedRK = ""

            Add-StorageTableRow -table $tableInsert `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowByCustomFilter -table $tableInsert `
                -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }
    }

    Context "Remove-AzureStorageTableRow" {
        BeforeAll {
            $tableDelete = $tables | Where-Object -Property Name -EQ "$($uniqueString)delete"
        }

        It "Can delete entity" {
            $expectedPK = "pk"
            $expectedRK = "rk"

            Add-StorageTableRow -table $tableDelete `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowAll -table $tableDelete

            $entity | Should Not Be $null

            Remove-AzureStorageTableRow -table $tableDelete `
                -partitionKey $expectedPK -rowKey $expectedRK

            $entity = Get-AzureStorageTableRowAll -table $tableDelete

            $entity | Should Be $null
        }

        It "Can delete entity with empty partition key" {
            $expectedPK = ""
            $expectedRK = "rk"

            Add-StorageTableRow -table $tableDelete `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowByPartitionKey -table $tableDelete `
                -partitionKey $expectedPK

            $entity | Should Not Be $null

            Remove-AzureStorageTableRow -table $tableDelete `
                -partitionKey $expectedPK -rowKey $expectedRK

            $entity = Get-AzureStorageTableRowByPartitionKey -table $tableDelete `
                -partitionKey $expectedPK

            $entity | Should Be $null
        }

        It "Can delete entity with empty row key" {
            $expectedPK = "pk"
            $expectedRK = ""

            Add-StorageTableRow -table $tableDelete `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowByColumnName -table $tableDelete `
                -columnName "RowKey" -value $expectedRK -operator Equal

            $entity | Should Not Be $null

            Remove-AzureStorageTableRow -table $tableDelete `
                -partitionKey $expectedPK -rowKey $expectedRK

            $entity = Get-AzureStorageTableRowByColumnName -table $tableDelete `
                -columnName "RowKey" -value $expectedRK -operator Equal

            $entity | Should Be $null
        }

        It "Can delete entity with empty partition and row keys" {
            $expectedPK = ""
            $expectedRK = ""

            Add-StorageTableRow -table $tableDelete `
                -partitionKey $expectedPK `
                -rowKey $expectedRK `
                -property @{}

            $entity = Get-AzureStorageTableRowByCustomFilter -table $tableDelete `
                -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

            $entity | Should Not Be $null

            Remove-AzureStorageTableRow -table $tableDelete `
                -partitionKey $expectedPK -rowKey $expectedRK

            $entity = Get-AzureStorageTableRowByCustomFilter -table $tableDelete `
                -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

            $entity | Should Be $null
        }
    }

    AfterAll { 
        Write-Host -for DarkGreen "Cleanup in process"

        if ($useEmulator) {
            foreach ($tableName in $tableNames) {
                Remove-AzureStorageTable -Context $context -Name $tableName -Force
            }
        } else {
            Remove-AzureRmResourceGroup -Name $uniqueString -Force
        }

        Write-Host -for DarkGreen "Done"
    }
}