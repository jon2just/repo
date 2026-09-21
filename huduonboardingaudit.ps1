# ==============================================================================
# --- HUDU ONBOARDING/DOCUMENTATION AUDIT SCRIPT (ACCOUNTABILITY EXTENSION) ---
# ==============================================================================
$RunInTestMode        = $false           # set to true for running against one company. false to run in prod
$TestCompanyWildcard  = "Test company*"   # Target names dynamically (e.g., "Acme*", "*Inc*")

# --- Configuration Variables ---
$HuduBaseUrl   = "https://YOURDOMAIN.COM"
$HuduApiKey    = "REDACTED"


# --- STATUS FILTERS ---
$StatusesToSkip = @("Inactive", "Archive", "Prospect")
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not (Get-Module -ListAvailable -Name HuduAPI)) {
    Install-Module -Name HuduAPI -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
}
Import-Module HuduAPI -ErrorAction Stop

New-HuduBaseURL $HuduBaseUrl
New-HuduAPIKey $HuduApiKey

Write-Host "1. Fetching baseline list..." -ForegroundColor Cyan
$allCompanies = Get-HuduCompanies
$allLayouts = Get-HuduAssetLayouts

# --- THE SPEED WEAPON: Load massive items into RAM up front ---
Write-Host "2. Loading global articles and passwords into memory for ultra-fast matching..." -ForegroundColor Cyan
$globalArticleCache = Get-HuduArticles
$globalPasswordCache = Get-HuduPasswords
Write-Host "-> Successfully pre-cached databases into RAM." -ForegroundColor Green

# Apply the testing safety valve if toggle is enabled
if ($RunInTestMode) {
    $allCompanies = $allCompanies | Where-Object { $_.name -like $TestCompanyWildcard }
    Write-Host "⚠️ TEST MODE ACTIVE: Limited to checking companies matching wildcard '$TestCompanyWildcard'." -ForegroundColor Yellow
} else {
    Write-Host "🚀 PRODUCTION MODE ACTIVE: Preparing full database run." -ForegroundColor Green
}

$totalCompanies = $allCompanies.Count
Write-Host "Starting high-speed onboarding gap analysis...`n" -ForegroundColor Cyan

$onboardingReport = @()
$counter = 0

