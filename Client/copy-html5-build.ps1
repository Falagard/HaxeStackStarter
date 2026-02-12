# Post-build script
$sourceDir = "Export\html5\bin"
$destinations = @(
    "..\Server\static\client",
    "..\Server\Export\hl\bin\static\client",
    "..\Server\Export\hlc\bin\static\client"
)

foreach ($destDir in $destinations) {
    # Ensure destination directory exists
    if (-Not (Test-Path $destDir)) { 
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null 
    }

    # Delete existing files and directories in destination
    Get-ChildItem -Path $destDir -Recurse | Remove-Item -Force -Recurse
    Write-Host "Cleaned destination directory: $destDir" -ForegroundColor Yellow

    # Copy new build
    Copy-Item -Path "$sourceDir\*" -Destination $destDir -Recurse -Force
    Write-Host "Copied HTML5 build to: $destDir" -ForegroundColor Green
}
