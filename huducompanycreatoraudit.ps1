################################################
##        Hudu Company Creator Audit          ##
##      Identify creators of organization     ##
################################################
$HuduBaseUrl   = "https://YOUDOMAIN.com"
$HuduApiKey    = "REDACTED"

# --- TOGGLE SWITCHES FOR TESTING ---
$TestMode      = $false   # Set to $false when you are ready to run the full historical sweep
$TestMaxPages  = 100      # Only scan this many pages if TestMode is true
$TestMaxRecords = 250     # Stop early once we collect this many records in test mode
# -----------------------------------

$outputCsv      = "C:\company_creations_audit.csv"
$checkpointFile = "C:\last_processed_creator_checkpoint.txt"

$lastCheckpointId = $null
$lastKnownPage = $null

if (-not $TestMode -and (Test-Path $checkpointFile)) {

    $checkpointData = (Get-Content $checkpointFile -Raw).Trim()

    if ($checkpointData -match '^(\d+)\|(\d+)$') {

        $lastCheckpointId = $matches[1]
        $lastKnownPage = [int]$matches[2]

        Write-Host "Loaded checkpoint ID: $lastCheckpointId" -ForegroundColor Cyan
        Write-Host "Loaded last known page: $lastKnownPage" -ForegroundColor Cyan
		
		Write-Host "ID=$lastCheckpointId" -ForegroundColor Yellow
Write-Host "PAGE=$lastKnownPage" -ForegroundColor Yellow
    }
}

# --- SMART AUTO-DETERMINE STARTING PAGE ---
if (-not $TestMode -and $null -ne $lastKnownPage) {

    # Start a little earlier than where we left off
    $page = [Math]::Max(1, ($lastKnownPage - 10))

    Write-Host "Starting search from page $page based on saved page checkpoint." -ForegroundColor Green

}
else {

    Write-Host "No checkpoint found. Starting full historical sync from page 1." -ForegroundColor Yellow
    $page = 1
}

$globalCache = [System.Collections.Generic.List[PSCustomObject]]::new()
$perPage = 250
$keepRunning = $true
#$highestIdFoundOnRun = $null
$lastSuccessfulPage = $page

Write-Host "Starting Hudu Activity Log Audit with Delta-Sync Checkpoint..." -ForegroundColor Cyan