foreach ($company in $allCompanies) {
    $counter++
    
    # Force the company ID to a strict integer format
    $companyId     = [int]$company.id
    $companyName   = $company.name
    $companyStatus = $company.status

    # --- STATUS FILTER CHECK ---
    if ($companyStatus -and ($StatusesToSkip -contains $companyStatus)) {
        continue
    }

    # Graphical Progress Bar
    Write-Progress -Activity "Auditing Onboarding Documentation" `
                   -Status "Processing: ${companyName} ($counter of $totalCompanies)" `
                   -PercentComplete (($counter / $totalCompanies) * 100)

    try {
        # 1. Fetch targeted assets for just this single company (Fast server-side call)
        $testAssets = Get-HuduAssets -company_id $companyId
        
        # 2. Sort by creation date to isolate the very first asset built in this space
        $firstFootprint = $testAssets | Sort-Object created_at | Select-Object -First 1
        
        # 3. Establish the base default identity and tenure states
        $onboardingOwner = "System/Unassigned Integration"
        $daysActive = 0

        if ($firstFootprint) {
            # Extract clean string properties directly via standard pipeline
            $creator = $firstFootprint.creator_name
            $updater = $firstFootprint.updated_by_user_name
            
            # Match against the true human text values
            if ($null -ne $creator -and $creator -ne "") {
                $onboardingOwner = $creator
            } elseif ($null -ne $updater -and $updater -ne "") {
                $onboardingOwner = $updater
            }

            # Calculate exact tenure days based on the original asset creation footprint
            if ($firstFootprint.created_at) {
                $daysActive = ((Get-Date) - (Get-Date $firstFootprint.created_at)).Days
            }
        }

        # 4. Notes Check (Since we have to check notes field on the individual company)
        $companyDetails = Get-HuduCompanies -id $companyId
        $rawNotes = $companyDetails.notes
        $defaultHtmlPlaceholder = "<p>Document additional information about the company</p>"
        $defaultCleanPlaceholder = "Document additional information about the company"

        $missingQuickNotes = $true
        if ($null -ne $rawNotes -and $rawNotes -ne "") {
            $notesString = ($rawNotes | Out-String).Trim()
            if ($notesString -and $notesString -ne $defaultHtmlPlaceholder -and $notesString -ne $defaultCleanPlaceholder) {
                $missingQuickNotes = $false
            }
        }
        
        # 5. Articles Check (0-Network Lookup from memory cache)
        $kbArticles = $globalArticleCache | Where-Object { $_.company_id -eq $companyId }
        $realArticleCount = if ($kbArticles) { $kbArticles.Count } else { 0 }
        $missingArticles = $realArticleCount -eq 0

        # 6. Passwords Check (0-Network Lookup from memory cache)
        $passwords = $globalPasswordCache | Where-Object { $_.company_id -eq $companyId }
        $missingPasswords = $null -eq $passwords -or $passwords.Count -eq 0

        # 7. Layout and Contacts Check
        $missingContacts = $true
        $foundAssetTypes = @()

        if ($testAssets) {
            $uniqueLayouts = $testAssets | Where-Object { $_.asset_type } | Select-Object -ExpandProperty asset_type -Unique
            foreach ($layoutName in $uniqueLayouts) {
                if ($allLayouts.name -contains $layoutName) {
                    $foundAssetTypes += $layoutName
                    if ($layoutName -eq "Contacts") { $missingContacts = $false }
                }
            }
        }

        $populatedAssets = if ($foundAssetTypes.Count -gt 0) { ($foundAssetTypes | Select-Object -Unique) -join ", " } else { "None" }

        # Calculate Gaps
        $gaps = @()
        if ($missingQuickNotes) { $gaps += "Quick Notes" }
        if ($missingArticles)   { $gaps += "KB Articles" }
        if ($missingPasswords)  { $gaps += "Passwords" }
        if ($missingContacts)   { $gaps += "Contacts" }

        $status = if ($gaps.Count -eq 4) { "Completely Blank" } elseif ($gaps.Count -gt 0) { "Missing Key Components" } else { "Minimal Onboarding Met" }

        $onboardingReport += [PSCustomObject]@{
            CompanyID        = $companyId
			CompanyName      = $companyName
            #ClientAgeInDays  = $daysActive
			OldestAssetAgeInDays = $daysActive
            CompanyStatus    = $companyStatus
            OnboardingStatus = $status
            MissingItems     = if ($gaps.Count -gt 0) { $gaps -join ", " } else { "None" }
            KBArticlesCount  = $realArticleCount
            HasRealNotes     = if ($missingQuickNotes) { "No" } else { "Yes" }
            HasPasswords     = if ($missingPasswords) { "No" } else { "Yes" }
            HasContacts      = if ($missingContacts) { "No" } else { "Yes" }
            AssetsPopulated  = $populatedAssets
        }
    } catch {
        Write-Host "⚠️ Error querying ${companyName}: $_" -ForegroundColor Red
    }
    
    # Minimal 100ms pause keeps things moving rapidly while avoiding connection limits
    Start-Sleep -Milliseconds 100
}

Write-Progress -Activity "Auditing Onboarding Documentation" -Completed

if ($onboardingReport.Count -gt 0) {
    # Print preview block
    $onboardingReport | Sort-Object OnboardingStatus, CompanyName | Select-Object -First 20 | Format-Table -AutoSize

    # Save cleanly with UTF8 encoding
    $dateStamp = Get-Date -Format "yyyy-MM-ddss"
    $desktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "Hudu_Onboarding_Audit_Final_$dateStamp.csv")
    $onboardingReport | Sort-Object OnboardingStatus, CompanyName | Export-Csv -Path $desktopPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nReport successfully compiled and saved to Desktop: $desktopPath" -ForegroundColor Green
} else {
    Write-Host "❌ No matching records processed or compiled." -ForegroundColor Red
}
