# Edit script settings

# Specify source directories.
$sourceDirs = @(
    # 'C:\path\to\Camera Roll'
    # 'C:\path\to\Camera Roll 2'
)

# Specify other directories (i.e. directories that might contain duplicates). Must be distinct from source directories.
$otherDirs = @(
    # 'C:\path\to\other folder'
    # 'C:\path\to\other folder 2'
)

# Whether to cache the search results into a .json and use it. Enable only if executing the script multiple times against very large folders.
# 0 - Disable
# 1 - Enable
$exportCacheAsJson = 0

# Whether duplicate criteria should also include file size and file hash.
# 0 - Disable (Only consider Date Taken)
# 1 - Enable (Consider Date Taken, file size, file hash)
$criteriaStrict = 0

function Get-FileMetaData {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Mandatory)]
        [System.IO.FileInfo]$FileInfo
    )

    begin {
        Add-Type -AssemblyName System.Drawing
    }
    process {
        $f = $FileInfo
        "Processing file: $( $f.FullName )" | Write-Host

        # Construct a customobject
        $o = [ordered]@{
            FullName = $f.FullName
            Name = $f.Name
            Length = $f.Length
            CreationTimeUtc = $f.CreationTimeUtc
            LastWriteTimeUtc = $f.LastWriteTimeUtc
            # Hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
            DateTaken = & {
                try {
                    # Improved version of https://stackoverflow.com/questions/6834259/how-can-i-get-programmatic-access-to-the-date-taken-field-of-an-image-or-video
                    $p = New-Object System.Drawing.Bitmap $f.FullName
                    $byteArray =  $p.GetPropertyItem(36867).Value
                    $dateTakenString = [System.Text.Encoding]::ASCII.GetString( $byteArray[0..18] )
                    $dateTakenDateTime = [datetime]::ParseExact($dateTakenString, "yyyy:MM:dd HH:mm:ss", $null)
                    $dateIso = Get-Date $dateTakenDateTime -Format 'yyyy-MM-ddTHH:mm:sszz00'
                }catch {
                    "Ignoring file $( $f.FullName ) without a Date Taken attribute. Reason: $( $_ )"| Write-Warning
                    $dateIso = $null
                }

                # Doesn't get Date taken
                # $shellObject = New-Object -ComObject Shell.Application
                # $directoryObject = $shellObject.NameSpace( $f.Directory.FullName )
                # $fileObject = $directoryObject.ParseName( $f.Name )
                # $property = 'Date taken'
                # for( $index = 5; $directoryObject.GetDetailsOf( $directoryObject.Items, $index ) -ne $property; ++$index ) { }
                # $value = $directoryObject.GetDetailsOf( $fileObject, $index )

                $dateIso
            }
        }
        $o['key'] = $o.DateTaken

        $o -as [PSCustomObject] # Send this immediately down the pipeline
    }
}

# Unused, doesn't get Date taken Modified version of: https://www.reddit.com/r/PowerShell/comments/jx8532/access_date_taken_of_picture_files/
# Function Get-FileMetaData {
#     [cmdletbinding()]
#     Param (
#         [parameter(valuefrompipeline,ValueFromPipelineByPropertyName,Position=1,Mandatory)]
#         [alias('Path','FullName')]
#         [string]$folder
#     )
#     process {
#         try{
#             "Processing folder $folder" | Write-Host -ForegroundColor Cyan

#             $shell = New-Object -ComObject Shell.Application
#             $currentfolder = $shell.namespace($folder)
#             foreach ($item in $currentfolder.items()) {
#                 "Processing item: $( $item.Path )" | Write-Host
#                 $ht = [ordered]@{}
#                 0..266 | ForEach-Object {
#                     $key = $currentfolder.GetDetailsOf($currentfolder.items,$_)
#                     $value = $currentfolder.GetDetailsOf($item,$_)
#                     if ($value) {
#                         "key: $key, value: $value" | Write-Host
#                         $ht[$key] = $value
#                     }
#                 }
#             }
#         }catch {
#             "Error while processing folder $folder : $($_.execption.message)" | Write-Warning
#         }
#     }
# }

function Get-ChildItemWithMetaData {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    ,
        [Parameter()]
        [string]
        $JsonFile
    )

    # Get file objects from an existing .json, or else create the file objects
    $files = if ($JsonFile -and (Test-Path $JsonFile)) {
        Get-Content $JsonFile -raw -ErrorAction Stop | ConvertFrom-Json | Sort-Object -Property FullName
        "Reusing file object cache: $JsonFile" | Write-Host -ForegroundColor Green
    }else {
        Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction Stop | Get-FileMetaData | Sort-Object -Property FullName
    }

    # Export to json file
    if ($JsonFile) {
        $files | ConvertTo-Json -Depth 100 | Out-File $JsonFile -encoding utf8
        "Exporting objects to $JsonFile" | Write-Host -ForegroundColor Green
    }

    $files
}