while ($keepRunning) {
    if ($TestMode -and $page -gt $TestMaxPages) {
        Write-Host "Test mode page limit reached." -ForegroundColor Yellow
        break
    }

    $targetUri = "$HuduBaseUrl/api/v1/activity_logs?page=$page&per_page=$perPage"
    $success = $false
    $retries = 0
    $maxRetries = 5
    $response = $null

    # Retry loop for rate limits (HTTP 429 / Retry later)
    while (-not $success -and $retries -lt $maxRetries) {
        try {
            $response = Invoke-RestMethod -Uri $targetUri -Headers @{ "x-api-key" = $HuduApiKey } -Method Get
            $success = $true
        }
        catch {
            $retries++
            $backoffSeconds = [Math]::Pow(2, $retries)
            Write-Host "Rate limit hit on page $page. Retrying in $backoffSeconds seconds (Attempt $retries/$maxRetries)..." -ForegroundColor Yellow
            Start-Sleep -Seconds $backoffSeconds
        }
    }

    if (-not $success) {
        Write-Host "Failed to fetch page $page after $maxRetries attempts. Stopping." -ForegroundColor Red
        break
    }

    $Logs = $null
    if ($response.PSObject.Properties['activity_logs']) { $Logs = $response.activity_logs }
    else { $Logs = $response }

    $LogIds = if ($Logs -and $Logs.id) { @($Logs.id) } else { @() }

    if ($LogIds.Count -eq 0) {
        Write-Host "Reached bottom of activity logs at page $page." -ForegroundColor Green
        break
    }

    # Track the absolute newest ID found on page 1 for updating the checkpoint later
    if ($page -eq 1 -and $LogIds.Count -gt 0) {
        $highestIdFoundOnRun = "$($LogIds[0])".Trim()
    }

    $hitCheckpoint = $false

    for ($i = 0; $i -lt $LogIds.Count; $i++) {
        $logId          = "$($LogIds[$i])".Trim()
        
# --- CHECKPOINT SKIP & STOP CONDITION ---
if (-not $TestMode -and $null -ne $lastCheckpointId) {
    if ([int]$logId -le [int]$lastCheckpointId) {
        # Skip this log entry because we already processed it in a prior run
        continue
    }
}
        # ---------------------------------

        $logAction      = if ($Logs.action) { "$($Logs.action[$i])" } else { "" }
        $logRecordType  = if ($Logs.record_type) { "$($Logs.record_type[$i])" } else { "" }
        $logCompanyName = if ($Logs.company_name) { "$($Logs.company_name[$i])" } else { "Unknown" }
        $logUserName    = if ($Logs.user_name) { "$($Logs.user_name[$i])" } else { "System/API" }
        $logCreatedAt   = if ($Logs.created_at) { "$($Logs.created_at[$i])" } else { "" }
        $logCompanyId   = if ($Logs.company_id) { "$($Logs.company_id[$i])" } else { $null }
        $logRecordId    = if ($Logs.record_id) { "$($Logs.record_id[$i])" } else { $null }

        if ($logAction -eq "created" -and $logRecordType -eq "Company") {
            $CompanyId = if ($null -ne $logCompanyId) { $logCompanyId } else { $logRecordId }
            $CompanyUrl = if ($null -ne $CompanyId) { "$HuduBaseUrl/companies/$CompanyId" } else { "$HuduBaseUrl/companies" }

            $globalCache.Add([PSCustomObject]@{
				CompanyID  =  $CompanyId
                ID          = $logId
                Company     = $logCompanyName
                RecordType  = $logRecordType
                Creator     = $logUserName
                CreatedTime = $logCreatedAt
                DirectLink  = $CompanyUrl
            })

            if ($TestMode -and $globalCache.Count -ge $TestMaxRecords) {
                Write-Host "Test mode record limit reached." -ForegroundColor Yellow
                $keepRunning = $false
                break
            }
        }
    }

    if ($hitCheckpoint -or -not $keepRunning) { break }

    Write-Host "Scanned page $page (New Company Creations found: $($globalCache.Count))..." -ForegroundColor DarkCyan
    $lastSuccessfulPage = $page
    Start-Sleep -Milliseconds 250
    $page++
}

# 2. Merge with existing CSV data if running a delta update, or write fresh
if (-not $TestMode) {
    if ($globalCache.Count -gt 0) {
        if (Test-Path $outputCsv) {
           $existingData = Import-Csv -Path $outputCsv
# Combine old data with new data, filtering duplicates by ID while keeping all columns intact
$combinedData = @(@($globalCache) + @($existingData)) | Group-Object ID | ForEach-Object { $_.Group[0] }
$combinedData | Export-Csv -Path $outputCsv -NoTypeInformation -Force
            Write-Host "Appended $($globalCache.Count) new records to existing master CSV." -ForegroundColor Cyan
        } else {
            $globalCache | Export-Csv -Path $outputCsv -NoTypeInformation -Force
            Write-Host "Created new master CSV file with $($globalCache.Count) records." -ForegroundColor Cyan
        }
    } else {
        Write-Host "No new records found. Master CSV left completely untouched." -ForegroundColor Yellow
    }

    # 3. Update checkpoint file safely
    if (Test-Path $outputCsv) {
        $allRecords = Import-Csv -Path $outputCsv
        if ($allRecords) {
            $maxId = ($allRecords | Measure-Object -Property ID -Maximum).Maximum
           "$maxId|$lastSuccessfulPage" |
    Set-Content -Path $checkpointFile -Force

Write-Host "Updated checkpoint: ID=$maxId Page=$lastSuccessfulPage" -ForegroundColor Green
        }
   }
}

Write-Host "`nDelta-sync complete! Processed $($globalCache.Count) new company creation records." -ForegroundColor Green
Write-Host "Saved to: $outputCsv" -ForegroundColor Cyan
