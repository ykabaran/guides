# List of directories containing the projects
$baseDirectory = "C:\Users\user\Documents\projects"
$directories = @(
    "app_tools\app_tools",
#    "app_tools\app_tools_test",
    "app_tools\app_user_tools",
    "app_tools\app_accounting",
#    "lsports\lsports_main",
#    "goalserve\goalserve_main",
#    "Admin2024\hlbs_sport",
#    "Admin2024\hls_sport",
    "Admin2024\hls_game",
    "Admin2024\Admin2024_api",
    "app_tools\app_diagnostics_client"
)

# Loop through each directory
foreach ($relativeDir in $directories) {
    $dir = Join-Path -Path $baseDirectory -ChildPath $relativeDir

    if (Test-Path $dir) {
        Set-Location -Path $dir
        code .
    } else {
        Write-Host "Directory does not exist: $dir" -ForegroundColor Red
    }
}

# Return to the original location
Set-Location -Path (Get-Location -PSProvider FileSystem).Path