Set-StrictMode -Version Latest

# Normalize, compile, validate config
$sourceDirs = @( $sourceDirs | % { $_.Trim() } | ? { $_ } )
if ($sourceDirs.Count -eq 0) {
    "No source directories specified." | Write-Warning
    return
}
$otherDirs = @( $otherDirs | ? { $_ -notin $sourceDirs } | % { $_.Trim() } | ? { $_ } )
if ($otherDirs.Count -eq 0) {
    "No other directories specified. Ensure other directories entries are distinct from source directories." | Write-Warning
    return
}
$sourceJsonFile = if ($exportCacheAsJson) { [io.path]::combine($PWD, 'source.json') } else { '' }
$otherJsonFile = if ($exportCacheAsJson) {[io.path]::combine($PWD, 'other.json') } else { '' }

# Get objects in source group
$sourceFiles = [ordered]@{}
$sourceDirs | ForEach-Object {
    "`nProcessing source directory $( $_ )" | Write-Host -ForegroundColor Cyan
    Get-ChildItemWithMetaData -Path $_ -JsonFile $sourceJsonFile | % {
        $s = $_
        if (! $sourceFiles.Contains($s.key)) {
            $sourceFiles[$s.key] = $s # There may only be one unique source file
        }else {
            "Ignoring a duplicate file in source directory. file: `n$( $sourceFiles[$s.key].FullName ), duplicate: $( $s.FullName )" | Write-Verbose
        }
    }
}
# Get objects in other group
$otherFiles = [ordered]@{}
$otherDirs | ForEach-Object {
    "`nProcessing other directory $( $_ )" | Write-Host -ForegroundColor Cyan
    Get-ChildItemWithMetaData -Path $_ -JsonFile $sourceJsonFile | % {
        $o = $_
        if (! $otherFiles.Contains($o.key)) {
            $otherFiles[$o.key] = @() # There may be more than one other file
        }
        $otherFiles[$o.key] += $o
    }
}

$dups = [ordered]@{}
foreach ($k in @( $sourceFiles.Keys )) {
    if ($otherFiles.Contains($k)) {
        $s = $sourceFiles[$k] # Source
        foreach ($o in $otherFiles[$k]) {
            if ($s.FullName -ne $o.FullName) {
                $key = $k
                "`nComparing $( $s.FullName ) and $( $o.FullName ) of date taken: $k" | Write-Host
                if ($criteriaStrict) {
                    $h1 = Get-FileHash -Path $s.FullName -Algorithm SHA256 -ErrorAction Continue | Select-Object -ExpandProperty 'Hash'
                    $h2 = Get-FileHash -Path $o.FullName -Algorithm SHA256 -ErrorAction Continue | Select-Object -ExpandProperty 'Hash'
                    if ( ($s.Length -eq $o.Length) -and ($h1 -eq $h2) ) {
                        "File $( $o.FullName ) is a duplicate of $( $s.FullName ), Date taken: $( $s.DateTaken ), length: $( $s.Length ), hash: $( $h1 )" | Write-Host -ForegroundColor Green
                        $key = "$key-$( $s.Length )-$h1" # The hashtable key will be <DateTaken>-<Length>-<FileHash>. Value will be all matching files including the source file
                    }else {
                        continue
                    }
                }else {
                    "File $( $o.FullName ) is a duplicate of $( $s.FullName ). Date taken: $( $s.DateTaken )" | Write-Host -ForegroundColor Green
                }
                # Construct an object that organizes the duplicates by DateTaken
                if (!$dups.Contains($key)) {
                    $dups[$key] = @( $s.FullName ) # Source file is always the first object in the array
                }
                $dups[$key] += $o.FullName # Add duplicate file to array
                $dups[$key] = @(
                    $dups[$key] | Select-Object -Unique # Ensure items are unique in array
                )
            }
        }
    }else {
        "No duplicate found for date taken: $k" | Write-Host -ForegroundColor Gray
    }
}
"There were $( $dups.Count ) duplicates found." | Write-Host -ForegroundColor Green

# Export the duplicates to json
$jsonFile = Join-Path $PWD "duplicates.json"
$dups | ConvertTo-Json -Depth 100 | Out-File $jsonFile -Encoding utf8
"Exporting duplicates to $jsonFile" | Write-Host -ForegroundColor Green

# Now you can do whatever you want with the duplicates, e.g.
# $dups = Get-Content $jsonFile -Encoding utf8 -raw | ConvertFrom-Json
# $dups.psobject.Properties | % {
#     $key = $_.Name
#     $value = $_.Value
#     $sourceFile = $value[0]
#     $duplicateFiles = $value[1..($value.Count - 1)] # Ignore the first object

#     foreach ($f in $duplicateFiles) {
#         # Do something
#     }
# }

