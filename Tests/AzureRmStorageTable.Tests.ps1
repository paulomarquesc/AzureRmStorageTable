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

$GetAzTableTableCmdtTableName = "TestTable"

Describe "AzureRmStorageTable" {
    BeforeAll {
        if ($PSCmdlet.ParameterSetName -ne "AzureStorage")
        {
            # Storage Emulator
            $context = Az.Storage\New-AzStorageContext -Local
        }
        else
        {
            Select-AzSubscription -SubscriptionId $SubscriptionId
            New-AzResourceGroup -Name $resourceGroup -Location $Location
            
            # Storage Account            
            New-AzStorageAccount -Name $uniqueString -ResourceGroupName $resourceGroup -Location $Location -SkuName Standard_LRS -Kind StorageV2
            $context = (Get-AzStorageAccount -Name $uniqueString -ResourceGroupName $resourceGroup).Context
            
            # CosmosDB Account
            $apiVersion = "2015-04-08"
            $accountProperties = @{
                "databaseAccountOfferType"="Standard";
                "capabilities"= @( @{ "name"="EnableTable" } ) 
            }

            New-AzResource -ResourceType "Microsoft.DocumentDB/databaseAccounts" `
                -ApiVersion $apiVersion `
                -ResourceGroupName $resourceGroup `
                -Location $Location `
                -Name $uniqueString `
                -PropertyObject $accountProperties `
                -Force
        }
        
        # Preparing tables for inserts, deletes and updates
        $GetTableCommand=@{$true = "-UseStorageEmulator"; $false = "-ResourceGroup `$resourceGroup -StorageAccountName `$uniqueString"}[($PSCmdlet.ParameterSetName -ne "AzureStorage")]

        $GetCosmosDbTableCommand=@{$true = "-UseStorageEmulator"; $false = "-ResourceGroup `$resourceGroup -CosmosDbAccountName `$uniqueString"}[($PSCmdlet.ParameterSetName -ne "AzureStorage")]
        
        $tables = [System.Collections.ArrayList]@()
        $tableNames = @("table$($uniqueString)insert", "table$($uniqueString)delete")
        foreach ($tableName in $tableNames)
        {
            #Storage Test
            Write-Host -for DarkGreen "   Creating Storage Table $($tableName)"
            $Table = Invoke-Expression("Get-AzTableTable -table `$tableName $GetTableCommand")
            Write-Host -for Green "      Created Table $($table | out-string)"
            $tables.Add($table)
            
            #CosmosDB Test
            Write-Host -for DarkGreen "   Creating CosmosDB Table $($tableName)"
            $cosmosTable = Invoke-Expression("Get-AzTableTable -table `"`cosmos$tableName`" $GetCosmosDbTableCommand")
            Write-Host -for Green "      Created CosmosDB Table $($table | out-string)"
            $tables.Add($cosmosTable)
        }
    }

    Context "Get-AzTableTable" {

        #Azure storage create and open a table
        $GetTableCommand=@{$true = "-UseStorageEmulator"; $false = "-ResourceGroup `$resourceGroup -StorageAccountName `$uniqueString"}[($PSCmdlet.ParameterSetName -ne "AzureStorage")]
        
        It "Can create a new table(Storage account)" {
            $Table = Invoke-Expression("Get-AzTableTable -table `$GetAzTableTableCmdtTableName $GetTableCommand") 
            $Table | Should not be $null
        }

        It "Can open an existing table (Storage account)" {
            $Table = Invoke-Expression("Get-AzTableTable -table `$GetAzTableTableCmdtTableName $GetTableCommand") 
            $Table | Should not be $null
        }
        
        # CosmosDB create and open a table
        $GetCosmosDbTableCommand=@{$true = "-UseStorageEmulator"; $false = "-ResourceGroup `$resourceGroup -CosmosDbAccountName `$uniqueString"}[($PSCmdlet.ParameterSetName -ne "AzureStorage")]
        
        It "Can create a new table (CosmosDb account)" {
            $Table = Invoke-Expression("Get-AzTableTable -table `$GetAzTableTableCmdtTableName $GetCosmosDbTableCommand") 
            $Table | Should not be $null
        }

        It "Can open an existing table (CosmosDb account)" {
            $Table = Invoke-Expression("Get-AzTableTable -table `$GetAzTableTableCmdtTableName $GetCosmosDbTableCommand") 
            $Table | Should not be $null
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
            $tableInserts = $tables | Where-Object -Property Name -EQ "table$($uniqueString)insert"
            $partitionKey = [guid]::NewGuid().tostring()
            $rowKey = [guid]::NewGuid().tostring()
            
            foreach ($tableInsert in $tableInserts)
            {
                Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey $rowKey -property @{"computerName"="COMP01";"osVersion"="Windows 10";"status"="OK"}
                Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP02";"osVersion"="Windows 8.1";"status"="NeedsOsUpgrade"}
                Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP03";"osVersion"="Windows 8.1";"status"="NeedsOsUpgrade"}
                Add-AzTableRow -table $tableInsert -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP04";"osVersion"="Windows XP";"status"="NeedsOsUpgrade"}
            }
        }

        for ($i = 0; $i -lt $tableInserts.Count; $i++)
        {
            if ($i -eq 0)
            {
                $dataStore = "StorageAccount"
            }
            else
            {
                $dataStore = "CosmosDb"
            }
            
            It "Can it get all rows ($dataStore)" {
                $entityList = $null
                $expectedRowCount = 9
                $entityList = Get-AzTableRow -table $tableInserts[$i]
                $entityList.Count | Should be $expectedRowCount
            }

            It "Can it get rows by partition key ($dataStore)" {
                $entityList = $null
                $expectedRowCount = 4
                $entityList = Get-AzTableRow -table $tableInserts[$i] -partitionKey $partitionKey
                $entityList.Count | Should be $expectedRowCount
            }

            It "Can it get row by partition and row key ($dataStore)" {
                $entityList = $null
                $expectedRowCount = 1
                $entityList = @(Get-AzTableRow -table $tableInserts[$i] -partitionKey $partitionKey -RowKey $rowKey)
                $entityList.Count | Should be $expectedRowCount
            }

            It "Can it get row by column name using guid value ($dataStore)" {
                $entity = $null
                $expectedGuidValue = [guid]::NewGuid()
                Add-AzTableRow -table $tableInserts[$i] -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring())-property @{"computerName"="COMP05";"osVersion"="Windows 10";"status"="OK";"id"=$expectedGuidValue}

                $entity = Get-AzTableRow -Table $tableInserts[$i] -ColumnName "id" -guidvalue $expectedGuidValue -operator Equal
                $entity.id | Should be $expectedGuidValue
            }

            It "Can it get row by column name using string value ($dataStore)" {
                $entity = $null
                $expectedStringValue = "COMP02"
                $entity = Get-AzTableRow -Table $tableInserts[$i] -ColumnName "computerName" -value $expectedStringValue -operator Equal
                $entity.computerName | Should be $expectedStringValue
            }

            It "Can it get row using custom filter ($dataStore)" {
                $entityList = $null
                $expectedRowCount = 1
                $entityList = @(Get-AzTableRow -Table $tableInserts[$i] -CustomFilter "(osVersion eq 'Windows XP') and (computerName eq 'COMP04')")
                $entityList.Count | Should be $expectedRowCount
            }
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
            $tableInsert = $tables | Where-Object -Property Name -eq "table$($uniqueString)insert"
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

        if ($PSCmdlet.ParameterSetName -eq "AzureStorage")
        {
            Remove-AzResourceGroup -Name $resourceGroup -Force
        }
        else
        {
            Remove-AzStorageTable $GetAzTableTableCmdtTableName -Context $context -Force
            foreach ($tableName in $tableNames)
            {
                if (-not $tableName.StartsWith("cosmos"))
                {
                    Remove-AzStorageTable -Context $context -Name $tableName -Force
                }
            }
        }

        Write-Host -for DarkGreen "Done"
    }
}
