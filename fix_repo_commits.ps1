# Script to fix commits in a specific repository
# Usage: .\fix_repo_commits.ps1 <repo-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoPath
)

$correctEmail = "benjanusevicius@gmail.com"
$correctName = "benasja"

if (-not (Test-Path "$RepoPath\.git")) {
    Write-Host "ERROR: Not a git repository: $RepoPath" -ForegroundColor Red
    exit 1
}

Write-Host "=== Fixing Commits in Repository ===" -ForegroundColor Green
Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host ""

Push-Location $RepoPath

try {
    # Check current branch
    $branch = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $branch" -ForegroundColor Yellow
    
    # Check if there are commits with wrong email/name
    $wrongCommits = git log --all --format="%H|%an|%ae" | Where-Object {
        $_ -match "benjanusevicvius" -or $_ -match "^[^|]*\|Benas\|"
    }
    
    if (-not $wrongCommits) {
        Write-Host "No commits found with wrong email/name!" -ForegroundColor Green
        exit 0
    }
    
    $count = ($wrongCommits | Measure-Object).Count
    Write-Host "Found $count commits with wrong email/name" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "This will rewrite git history using filter-branch..." -ForegroundColor Yellow
    Write-Host "WARNING: This requires force push!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Type 'YES' to proceed"
    
    if ($confirm -ne "YES") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    # Use git filter-branch to fix all commits
    $filterScript = @"
if [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmail.com' ] || [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmai.com' ]; then
  export GIT_COMMITTER_EMAIL='benjanusevicius@gmail.com'
  export GIT_COMMITTER_NAME='benasja'
fi
if [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmail.com' ] || [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmai.com' ]; then
  export GIT_AUTHOR_EMAIL='benjanusevicius@gmail.com'
  export GIT_AUTHOR_NAME='benasja'
fi
if [ `$GIT_COMMITTER_NAME = 'Benas' ]; then
  export GIT_COMMITTER_NAME='benasja'
fi
if [ `$GIT_AUTHOR_NAME = 'Benas' ]; then
  export GIT_AUTHOR_NAME='benasja'
fi
"@
    
    Write-Host "Running git filter-branch..." -ForegroundColor Yellow
    
    # Save filter script to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    $filterScript | Out-File -FilePath $tempFile -Encoding ASCII
    
    # Run filter-branch
    $env:GIT_AUTHOR_NAME = $correctName
    $env:GIT_AUTHOR_EMAIL = $correctEmail
    $env:GIT_COMMITTER_NAME = $correctName
    $env:GIT_COMMITTER_EMAIL = $correctEmail
    
    git filter-branch -f --env-filter "`$env:GIT_AUTHOR_NAME='$correctName'; `$env:GIT_AUTHOR_EMAIL='$correctEmail'; `$env:GIT_COMMITTER_NAME='$correctName'; `$env:GIT_COMMITTER_EMAIL='$correctEmail'; if (`$env:GIT_AUTHOR_EMAIL -eq 'benjanusevicvius@gmail.com' -or `$env:GIT_AUTHOR_EMAIL -eq 'benjanusevicvius@gmai.com') { `$env:GIT_AUTHOR_EMAIL='$correctEmail'; `$env:GIT_AUTHOR_NAME='$correctName' }; if (`$env:GIT_COMMITTER_EMAIL -eq 'benjanusevicvius@gmail.com' -or `$env:GIT_COMMITTER_EMAIL -eq 'benjanusevicvius@gmai.com') { `$env:GIT_COMMITTER_EMAIL='$correctEmail'; `$env:GIT_COMMITTER_NAME='$correctName' }" --tag-name-filter cat -- --branches --tags
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "=== COMPLETE ===" -ForegroundColor Green
    Write-Host "All commits have been fixed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To push the changes, run:" -ForegroundColor Yellow
    Write-Host "  git push origin --all --force" -ForegroundColor Red
    Write-Host ""
    Write-Host "WARNING: Force push will overwrite remote history!" -ForegroundColor Red
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

