Import-Module .\AzureRmStorageTable.psd1 -Force

#$choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Y","&N")
#$useEmulator = $Host.UI.PromptForChoice("Use local Azure Storage Emulator?", "", $choices, 0)
#$useEmulator = $useEmulator -eq 0

$uniqueString = Get-Date -UFormat "PsTest%Y%m%dT%H%M%S"

$GetAzTableTableCmdtTableName = "TestTable"

Describe "AzureRmStorageTable" {
    BeforeAll {
        $context = Az.Storage\New-AzStorageContext -Local

        # Storage Table
        $tables = [System.Collections.ArrayList]@()
        $tableNames = @("$($uniqueString)insert", "$($uniqueString)delete")
        foreach ($tableName in $tableNames) {
            Write-Host -for DarkGreen "   Creating Storage Table $($tableName)"
            $Table = Get-AzTableTable -table $tableName -UseStorageEmulator
            $tables.Add($table)
        }
    }

    Context "Get-AzTableTable" {

        It "Can create a new table" {
            Get-AzTableTable -table $GetAzTableTableCmdtTableName -UseStorageEmulator
        }

        It "Can open an existing table" {
            Get-AzTableTable -table $GetAzTableTableCmdtTableName -UseStorageEmulator
        }
    }

    Context "Add-AzTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -EQ "$($uniqueString)insert"
        }

        It "Can add entity" {
            $entity = $null
            $expectedPK = [guid]::NewGuid().Guid
            $expectedRK = [guid]::NewGuid().Guid
         
            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with empty partition key" {
            $entity = $null
            $expectedPK = ""
            $expectedRK = [guid]::NewGuid().Guid

            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert -partitionKey $expectedPK

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with empty row key" {
            $entity = $null
            $expectedPK = [guid]::NewGuid().Guid
            $expectedRK = ""

            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert -columnName "RowKey" -value $expectedRK -operator Equal

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with empty partition and row keys" {
            $entity = $null
            $expectedPK = ""
            $expectedRK = ""

            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

            $entity.PartitionKey | Should be $expectedPK
            $entity.RowKey | Should be $expectedRK
        }

        It "Can add entity with properties" {
            $entity = $null
            $expectedProperty1Content = "COMP01"
            $expectedProperty2Content = "Windows 10"
            $PK = [guid]::NewGuid().Guid
            $RK = [guid]::NewGuid().Guid

            Add-AzTableRow -table $tableInsert -partitionKey $PK -rowKey $RK -property @{"computerName"=$expectedProperty1Content;"osVersion"=$expectedProperty2Content}

            $entity = Get-AzTableRow -table $tableInsert -customFilter "(PartitionKey eq '$($PK)') and (RowKey eq '$($RK)')"

            $entity.computerName | Should be $expectedProperty1Content
            $entity.osVersion | Should be $expectedProperty2Content
        }
    }

    Context "Get-AzTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -EQ "$($uniqueString)insert"
            $partitionKey = [guid]::NewGuid().tostring()
            $rowKey = [guid]::NewGuid().tostring()

            Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey $rowKey -property @{"computerName"="COMP01";"osVersion"="Windows 10";"status"="OK"}
            Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP02";"osVersion"="Windows 8.1";"status"="NeedsOsUpgrade"}
            Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP03";"osVersion"="Windows 8.1";"status"="NeedsOsUpgrade"}
            Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP04";"osVersion"="Windows XP";"status"="NeedsOsUpgrade"}
        }

        It "Can it get all rows" {
            $entityList = $null
            $expectedRowCount = 9
            $entityList = Get-AzTableRow -table $tableInsert
            $entityList.Count | Should be $expectedRowCount
        }

        It "Can it get rows by partition key" {
            $entityList = $null
            $expectedRowCount = 4
            $entityList = Get-AzTableRow -table $tableInsert -partitionKey $partitionKey
            $entityList.Count | Should be $expectedRowCount
        }

        It "Can it get row by partition and row key" {
            $entityList = $null
            $expectedRowCount = 1
            $entityList = @(Get-AzTableRow -table $tableInsert -partitionKey $partitionKey -RowKey $rowKey)
            $entityList.Count | Should be $expectedRowCount
        }

        It "Can it get row by column name using guid value" {
            $entity = $null
            $expectedGuidValue = [guid]::NewGuid()
            Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring())-property @{"computerName"="COMP05";"osVersion"="Windows 10";"status"="OK";"id"=$expectedGuidValue}

            $entity = Get-AzTableRow -Table $tableInsert -ColumnName "id" -guidvalue $expectedGuidValue -operator Equal
            $entity.id | Should be $expectedGuidValue
        }

        It "Can it get row by column name using string value" {
            $entity = $null
            $expectedStringValue = "COMP02"
            $entity = Get-AzTableRow -Table $tableInsert -ColumnName "computerName" -value $expectedStringValue -operator Equal
            $entity.computerName | Should be $expectedStringValue
        }

        It "Can it get row using custom filter" {
            $entityList = $null
            $expectedRowCount = 1
            $entityList = @(Get-AzTableRow -Table $tableInsert -CustomFilter "(osVersion eq 'Windows XP') and (computerName eq 'COMP04')")
            $entityList.Count | Should be $expectedRowCount
        }
    }

    Context "Remove-AzTableRow" {
        BeforeAll {
            $tableDelete = $tables | Where-Object -Property Name -EQ "$($uniqueString)delete"
        }

        It "Can delete entity" {
            $entity = $null
            $PK = [guid]::NewGuid().Guid
            $RK = [guid]::NewGuid().GUid

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete
            $entity | Should Not Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK 

            $entity = Get-AzTableRow -table $tableDelete
            $entity | Should Be $null
        }

        It "Can delete entity with empty partition key" {
            $entity = $null
            $PK = ""
            $RK = [guid]::NewGuid().Guid

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete -partitionKey $expectedPK
            $entity | Should Not Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK

            $entity = Get-AzTableRow -table $tableDelete -partitionKey $PK
            $entity | Should Be $null
        }

        It "Can delete entity with empty row key" {
            $entity = $null
            $PK = [guid]::NewGuid().Guid
            $RK = ""

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete -columnName "RowKey" -value $RK -operator Equal
            $entity | Should Not Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK

            $entity = Get-AzTableRow -table $tableDelete -columnName "RowKey" -value $RK -operator Equal

            $entity | Should Be $null
        }

        It "Can delete entity with empty partition and row keys" {
            $entity = $null
            $PK = ""
            $RK = ""

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete -customFilter "(PartitionKey eq '$($PK)') and (RowKey eq '$($RK)')"
            $entity | Should Not Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK

            $entity = Get-AzTableRow -table $tableDelete -customFilter "(PartitionKey eq '$($PK)') and (RowKey eq '$($RK)')"
            $entity | Should Be $null
        }
    }
    
    Context "Update-AzTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -EQ "$($uniqueString)insert"
        }

        It "Can it update an entity" {
            $expectedValue = "NeedsOsUpgrade"
            
            [string]$filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("computerName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"COMP03")
            $UpdateEntity = Get-AzTableRow -table $tableInsert -customFilter $filter
            $UpdateEntity.status | Should Be $expectedValue

            # Changing values
            $UpdateEntity.osVersion = "Windows 10"
            $UpdateEntity.status = "OK"

            # Updating the content
            $UpdateEntity | Update-AzTableRow -table $tableInsert

            # Getting the entity again to check the changes
            $UpdateEntity = Get-AzTableRow -table $tableInsert -customFilter $filter
            $UpdateEntity.status | Should Not Be $expectedValue
        }
    }

    AfterAll { 
        Write-Host -for DarkGreen "Cleanup in process"

        # Removing Get-AzTableTable test table
        Remove-AzStorageTable $GetAzTableTableCmdtTableName -Context $context -Force

        foreach ($tableName in $tableNames)
        {
            Remove-AzStorageTable -Context $context -Name $tableName -Force
        }

        Write-Host -for DarkGreen "Done"
    }
}