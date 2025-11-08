# Script to fix all commits in html-pdf repository with wrong email/name

$correctEmail = "benjanusevicius@gmail.com"
$correctName = "benasja"

Write-Host "=== Fixing All Commits in html-pdf Repository ===" -ForegroundColor Green
Write-Host "This will rewrite git history to fix email/name in all commits" -ForegroundColor Yellow
Write-Host ""

# Check if we're in a git repo
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not in a git repository!" -ForegroundColor Red
    Write-Host "Please run this script from the html-pdf repository directory" -ForegroundColor Yellow
    exit 1
}

# Count commits that need fixing
$wrongCommits = git log --all --format="%H|%an|%ae" | Where-Object {
    $_ -match "benjanusevicvius" -or $_ -match "^[^|]*\|Benas\|"
}

$count = ($wrongCommits | Measure-Object).Count
Write-Host "Found $count commits with wrong email/name" -ForegroundColor Yellow
Write-Host ""

if ($count -eq 0) {
    Write-Host "No commits need fixing!" -ForegroundColor Green
    exit 0
}

Write-Host "WARNING: This will rewrite git history!" -ForegroundColor Red
Write-Host "1. Make sure you have backups" -ForegroundColor Yellow
Write-Host "2. Make sure no one else is working on this repo" -ForegroundColor Yellow
Write-Host "3. This requires force push after completion" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Type 'YES' to proceed with fixing all commits"

if ($confirm -ne "YES") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Running git filter-branch..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray
Write-Host ""

# Use git filter-branch to fix all commits
# For Windows PowerShell, we need to use a different approach
# We'll use git filter-branch with a bash script

$filterScript = @"
#!/bin/bash
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

# Save filter script to temp file
$tempFile = [System.IO.Path]::GetTempFileName() + ".sh"
$filterScript | Out-File -FilePath $tempFile -Encoding ASCII -NoNewline

try {
    # Check if we have bash (Git Bash or WSL)
    $bashPath = $null
    if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
        $bashPath = "C:\Program Files\Git\bin\bash.exe"
    } elseif (Test-Path "C:\Program Files (x86)\Git\bin\bash.exe") {
        $bashPath = "C:\Program Files (x86)\Git\bin\bash.exe"
    } elseif (Get-Command wsl -ErrorAction SilentlyContinue) {
        $bashPath = "wsl"
    }
    
    if ($bashPath) {
        Write-Host "Using bash: $bashPath" -ForegroundColor Cyan
        
        # Make script executable (for WSL)
        if ($bashPath -eq "wsl") {
            wsl chmod +x $tempFile
        }
        
        # Run filter-branch using bash
        $env:GIT_AUTHOR_NAME = $correctName
        $env:GIT_AUTHOR_EMAIL = $correctEmail
        $env:GIT_COMMITTER_NAME = $correctName
        $env:GIT_COMMITTER_EMAIL = $correctEmail
        
        # Use git filter-branch with the script
        & $bashPath -c "git filter-branch -f --env-filter 'source $tempFile' --tag-name-filter cat -- --branches --tags"
        
    } else {
        # Fallback: Use PowerShell-based approach
        Write-Host "Bash not found. Using PowerShell-based approach..." -ForegroundColor Yellow
        Write-Host "This is a simplified version that may not catch all cases." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "For best results, install Git Bash and run:" -ForegroundColor Cyan
        Write-Host "  git filter-branch -f --env-filter \"`" -ForegroundColor White
        Write-Host "    if [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmail.com' ] || [ `$GIT_COMMITTER_EMAIL = 'benjanusevicvius@gmai.com' ]; then" -ForegroundColor White
        Write-Host "      export GIT_COMMITTER_EMAIL='benjanusevicius@gmail.com'" -ForegroundColor White
        Write-Host "      export GIT_COMMITTER_NAME='benasja'" -ForegroundColor White
        Write-Host "    fi" -ForegroundColor White
        Write-Host "    if [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmail.com' ] || [ `$GIT_AUTHOR_EMAIL = 'benjanusevicvius@gmai.com' ]; then" -ForegroundColor White
        Write-Host "      export GIT_AUTHOR_EMAIL='benjanusevicius@gmail.com'" -ForegroundColor White
        Write-Host "      export GIT_AUTHOR_NAME='benasja'" -ForegroundColor White
        Write-Host "    fi" -ForegroundColor White
        Write-Host "    if [ `$GIT_COMMITTER_NAME = 'Benas' ]; then" -ForegroundColor White
        Write-Host "      export GIT_COMMITTER_NAME='benasja'" -ForegroundColor White
        Write-Host "    fi" -ForegroundColor White
        Write-Host "    if [ `$GIT_AUTHOR_NAME = 'Benas' ]; then" -ForegroundColor White
        Write-Host "      export GIT_AUTHOR_NAME='benasja'" -ForegroundColor White
        Write-Host "    fi" -ForegroundColor White
        Write-Host "  `" --tag-name-filter cat -- --branches --tags" -ForegroundColor White
        Write-Host ""
        Write-Host "Or use the manual command above in Git Bash." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
    Write-Host "=== COMPLETE ===" -ForegroundColor Green
    Write-Host "All commits have been fixed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To push the changes, run:" -ForegroundColor Yellow
    Write-Host "  git push origin --all --force" -ForegroundColor Red
    Write-Host ""
    Write-Host "WARNING: Force push will overwrite remote history!" -ForegroundColor Red
    Write-Host "Make sure no one else is working on this repository!" -ForegroundColor Red
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can manually run the git filter-branch command:" -ForegroundColor Yellow
    Write-Host "See the command above in the error message" -ForegroundColor Gray
} finally {
    # Clean up temp file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

