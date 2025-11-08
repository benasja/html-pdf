# Script to find and fix all git repositories with incorrect email/name
# This will fix git config for all repos found

$correctEmail = "benjanusevicius@gmail.com"
$correctName = "benasja"
$wrongEmails = @("benjanusevicvius@gmail.com", "benjanusevicvius@gmai.com")
$wrongNames = @("Benas")

Write-Host "=== Finding All Git Repositories ===" -ForegroundColor Green
Write-Host "Correct Email: $correctEmail" -ForegroundColor Cyan
Write-Host "Correct Name: $correctName" -ForegroundColor Cyan
Write-Host ""

# Find all .git directories in common locations
$searchPaths = @(
    "$env:USERPROFILE\Documents\Projects",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\source",
    "C:\Projects"
)

$repos = @()

foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Write-Host "Searching: $path" -ForegroundColor Yellow
        $found = Get-ChildItem -Path $path -Directory -Recurse -Filter ".git" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\.git\*" }
        $repos += $found | ForEach-Object { Split-Path $_.FullName -Parent }
    }
}

# Remove duplicates
$repos = $repos | Select-Object -Unique

Write-Host ""
Write-Host "Found $($repos.Count) git repositories" -ForegroundColor Green
Write-Host ""

$fixedRepos = @()
$needsFixRepos = @()

foreach ($repo in $repos) {
    Write-Host "Checking: $repo" -ForegroundColor Cyan
    
    Push-Location $repo
    
    try {
        $currentEmail = git config user.email
        $currentName = git config user.name
        
        $needsFix = $false
        $fixReason = @()
        
        if ($wrongEmails -contains $currentEmail -or $currentEmail -ne $correctEmail) {
            $needsFix = $true
            $fixReason += "Email: $currentEmail -> $correctEmail"
        }
        
        if ($wrongNames -contains $currentName -or $currentName -ne $correctName) {
            $needsFix = $true
            $fixReason += "Name: $currentName -> $correctName"
        }
        
        if ($needsFix) {
            Write-Host "  NEEDS FIX:" -ForegroundColor Red
            foreach ($reason in $fixReason) {
                Write-Host "    - $reason" -ForegroundColor Yellow
            }
            
            # Fix git config
            git config user.email $correctEmail
            git config user.name $correctName
            
            Write-Host "  FIXED!" -ForegroundColor Green
            $fixedRepos += @{
                Path = $repo
                OldEmail = $currentEmail
                OldName = $currentName
            }
        } else {
            Write-Host "  OK (already correct)" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  ERROR: Could not check this repository" -ForegroundColor Red
    } finally {
        Pop-Location
    }
    
    Write-Host ""
}

Write-Host "=== SUMMARY ===" -ForegroundColor Green
Write-Host "Total repositories checked: $($repos.Count)" -ForegroundColor Cyan
Write-Host "Repositories fixed: $($fixedRepos.Count)" -ForegroundColor Green

if ($fixedRepos.Count -gt 0) {
    Write-Host ""
    Write-Host "Fixed repositories:" -ForegroundColor Yellow
    foreach ($repo in $fixedRepos) {
        Write-Host "  - $($repo.Path)" -ForegroundColor Cyan
        Write-Host "    Email: $($repo.OldEmail) -> $correctEmail" -ForegroundColor Gray
        Write-Host "    Name: $($repo.OldName) -> $correctName" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== NEXT STEPS ===" -ForegroundColor Green
Write-Host "All git configs have been fixed for future commits." -ForegroundColor Cyan
Write-Host ""
Write-Host "To fix PAST commits (last 7 days), you have two options:" -ForegroundColor Yellow
Write-Host "1. Let commits stay as-is (they won't count but future ones will)" -ForegroundColor Gray
Write-Host "2. Amend recent commits (requires force push - be careful!)" -ForegroundColor Gray
Write-Host ""
Write-Host "Would you like to amend recent commits? (This will require force push)" -ForegroundColor Yellow
Write-Host "Type 'yes' to proceed with amending commits from the last 7 days" -ForegroundColor Yellow

