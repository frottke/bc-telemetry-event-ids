$settingsPath = Join-Path -Path $PWD -ChildPath 'settings.json'
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
    if (-not $MainUrl) { $MainUrl = $settings.MainUrl }
    if (-not $OutJson) { $OutJson = $settings.OutJson }
}

function Resolve-RelativeUrl {
    param([string]$BaseUrl,[string]$RelativePath)
    return (New-Object System.Uri([System.Uri]$BaseUrl, $RelativePath)).AbsoluteUri
}

function Get-ContentText {
    param([string]$Url)
    (Invoke-WebRequest -Uri $Url -Headers @{ 'Accept' = 'text/plain' }).Content
}

function Convert-MarkdownTables {
    param([string]$Markdown)
    $lines = $Markdown -split "`r?`n"
    $results = @()
    for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\|.*\|\s*$' -and $i+1 -lt $lines.Count -and $lines[$i+1] -match '^\s*\|[ :\-|]+\|\s*$') {
            $columns = ($lines[$i].Trim().Trim('|') -split '\|').ForEach({ $_.Trim() })
            $i += 2
            while ($i -lt $lines.Count -and $lines[$i] -match '^\s*\|.*\|\s*$') {
                $cells = ($lines[$i].Trim().Trim('|') -split '\|').ForEach({ $_.Trim() })
                $obj = [ordered]@{}
                for ($c=0; $c -lt $columns.Count; $c++) {
                    $name = if ($columns[$c]) { $columns[$c] } else { "Col$($c+1)" }
                    $obj[$name] = if ($c -lt $cells.Count) { $cells[$c] } else { $null }
                }
                $results += [pscustomobject]$obj
                $i++
            }
            $i--
        }
    }
    $results
}

function UnMd {
    param([string]$s)
    if ([string]::IsNullOrWhiteSpace($s)) { return $s }
    $x = $s
    $x = [regex]::Replace($x, '\[([^\]]+)\]\([^)]+\)', '$1') # Links
    $x = $x -replace '`',''                                # Backticks
    $x = $x -replace '&amp;','&' -replace '&lt;','<' -replace '&gt;','>'
    $x.Trim()
}

$mainMd = Get-ContentText -Url $MainUrl

# extract includes
$includePattern = '\[!INCLUDE\[[^\]]+\]\((?<path>[^)]+)\)\]'
$includes = [regex]::Matches($mainMd, $includePattern)

# read included files
$Result = foreach ($m in $includes) {
    $incUrl = Resolve-RelativeUrl -BaseUrl $MainUrl -RelativePath $m.Groups['path'].Value
    $incMd  = Get-ContentText -Url $incUrl
    foreach ($r in (Convert-MarkdownTables -Markdown $incMd)) {
        $eid = $r.'Event ID'; if (-not $eid) { $eid = $r.'EventId' } if (-not $eid) { $eid = $r.'ID' }
        $area = $r.'Area'
        $msg  = $r.'Message'
        if ($eid -or $area -or $msg) {
            [pscustomobject]@{
                eventId          = UnMd $eid
                eventArea        = UnMd $area
                eventDescription = UnMd $msg
            }
        }
    }
}

$Result = $Result | Sort-Object 'eventId','eventArea','eventDescription' -Unique #Unique just to be sure if there are any duplicates
$Result | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $OutJson