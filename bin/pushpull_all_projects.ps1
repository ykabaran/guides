# Parameters
param(
    [switch] $PushAfterPull = $false,
    [string] $CommitMessage = "auto-commit"
)

# List of directories containing git repositories
$baseDirectory = "C:\Users\user\Documents\projects"
$directories = @(
    "guides",
    "app_tools\app_tools",
    "app_tools\app_tools_test",
    "app_tools\app_user_tools",
    "app_tools\app_accounting",
    "app_tools\app_diagnostics_client",
    "lsports\lsports_main",
    "goalserve\goalserve_main",
    "Admin2024\hlbs_sport",
    "Admin2024\hls_sport",
    "Admin2024\hls_game",
    "Admin2024\Admin2024_api",
    "Admin2024\Admin2024"
)

# Loop through each directory
foreach ($relativeDir in $directories) {
    $dir = Join-Path -Path $baseDirectory -ChildPath $relativeDir

    if (Test-Path $dir) {
        Write-Host "Processing directory: $relativeDir" -ForegroundColor Green
        Set-Location -Path $dir

        if ($PushAfterPull) {
            # Stage changes
            $stageOutput = git add --all 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Staged changes in: $relativeDir" -ForegroundColor Cyan
            } else {
                Write-Host "Failed to stage changes in: $relativeDir" -ForegroundColor Red
                Write-Host $stageOutput -ForegroundColor Yellow
                continue
            }

            # Commit changes
            $commitOutput = git commit -am $CommitMessage 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Committed changes in: $relativeDir" -ForegroundColor Cyan
            } else {
                Write-Host "No changes to commit in: $relativeDir" -ForegroundColor Yellow
            }
        }

        # Execute git pull
        $pullOutput = git pull 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully pulled updates for: $relativeDir" -ForegroundColor Cyan
        } else {
            Write-Host "Failed to pull updates for: $relativeDir" -ForegroundColor Red
            Write-Host $pullOutput -ForegroundColor Yellow
        }

        if ($PushAfterPull) {
            # Execute git push
            $pushOutput = git push 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully pushed changes for: $relativeDir" -ForegroundColor Cyan
            } else {
                Write-Host "Failed to push changes for: $relativeDir" -ForegroundColor Red
                Write-Host $pushOutput -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Directory does not exist: $dir" -ForegroundColor Red
    }
}

# Return to the original location
Set-Location -Path (Get-Location -PSProvider FileSystem).Path