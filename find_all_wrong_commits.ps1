# Comprehensive script to find ALL commits with wrong email/name in ALL repositories

$correctEmail = "benjanusevicius@gmail.com"
$correctName = "benasja"
$wrongEmails = @("benjanusevicvius@gmail.com", "benjanusevicvius@gmai.com")
$wrongNames = @("Benas")

Write-Host "=== Finding ALL Commits with Wrong Email/Name ===" -ForegroundColor Green
Write-Host "Searching all common project locations..." -ForegroundColor Cyan
Write-Host ""

# Expanded search paths
$searchPaths = @(
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\source",
    "$env:USERPROFILE\Projects",
    "C:\Projects",
    "C:\dev",
    "C:\code",
    "D:\Projects",
    "D:\dev",
    "D:\code"
)

$allRepos = @()

foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Write-Host "Searching: $path" -ForegroundColor Yellow
        try {
            $found = Get-ChildItem -Path $path -Directory -Recurse -Filter ".git" -ErrorAction SilentlyContinue -Depth 5 | 
                     Where-Object { 
                         $_.FullName -notlike "*\node_modules\*" -and 
                         $_.FullName -notlike "*\.git\*" -and
                         $_.FullName -notlike "*\venv\*" -and
                         $_.FullName -notlike "*\env\*"
                     }
            $allRepos += $found | ForEach-Object { Split-Path $_.FullName -Parent }
        } catch {
            # Skip paths with access issues
        }
    }
}

$allRepos = $allRepos | Select-Object -Unique

Write-Host ""
Write-Host "Found $($allRepos.Count) git repositories" -ForegroundColor Green
Write-Host ""

$reposWithIssues = @()
$totalWrongCommits = 0

foreach ($repo in $allRepos) {
    Push-Location $repo
    
    try {
        $repoName = Split-Path $repo -Leaf
        
        # Check ALL commits (not just last 7 days)
        $commits = git log --all --format="%H|%an|%ae|%ad|%s" 2>$null
        
        if ($commits) {
            $wrongCommits = @()
            
            foreach ($commit in $commits) {
                $parts = $commit -split '\|'
                if ($parts.Length -ge 3) {
                    $hash = $parts[0]
                    $name = $parts[1]
                    $email = $parts[2]
                    $date = if ($parts.Length -gt 3) { $parts[3] } else { "" }
                    $message = if ($parts.Length -gt 4) { $parts[4] } else { "" }
                    
                    if ($wrongEmails -contains $email -or $wrongNames -contains $name) {
                        $wrongCommits += @{
                            Hash = $hash.Substring(0, 7)
                            FullHash = $hash
                            Name = $name
                            Email = $email
                            Date = $date
                            Message = $message
                        }
                    }
                }
            }
            
            if ($wrongCommits.Count -gt 0) {
                Write-Host "Repository: $repoName" -ForegroundColor Yellow
                Write-Host "  Path: $repo" -ForegroundColor Gray
                Write-Host "  Found $($wrongCommits.Count) commits with wrong email/name" -ForegroundColor Red
                
                # Show first 5 commits as examples
                $showCount = [Math]::Min(5, $wrongCommits.Count)
                for ($i = 0; $i -lt $showCount; $i++) {
                    $commit = $wrongCommits[$i]
                    Write-Host "    - $($commit.Hash): $($commit.Name) <$($commit.Email)>" -ForegroundColor Yellow
                    Write-Host "      Date: $($commit.Date)" -ForegroundColor Gray
                    Write-Host "      Message: $($commit.Message.Substring(0, [Math]::Min(60, $commit.Message.Length)))" -ForegroundColor Gray
                }
                
                if ($wrongCommits.Count -gt 5) {
                    Write-Host "    ... and $($wrongCommits.Count - 5) more commits" -ForegroundColor Gray
                }
                
                $reposWithIssues += @{
                    Path = $repo
                    Name = $repoName
                    Commits = $wrongCommits
                }
                
                $totalWrongCommits += $wrongCommits.Count
                Write-Host ""
            }
        }
        
    } catch {
        # Skip repos with errors
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Green
Write-Host "Repositories checked: $($allRepos.Count)" -ForegroundColor Cyan
Write-Host "Repositories with issues: $($reposWithIssues.Count)" -ForegroundColor Yellow
Write-Host "Total commits needing fix: $totalWrongCommits" -ForegroundColor Yellow

if ($reposWithIssues.Count -eq 0) {
    Write-Host ""
    Write-Host "Great! No commits found with wrong email/name!" -ForegroundColor Green
    Write-Host "All your repositories are already using the correct email/name." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "=== REPOSITORIES THAT NEED FIXING ===" -ForegroundColor Yellow
    foreach ($repo in $reposWithIssues) {
        Write-Host ""
        Write-Host "Repository: $($repo.Name)" -ForegroundColor Cyan
        Write-Host "  Path: $($repo.Path)" -ForegroundColor Gray
        Write-Host "  Commits to fix: $($repo.Commits.Count)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  To fix, run these commands:" -ForegroundColor Green
        Write-Host "    cd `"$($repo.Path)`"" -ForegroundColor White
        Write-Host "    git filter-branch -f --env-filter `"" -ForegroundColor White
        Write-Host "      if [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmail.com' ] || [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmai.com' ]; then" -ForegroundColor White
        Write-Host "        export GIT_COMMITTER_EMAIL='benjanusevicius@gmail.com'" -ForegroundColor White
        Write-Host "        export GIT_COMMITTER_NAME='benasja'" -ForegroundColor White
        Write-Host "      fi" -ForegroundColor White
        Write-Host "      if [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmail.com' ] || [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmai.com' ]; then" -ForegroundColor White
        Write-Host "        export GIT_AUTHOR_EMAIL='benjanusevicius@gmail.com'" -ForegroundColor White
        Write-Host "        export GIT_AUTHOR_NAME='benasja'" -ForegroundColor White
        Write-Host "      fi" -ForegroundColor White
        Write-Host "      if [ `$GIT_COMMITTER_NAME = 'Benas' ]; then" -ForegroundColor White
        Write-Host "        export GIT_COMMITTER_NAME='benasja'" -ForegroundColor White
        Write-Host "      fi" -ForegroundColor White
        Write-Host "      if [ `$GIT_AUTHOR_NAME = 'Benas' ]; then" -ForegroundColor White
        Write-Host "        export GIT_AUTHOR_NAME='benasja'" -ForegroundColor White
        Write-Host "      fi" -ForegroundColor White
        Write-Host "    `" --tag-name-filter cat -- --branches --tags" -ForegroundColor White
        Write-Host ""
        Write-Host "    Then force push:" -ForegroundColor Yellow
        Write-Host "    git push origin --all --force" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host "=== IMPORTANT WARNINGS ===" -ForegroundColor Red
    Write-Host "1. This rewrites git history - make sure you have backups!" -ForegroundColor Yellow
    Write-Host "2. Don't do this if others are working on these repositories!" -ForegroundColor Yellow
    Write-Host "3. Force push will overwrite remote history!" -ForegroundColor Yellow
    Write-Host "4. Make sure you're the only one working on these repos!" -ForegroundColor Yellow
}

