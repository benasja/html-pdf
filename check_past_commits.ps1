# Script to CHECK past commits from last 7 days (doesn't modify anything)
# This will show you what commits need fixing

$correctEmail = "benjanusevicius@gmail.com"
$correctName = "benasja"
$wrongEmails = @("benjanusevicvius@gmail.com", "benjanusevicvius@gmai.com")
$wrongNames = @("Benas")
$daysBack = 7

Write-Host "=== Checking Past Commits (Last $daysBack Days) ===" -ForegroundColor Green
Write-Host "This script only CHECKS - it doesn't modify anything" -ForegroundColor Cyan
Write-Host ""

# Find all .git directories
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
        $found = Get-ChildItem -Path $path -Directory -Recurse -Filter ".git" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\.git\*" }
        $repos += $found | ForEach-Object { Split-Path $_.FullName -Parent }
    }
}

$repos = $repos | Select-Object -Unique

Write-Host "Found $($repos.Count) git repositories" -ForegroundColor Cyan
Write-Host ""

$reposWithIssues = @()
$totalWrongCommits = 0

foreach ($repo in $repos) {
    Push-Location $repo
    
    try {
        $repoName = Split-Path $repo -Leaf
        $sinceDate = (Get-Date).AddDays(-$daysBack).ToString("yyyy-MM-dd")
        $commits = git log --since="$sinceDate" --format="%H|%an|%ae|%ad|%s" --all 2>$null
        
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
                Write-Host "  Found $($wrongCommits.Count) commits with wrong email/name:" -ForegroundColor Red
                
                foreach ($commit in $wrongCommits) {
                    Write-Host "    - $($commit.Hash): $($commit.Name) <$($commit.Email)>" -ForegroundColor Yellow
                    Write-Host "      Date: $($commit.Date)" -ForegroundColor Gray
                    Write-Host "      Message: $($commit.Message)" -ForegroundColor Gray
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
Write-Host "Repositories checked: $($repos.Count)" -ForegroundColor Cyan
Write-Host "Repositories with issues: $($reposWithIssues.Count)" -ForegroundColor Yellow
Write-Host "Total commits needing fix: $totalWrongCommits" -ForegroundColor Yellow

if ($reposWithIssues.Count -eq 0) {
    Write-Host ""
    Write-Host "Great! All commits from the last $daysBack days already have correct email/name!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "=== TO FIX THESE COMMITS ===" -ForegroundColor Yellow
    Write-Host "For each repository, you can run:" -ForegroundColor Cyan
    Write-Host "  cd <repo-path>" -ForegroundColor Gray
    Write-Host "  git filter-branch --env-filter \"`" -ForegroundColor Gray
    Write-Host "    if [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmail.com' ]; then" -ForegroundColor Gray
    Write-Host "      export GIT_COMMITTER_EMAIL='benjanusevicius@gmail.com'" -ForegroundColor Gray
    Write-Host "      export GIT_COMMITTER_NAME='benasja'" -ForegroundColor Gray
    Write-Host "    fi" -ForegroundColor Gray
    Write-Host "    if [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmail.com' ]; then" -ForegroundColor Gray
    Write-Host "      export GIT_AUTHOR_EMAIL='benjanusevicius@gmail.com'" -ForegroundColor Gray
    Write-Host "      export GIT_AUTHOR_NAME='benasja'" -ForegroundColor Gray
    Write-Host "    fi" -ForegroundColor Gray
    Write-Host "  `" --tag-name-filter cat -- --branches --tags" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then force push: git push origin --all --force" -ForegroundColor Red
    Write-Host ""
    Write-Host "WARNING: This rewrites history! Make sure no one else is working on these repos!" -ForegroundColor Red
}

