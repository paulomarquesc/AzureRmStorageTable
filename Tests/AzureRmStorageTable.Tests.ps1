[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false,ParameterSetName="AzureStorage")]
    [string]$Location="westus",

    [Parameter(Mandatory=$false,ParameterSetName="AzureStorage")]
    [string]$SubscriptionId
)

Import-Module .\AzTable.psd1 -Force

#$uniqueString = Get-Date -UFormat "PsTest%Y%m%dT%H%M%S"
$uniqueString = [string]::Format("s{0}{1}",("{0:X}" -f (([guid]::NewGuid()).Guid.ToString().GetHashCode())).ToLower(), (Get-Date -UFormat "%Y%m%dT%H%M%S").ToString().ToLower())
$resourceGroup = "$uniqueString-rg"

Describe "AzureRmStorageTable" {
    BeforeAll {
        $GetAzTableTableCmdtTableName = "TestTable"

        if ($PSCmdlet.ParameterSetName -ne "AzureStorage")
        {
            # Storage Emulator
            $context = Az.Storage\New-AzStorageContext -Local
        }
        else
        {
            # Storage Account
            Select-AzSubscription -SubscriptionId $SubscriptionId
            New-AzResourceGroup -Name $resourceGroup -Location $Location
            New-AzStorageAccount -Name $uniqueString -ResourceGroupName $resourceGroup -Location $Location -SkuName Standard_LRS -Kind StorageV2
            $context = (Get-AzStorageAccount -Name $uniqueString -ResourceGroupName $resourceGroup).Context
        }

        $GetTableCommand=@{$true = "-UseStorageEmulator"; $false = "-ResourceGroup `$resourceGroup -StorageAccountName `$uniqueString"}[($PSCmdlet.ParameterSetName -ne "AzureStorage")]

        $tables = [System.Collections.ArrayList]@()
        $tableNames = @("table$($uniqueString)insert", "table$($uniqueString)delete")
        foreach ($tableName in $tableNames)
        {
            Write-Host -for DarkGreen "   Creating Storage Table $($tableName)"
            $Table = Invoke-Expression("Get-AzTableTable -TableName `$tableName $GetTableCommand")

            Write-Host -for Green "      Created Table $($table | out-string)"
            $tables.Add($table)
        }
    }

    Context "Get-AzTableTable" {

        $GetTableCommand=@{$true = "-UseStorageEmulator"; $false = "-ResourceGroup `$resourceGroup -StorageAccountName `$uniqueString"}[($PSCmdlet.ParameterSetName -ne "AzureStorage")]

        It "Can create a new table" {
            $Table = Invoke-Expression("Get-AzTableTable -TableName `$GetAzTableTableCmdtTableName $GetTableCommand") 
            $Table | Should -Not -Be $null
        }

        It "Can open an existing table" {
            $Table = Invoke-Expression("Get-AzTableTable -TableName `$GetAzTableTableCmdtTableName $GetTableCommand") 
            $Table | Should -Not -Be $null
        }
    }

    Context "New-AzTableBatch" {
        It "Can create an empty batch operation" {
            $batch = New-AzTableBatch
            $batch.Count | Should -Be 0
        }

        It "Can create a pre populated batch operation" {
            $entity1 = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList "Partition1", "1"
            $entity1.Properties.Add("ExampleProperty", "myProp")
            $entity2 = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList "Partition1", "2"
            $entity2.Properties.Add("ExampleProperty", "myProp2")
            $operation1 = [Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity1)
            $operation2 = [Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity2)
            $batch = New-AzTableBatch -Operations @($operation1, $operation2)

            $batch.Count | Should -Be 2
        }
    }

    Context "Add-AzTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -eq "table$($uniqueString)insert"
        }

        It "Can add entity" {
            $entity = $null
            $expectedPK = [guid]::NewGuid().Guid
            $expectedRK = [guid]::NewGuid().Guid
      
            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert

            $entity.PartitionKey | Should -Be $expectedPK
            $entity.RowKey | Should -Be $expectedRK
        }

        It "Can add entity with empty partition key" {
            $entity = $null
            $expectedPK = ""
            $expectedRK = [guid]::NewGuid().Guid

            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert -partitionKey $expectedPK

            $entity.PartitionKey | Should -Be $expectedPK
            $entity.RowKey | Should -Be $expectedRK
        }

        It "Can add entity with empty row key" {
            $entity = $null
            $expectedPK = [guid]::NewGuid().Guid
            $expectedRK = ""

            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert -columnName "RowKey" -value $expectedRK -operator Equal

            $entity.PartitionKey | Should -Be $expectedPK
            $entity.RowKey | Should -Be $expectedRK
        }

        It "Can add entity with empty partition and row keys" {
            $entity = $null
            $expectedPK = ""
            $expectedRK = ""

            Add-AzTableRow -table $tableInsert -partitionKey $expectedPK -rowKey $expectedRK -property @{}

            $entity = Get-AzTableRow -table $tableInsert -customFilter "(PartitionKey eq '$($expectedPK)') and (RowKey eq '$($expectedRK)')"

            $entity.PartitionKey | Should -Be $expectedPK
            $entity.RowKey | Should -Be $expectedRK
        }

        It "Can add entity with properties" {
            $entity = $null
            $expectedProperty1Content = "COMP01"
            $expectedProperty2Content = "Windows 10"
            $PK = [guid]::NewGuid().Guid
            $RK = [guid]::NewGuid().Guid

            Add-AzTableRow -table $tableInsert -partitionKey $PK -rowKey $RK -property @{"computerName"=$expectedProperty1Content;"osVersion"=$expectedProperty2Content}

            $entity = Get-AzTableRow -table $tableInsert -customFilter "(PartitionKey eq '$($PK)') and (RowKey eq '$($RK)')"

            $entity.computerName | Should -Be $expectedProperty1Content
            $entity.osVersion | Should -Be $expectedProperty2Content
        }

        It "Can add multiple entities to a batch operation" {
            $batch = New-AzTableBatch
            $PK = [guid]::NewGuid().Guid

            $property1Content = "COMP01"
            $property2Content = "Linux"
            

            Add-AzTableRow -Batch $batch -RowKey ([guid]::NewGuid().tostring()) -PartitionKey $PK -Property @{ "computerName" = $property1Content; "osVersion" = $property2Content }
            Add-AzTableRow -Batch $batch -RowKey ([guid]::NewGuid().tostring()) -PartitionKey $PK -Property @{ "computerName" = $property1Content; "osVersion" = $property2Content }

            $batch.Count | Should -Be 2
        }
    }

    Context "Get-AzTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -EQ "table$($uniqueString)insert"
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
            $entityList.Count | Should -Be $expectedRowCount
        }

        It "Can it get specific columns for a specific row" {
            $entity = $null
            $expectedStringValue = "Windows 10"
            $entity = Get-AzTableRow -Table $tableInsert -partitionKey $partitionKey -rowKey $rowKey -SelectColumn @('osVersion', 'computerName')
            $entity.osVersion | Should -Be $expectedStringValue
            $entity.status | Should -Be $null
        }

        It "Can it get rows by partition key" {
            $entityList = $null
            $expectedRowCount = 4
            $entityList = Get-AzTableRow -table $tableInsert -partitionKey $partitionKey
            $entityList.Count | Should -Be $expectedRowCount
        }

        It "Can it get rows by partition key, limiting the number of results" {
            $entityList = $null
            $expectedRowCount = 2
            $entityList = Get-AzTableRow -table $tableInsert -partitionKey $partitionKey -Top 2
            $entityList.Count | Should -Be $expectedRowCount
        }

        It "Can it get row by partition and row key" {
            $entityList = $null
            $expectedRowCount = 1
            $entityList = @(Get-AzTableRow -table $tableInsert -partitionKey $partitionKey -RowKey $rowKey)
            $entityList.Count | Should -Be $expectedRowCount
        }

        It "Can it get row by column name using guid value" {
            $entity = $null
            $expectedGuidValue = [guid]::NewGuid()
            Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring())-property @{"computerName"="COMP05";"osVersion"="Windows 10";"status"="OK";"id"=$expectedGuidValue}

            $entity = Get-AzTableRow -Table $tableInsert -ColumnName "id" -guidvalue $expectedGuidValue -operator Equal
            $entity.id | Should -Be $expectedGuidValue
        }

        It "Can it get row by column name using string value" {
            $entity = $null
            $expectedStringValue = "COMP02"
            $entity = Get-AzTableRow -Table $tableInsert -ColumnName "computerName" -value $expectedStringValue -operator Equal
            $entity.computerName | Should -Be $expectedStringValue
        }

        It "Can it get row using custom filter" {
            $entityList = $null
            $expectedRowCount = 1
            $entityList = @(Get-AzTableRow -Table $tableInsert -CustomFilter "(osVersion eq 'Windows XP') and (computerName eq 'COMP04')")
            $entityList.Count | Should -Be $expectedRowCount
        }

        It "Can limit the number of results" {
            $entityList = $null
            $expectedRowCount = 5
            $entityList = Get-AzTableRow -table $tableInsert -Top 5
            $entityList.Count | Should -Be $expectedRowCount
        }

        It "Doesn't break when there are more rows than TakeCount" {
            $entityList = $null
            $expectedRowCount = 10
            $entityList = Get-AzTableRow -table $tableInsert -Top 86
            $entityList.Count | Should -Be $expectedRowCount
        }
    }

    Context "Remove-AzTableRow" {
        BeforeAll {
            $tableDelete = $tables | Where-Object -Property Name -eq "table$($uniqueString)delete"
        }

        It "Can delete entity" {
            $entity = $null
            $PK = [guid]::NewGuid().Guid
            $RK = [guid]::NewGuid().GUid

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete
            $entity | Should -Not -Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK 

            $entity = Get-AzTableRow -table $tableDelete
            $entity | Should -Be $null
        }

        It "Can delete entity with empty partition key" {
            $entity = $null
            $PK = ""
            $RK = [guid]::NewGuid().Guid

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete -partitionKey $expectedPK
            $entity | Should -Not -Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK

            $entity = Get-AzTableRow -table $tableDelete -partitionKey $PK
            $entity | Should -Be $null
        }

        It "Can delete entity with empty row key" {
            $entity = $null
            $PK = [guid]::NewGuid().Guid
            $RK = ""

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete -columnName "RowKey" -value $RK -operator Equal
            $entity | Should -Not -Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK

            $entity = Get-AzTableRow -table $tableDelete -columnName "RowKey" -value $RK -operator Equal

            $entity | Should -Be $null
        }

        It "Can delete entity with empty partition and row keys" {
            $entity = $null
            $PK = ""
            $RK = ""

            Add-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK -property @{}

            $entity = Get-AzTableRow -table $tableDelete -customFilter "(PartitionKey eq '$($PK)') and (RowKey eq '$($RK)')"
            $entity | Should -Not -Be $null

            Remove-AzTableRow -table $tableDelete -partitionKey $PK -rowKey $RK

            $entity = Get-AzTableRow -table $tableDelete -customFilter "(PartitionKey eq '$($PK)') and (RowKey eq '$($RK)')"
            $entity | Should -Be $null
        }
    }
    
    Context "Update-AzTableRow" {
        BeforeAll {
            $tableInsert = $tables | Where-Object -Property Name -eq "table$($uniqueString)insert"
        }

        It "Can it update an entity" {
            $expectedValue = "NeedsOsUpgrade"
            
            [string]$filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("computerName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"COMP03")
            $UpdateEntity = Get-AzTableRow -table $tableInsert -customFilter $filter
            $UpdateEntity.status | Should -Be $expectedValue

            # Changing values
            $UpdateEntity.osVersion = "Windows 10"
            $UpdateEntity.status = "OK"

            # Updating the content
            $UpdateEntity | Update-AzTableRow -table $tableInsert

            # Getting the entity again to check the changes
            $UpdateEntity = Get-AzTableRow -table $tableInsert -customFilter $filter
            $UpdateEntity.status | Should -Not -Be $expectedValue
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

        if ($PSCmdlet.ParameterSetName -eq "AzureStorage")
        {
            Remove-AzStorageAccount -Name $uniqueString -ResourceGroupName $resourceGroup -Force
            Remove-AzResourceGroup -Name $resourceGroup -Force
        }

        Write-Host -for DarkGreen "Done"
    }
}