# Script to fix past commits from last 7 days in all repositories
# This will amend commits to use correct email/name

$correctEmail = "benjanusevicius@gmail.com"
$correctName = "benasja"
$wrongEmails = @("benjanusevicvius@gmail.com", "benjanusevicvius@gmai.com")
$wrongNames = @("Benas")
$daysBack = 7

Write-Host "=== Finding and Fixing Past Commits (Last $daysBack Days) ===" -ForegroundColor Green
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

$reposToFix = @()

foreach ($repo in $repos) {
    Push-Location $repo
    
    try {
        $repoName = Split-Path $repo -Leaf
        Write-Host "Checking: $repoName" -ForegroundColor Yellow
        
        # Get commits from last 7 days
        $sinceDate = (Get-Date).AddDays(-$daysBack).ToString("yyyy-MM-dd")
        $commits = git log --since="$sinceDate" --format="%H|%an|%ae|%s" --all
        
        if ($commits) {
            $needsFix = $false
            $wrongCommits = @()
            
            foreach ($commit in $commits) {
                $parts = $commit -split '\|'
                if ($parts.Length -ge 3) {
                    $hash = $parts[0]
                    $name = $parts[1]
                    $email = $parts[2]
                    $message = if ($parts.Length -gt 3) { $parts[3] } else { "" }
                    
                    if ($wrongEmails -contains $email -or $wrongNames -contains $name) {
                        $needsFix = $true
                        $wrongCommits += @{
                            Hash = $hash.Substring(0, 7)
                            Name = $name
                            Email = $email
                            Message = $message
                        }
                    }
                }
            }
            
            if ($needsFix) {
                Write-Host "  Found $($wrongCommits.Count) commits with wrong email/name:" -ForegroundColor Red
                foreach ($commit in $wrongCommits) {
                    Write-Host "    - $($commit.Hash): $($commit.Name) <$($commit.Email)>" -ForegroundColor Yellow
                    Write-Host "      Message: $($commit.Message)" -ForegroundColor Gray
                }
                
                $reposToFix += @{
                    Path = $repo
                    Name = $repoName
                    Commits = $wrongCommits
                }
            } else {
                Write-Host "  No commits need fixing" -ForegroundColor Green
            }
        } else {
            Write-Host "  No commits in last $daysBack days" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Pop-Location
    }
    
    Write-Host ""
}

if ($reposToFix.Count -eq 0) {
    Write-Host "=== NO COMMITS NEED FIXING ===" -ForegroundColor Green
    Write-Host "All commits from the last $daysBack days already have correct email/name!" -ForegroundColor Cyan
    exit 0
}

Write-Host "=== SUMMARY ===" -ForegroundColor Green
Write-Host "Repositories with commits to fix: $($reposToFix.Count)" -ForegroundColor Yellow
$totalCommits = ($reposToFix | ForEach-Object { $_.Commits.Count } | Measure-Object -Sum).Sum
Write-Host "Total commits to fix: $totalCommits" -ForegroundColor Yellow
Write-Host ""

Write-Host "Repositories that will be fixed:" -ForegroundColor Cyan
foreach ($repo in $reposToFix) {
    Write-Host "  - $($repo.Name): $($repo.Commits.Count) commits" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== WARNING ===" -ForegroundColor Red
Write-Host "This will amend commits and require FORCE PUSH!" -ForegroundColor Red
Write-Host "Make sure:" -ForegroundColor Yellow
Write-Host "  1. You have backups of your work" -ForegroundColor Gray
Write-Host "  2. No one else is working on these repositories" -ForegroundColor Gray
Write-Host "  3. You understand this will rewrite git history" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Type 'YES' to proceed with fixing all commits"

if ($confirm -ne "YES") {
    Write-Host "Cancelled. No changes made." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== FIXING COMMITS ===" -ForegroundColor Green

foreach ($repo in $reposToFix) {
    Write-Host ""
    Write-Host "Fixing: $($repo.Name)" -ForegroundColor Cyan
    Write-Host "Path: $($repo.Path)" -ForegroundColor Gray
    
    Push-Location $repo.Path
    
    try {
        # Get current branch
        $branch = git rev-parse --abbrev-ref HEAD
        
        Write-Host "  Current branch: $branch" -ForegroundColor Yellow
        
        # Get all commits from last 7 days that need fixing
        $sinceDate = (Get-Date).AddDays(-$daysBack).ToString("yyyy-MM-dd")
        $allCommits = git log --since="$sinceDate" --format="%H|%an|%ae" --all --reverse
        
        $commitsToAmend = @()
        foreach ($commitLine in $allCommits) {
            $parts = $commitLine -split '\|'
            if ($parts.Length -ge 3) {
                $hash = $parts[0]
                $name = $parts[1]
                $email = $parts[2]
                
                if ($wrongEmails -contains $email -or $wrongNames -contains $name) {
                    $commitsToAmend += $hash
                }
            }
        }
        
        if ($commitsToAmend.Count -eq 0) {
            Write-Host "  No commits to fix (already processed?)" -ForegroundColor Gray
            continue
        }
        
        Write-Host "  Found $($commitsToAmend.Count) commits to amend" -ForegroundColor Yellow
        
        # Use git filter-branch or interactive rebase
        # For safety, we'll use interactive rebase approach
        # First, get the first commit hash that needs fixing
        $firstBadCommit = $commitsToAmend[0]
        
        # Get the parent of the first bad commit
        $parentCommit = git rev-parse "$firstBadCommit^"
        
        Write-Host "  Starting interactive rebase from: $($parentCommit.Substring(0, 7))" -ForegroundColor Yellow
        
        # Set GIT_SEQUENCE_EDITOR to automatically mark commits for editing
        $env:GIT_SEQUENCE_EDITOR = "sed -i 's/^pick/edit/g'"
        
        # For Windows, we'll use a different approach - amend each commit individually
        # This is safer and more reliable
        
        # Get list of commits in reverse order (oldest first)
        $commitsInOrder = git log --since="$sinceDate" --format="%H" --reverse
        
        $amendedCount = 0
        foreach ($commitHash in $commitsInOrder) {
            $commitInfo = git log -1 --format="%an|%ae" $commitHash
            $parts = $commitInfo -split '\|'
            if ($parts.Length -ge 2) {
                $name = $parts[0]
                $email = $parts[1]
                
                if ($wrongEmails -contains $email -or $wrongNames -contains $name) {
                    # Checkout this commit
                    git checkout $commitHash --quiet
                    
                    # Amend with correct author
                    git commit --amend --author="$correctName <$correctEmail>" --no-edit --quiet
                    
                    $amendedCount++
                    Write-Host "    Fixed commit: $($commitHash.Substring(0, 7))" -ForegroundColor Green
                }
            }
        }
        
        # Return to original branch
        git checkout $branch --quiet
        
        if ($amendedCount -gt 0) {
            Write-Host "  Fixed $amendedCount commits" -ForegroundColor Green
            Write-Host "  WARNING: You need to force push: git push origin $branch --force" -ForegroundColor Red
        } else {
            Write-Host "  No commits needed fixing" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Skipping this repository" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Green
Write-Host "Remember to force push each repository:" -ForegroundColor Yellow
Write-Host "  git push origin <branch> --force" -ForegroundColor Cyan
Write-Host ""
Write-Host "Be careful with force push - make sure no one else is working on these repos!" -ForegroundColor Red

