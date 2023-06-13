---
external help file: AzureRmStorageTableCoreHelper-help.xml
Module Name: azurermstoragetable
online version:
schema: 2.0.0
---

# Get-AzTableRow

## SYNOPSIS
Returns all rows/entities from a storage table - no Filtering

## SYNTAX

### byCustomFilter
```powershell
Get-AzTableRow [-Table <Object>] [-SelectColumn <System.Collections.Generic.List`1[System.String]>]
 -CustomFilter <String> [-Top <Int32>] [<CommonParameters>]
```

### byColumnGuid
```powershell
Get-AzTableRow [-Table <Object>] [-SelectColumn <System.Collections.Generic.List`1[System.String]>]
 [-ColumnName <String>] -GuidValue <Guid> [-Operator <String>] [-Top <Int32>] [<CommonParameters>]
```

### byColumnString
```powershell
Get-AzTableRow [-Table <Object>] [-SelectColumn <System.Collections.Generic.List`1[System.String]>]
 -ColumnName <String> -Value <String> -Operator <String> [-Top <Int32>] [<CommonParameters>]
```

### byPartRowKeys
```powershell
Get-AzTableRow [-Table <Object>] [-SelectColumn <System.Collections.Generic.List`1[System.String]>]
 [-PartitionKey <String>] -RowKey <String> [-Top <Int32>] [<CommonParameters>]
```

### byPartitionKey
```powershell
Get-AzTableRow [-Table <Object>] [-SelectColumn <System.Collections.Generic.List`1[System.String]>]
 -PartitionKey <String> [-Top <Int32>] [<CommonParameters>]
```

### GetAll
```powershell
Get-AzTableRow -Table <Object> [-SelectColumn <System.Collections.Generic.List`1[System.String]>]
 [-Top <Int32>] [<CommonParameters>]
```

### SelectColumn
```powershell
Get-AzTableRow -Table <Object> [<CommonParameters>] -SelectColumn [<string[]>]
```

## DESCRIPTION
Used to return entities from a table with several options, this replaces all other Get-AzTable<XYZ> cmdlets.

## EXAMPLES

### EXAMPLE 1
```powershell
# Getting all rows
Get-AzTableRow -Table $Table

# Getting rows by partition key
Get-AzTableRow -Table $table -partitionKey NewYorkSite

# Getting specific columns
Get-AzTableRow -Table $table -partitionKey NewYorkSite -SelectColumn @('computerName', 'osVersion')

# Getting rows by partition and row key
Get-AzTableRow -Table $table -partitionKey NewYorkSite -rowKey "afc04476-bda0-47ea-a9e9-7c739c633815"

# Getting rows by Columnm Name using Guid columns in table
Get-AzTableRow -Table $Table -ColumnName "id" -guidvalue ([guid]"5fda3053-4444-4d23-b8c2-b26e946338b6") -operator Equal

# Getting rows by Columnm Name using string columns in table
Get-AzTableRow -Table $Table -ColumnName "osVersion" -value "Windows NT 4" -operator Equal

# Getting rows using Custom Filter
Get-AzTableRow -Table $Table -CustomFilter "(osVersion eq 'Windows NT 4') and (computerName eq 'COMP07')"

# Querying with a maximum number of rows returned
Get-AzTableRow -Table $Table -partitionKey NewYorkSite -Top 10

```

## PARAMETERS

### -Table
Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities (common to all parameter sets)

```yaml
Type: Object
Parameter Sets: byCustomFilter, byColummnGuid, byColummnString, byPartRowKeys, byPartitionKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Object
Parameter Sets: GetAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SelectColumn
Columns to be fetched by the query

```yaml
Type: System.Collections.Generic.List`1[System.String]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PartitionKey
Identifies the table partition (byPartitionKey and byPartRowKeys parameter sets)

```yaml
Type: String
Parameter Sets: byPartRowKeys
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: byPartitionKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RowKey
Identifies the row key in the partition (byPartRowKeys parameter set)

```yaml
Type: String
Parameter Sets: byPartRowKeys
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ColumnName
Column name to compare the value to (byColummnString and byColummnGuid parameter sets)

```yaml
Type: String
Parameter Sets: byColummnGuid
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: byColummnString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Value that will be looked for in the defined column (byColummnString parameter set)

```yaml
Type: String
Parameter Sets: byColummnString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GuidValue
Value that will be looked for in the defined column as Guid (byColummnGuid parameter set)

```yaml
Type: Guid
Parameter Sets: byColummnGuid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Operator
Supported comparison Operator.
Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual" (byColummnString and byColummnGuid parameter sets)

```yaml
Type: String
Parameter Sets: byColummnGuid
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: byColummnString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomFilter
Custom Filter string (byCustomFilter parameter set)

```yaml
Type: String
Parameter Sets: byCustomFilter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Top
Return only the first n rows from the query (all parameter sets)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
