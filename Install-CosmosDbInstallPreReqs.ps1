#Loading Preview Microsoft.WindowsAzure.Storage dll and dependencies for Cosmos DB support

# Download nuget
Write-Verbose "Downloading nuget.exe" -Verbose
$nugetFilename = "nuget.exe"
$destination = $PSScriptRoot
$webclient = New-Object System.Net.WebClient
$url = "https://dist.nuget.org/win-x86-commandline/latest/$nugetFilename"
$file = Join-Path $destination $nugetFilename
$webclient.DownloadFile($url,$file)

# Executing nuget to get necessary packages
Write-Verbose "Executing nuget to get necessary packages" -Verbose
.\nuget install WindowsAzure.Storage-PremiumTable -Prerelease

# Required assembles, please adjust as versions or names may change
$requiredDlls = @("WindowsAzure.Storage-PremiumTable.0.1.0-preview\lib\net45\Microsoft.WindowsAzure.Storage.dll",
                    "Microsoft.Data.Services.Client.5.8.2\lib\net40\Microsoft.Data.Services.Client.dll",
                    "Microsoft.Azure.DocumentDB.1.14.0\lib\net45\Microsoft.Azure.Documents.Client.dll",
                    "Microsoft.Azure.DocumentDB.1.14.0\runtimes\win7-x64\native\DocumentDB.Spatial.Sql.dll",
                    "Microsoft.Azure.DocumentDB.1.14.0\runtimes\win7-x64\native\Microsoft.Azure.Documents.ServiceInterop.dll",
                    "Newtonsoft.Json.6.0.8\lib\net45\Newtonsoft.Json.dll",
                    "Microsoft.Data.Edm.5.8.2\lib\net40\Microsoft.Data.Edm.dll",
                    "Microsoft.Data.OData.5.8.2\lib\net40\Microsoft.Data.OData.dll",
                    "Microsoft.OData.Core.7.2.0\lib\netstandard1.1\Microsoft.OData.Core.dll",
                    "Microsoft.OData.Edm.7.2.0\lib\netstandard1.1\Microsoft.OData.Edm.dll",
                    "Microsoft.Spatial.7.2.0\lib\netstandard1.1\Microsoft.Spatial.dll",
                    "Microsoft.Azure.KeyVault.Core.1.0.0\lib\net40\Microsoft.Azure.KeyVault.Core.dll",
                    "System.Spatial.5.8.2\lib\net40\System.Spatial.dll")

# Copying assembly files to root of module folder
Write-Verbose "Copying assembly files to root of module folder" -Verbose
foreach ($dll in $requiredDlls)
{
    $assembly = Join-Path $PSScriptRoot $dll
    $assemblyRootLevel = Join-Path $PSScriptRoot ($dll).Split("\")[0]

    Write-Verbose "Copying assembly $assembly to $destination" -Verbose
    Copy-Item $assembly $PSScriptRoot -Force
}

# Removing assembly folders
Write-Verbose "Removing assembly folders" -Verbose
foreach ($dll in $requiredDlls)
{
    $assemblyRootLevel = Join-Path $PSScriptRoot ($dll).Split("\")[0]

    Write-Verbose "Removing folder  $assemblyRootLevel" -Verbose
    Remove-Item $assemblyRootLevel -Recurse -Force -ErrorAction SilentlyContinue
}
