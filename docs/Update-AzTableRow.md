---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Update-AzTableRow

## SYNOPSIS
Updates a table entity

## SYNTAX

```powershell
Update-AzTableRow [-Table] <Object> [-entity] <Object> [<CommonParameters>]
```

## DESCRIPTION
Updates a table entity.
To work with this cmdlet, you need first retrieve an entity with one of the Get-AzTableRow cmdlets available and store in an object, change the necessary properties and then perform the update passing this modified entity back, through Pipeline or as argument. Notice that this cmdlet accepts only one entity per execution. This cmdlet cannot update Partition Key and/or RowKey because it uses those two values to locate the entity to update it, if this operation is required please delete the old entity and add the new one with the updated values instead.

## EXAMPLES

### EXAMPLE 1
```powershell
# Updating an entity

[string]$Filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"User1")
$person = Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $Filter
$person.lastName = "New Last Name"
$person | Update-AzTableRow -Table $Table
```

## PARAMETERS

### -Table
Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity exists

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -entity
The entity/row with new values to perform the update.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
