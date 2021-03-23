<#
.SYNOPSIS
    This script is for restructuring or updating key-value pairs in DocumentDB. 
    It leverages dt.exe migration tool to transfer data across containers.
.DESCRIPTION
    This is an automation script to perform below tasks
    1. Create a new backup container before restructuring data.
    2. Import all the documents in a single json file called "imported-file.json" and that gets stored in the same directory.
    3. Unique folder is generated on each run.
    4. Calls script "mapping.psm1" to update json objects based on user input.
    5. Once migrated, new file with updated records is created in the same running folder, and named as "migrated-file.json"
    6. [ToDo] Steps for deleting existing container and replacing content with the updated json files (migrated-file.josn) neess to be
       automated.

.NOTES
    Version        : 1.0
    File Name      : migration.ps1
    Author         : Pushpdeep Gupta (pusgup@microsoft.com)
    Creation Date  : March 22, 2021
    Prerequisites  : PowerShell V7.x, Azure Cosmos Data Migration tool (dt.exe)
    Purpose/Change : Initial script development
#>
[CmdletBinding()]
param (
    [string] $cosmosConnectionString,
    [string] $collectionName,
    [string] $backupCollection,
    [string] $dmtPath,
    [string] $directoryToStoreMigratedFiles,
    [string] $sourceProperty,
    [string] $targetProperty,
    [string] $targetPropertyValue,
    [string] $filterProperty,
    [string] $filterPropertyValue,
    [bool] $forceReplace, 
    [string] $folderPrefix
)

Import-Module ".\mapping.psm1"
#create Base path if not exists
$uuid = New-Guid
$appendedFolder = "$($uuid)-$($folderPrefix)"
$basePath = "$($directoryToStoreMigratedFiles)\$($appendedFolder)"
New-Item -ItemType Directory -Force -Path $basePath

$importedFileLocation = "$($directoryToStoreMigratedFiles)\$($appendedFolder)\imported-file.json"
$migratedFileLocation = "$($directoryToStoreMigratedFiles)\$($appendedFolder)\migrated-file.json"

#Create a back-Up collection
#Add current epoch time in back up collection name
$epochTime = Get-Date (Get-Date).ToUniversalTime() -UFormat %s
$finalBackUpCollection = [string]::IsNullOrEmpty($backupCollection) ? $collectionName + $epochTime : $backupCollection
Write-Host "Backup name: $($finalBackUpCollection). Backup creation in progress..."
$importArgs = "/s:DocumentDB /s.ConnectionString:""$($cosmosConnectionString)"" /s.Collection:""$($collectionName)"" /t:DocumentDB /t.ConnectionString:""$($cosmosConnectionString)"" /t.Collection:""$($finalBackUpCollection)"" /t.PartitionKey:/_partitionKey /t.CollectionThroughput:4000"
Start-Process -NoNewWindow -Wait -FilePath $dmtPath -ArgumentList $importArgs
Write-Host "Backup Completed. Container: $($finalBackUpCollection)"

#Import documents into single json file from source Cosmos DB
# Run migration tool to donlaod documents in migration directory.
Write-Host "Importing Backup files for migration..."
$importArgs = "/s:DocumentDB /s.ConnectionString:""$($cosmosConnectionString)"" /s.Collection:""$($finalBackUpCollection)"" /t:JsonFile /t.File:""$($importedFileLocation)"""
Start-Process -NoNewWindow -Wait -FilePath $dmtPath -ArgumentList $importArgs
Write-Host "Import Competed. Imported file location: $($importedFileLocation)"

#Property remapping
$discardedIds = ''
$json = Get-Content $importedFileLocation  | Out-String | ConvertFrom-Json
$filteredJson = $json | Where-Object {$_.$filterProperty -eq $filterPropertyValue}
Write-Host "Updating properties of $($json.Length) Documents ..."
foreach($item in $filteredJson) {   
    try {
        #Source
        if(![string]::IsNullOrEmpty($targetPropertyValue)){
            $sv = $targetPropertyValue  
            
        }
        else{
            $sv =  GetorSetPropertyValues -item $item -sv $null -copyValue $false -property $sourceProperty -fr $forceReplace
        } 
        if($null -eq $sv){
            $sv = ''
        }   

        $sv = GetorSetPropertyValues -item $item -sv $sv -copyValue $true -property $targetProperty -fr $forceReplace
        $updatedRecordCount++     
    }
    catch {
        $discardedIds = "$($discardedIds), $($item.id)"
        Write-Error $PSItem.Exception
    }
}

$json | ConvertTo-Json -Depth 9 | Set-Content $migratedFileLocation
Write-Host "Update completed for $($updatedRecordCount) documents. Migrated file: $($migratedFileLocation)"
Write-Output "Douments errored out: $($discardedIds.Length). Ids: $($discardedIds)"


