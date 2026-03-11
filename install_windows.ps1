# Termi Windows Installer (PowerShell)
# Automates Setup for Option 1: Lightweight WSL (Alpine Linux) + Windows Alacritty

Write-Host "🚀 Starting Termi Windows Setup..." -ForegroundColor Cyan

# Check for Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠️  Please run this script as Administrator!" -ForegroundColor Red
    exit 1
}

# 1. Install Alpine WSL
Write-Host "🐧 checking for WSL (Alpine)..." -ForegroundColor Green
if (-not (wsl -l -v | Select-String "Alpine")) {
    Write-Host "   - Installing Alpine Linux..."
    wsl --install -d Alpine
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install WSL. You might need to enable 'Virtual Machine Platform' feature and reboot first." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   - Alpine already installed."
}

# 2. Install Alacritty (Windows)
Write-Host "🖥️  Checking for Alacritty..." -ForegroundColor Green
if (-not (Get-Command alacritty -ErrorAction SilentlyContinue)) {
    Write-Host "   - Installing Alacritty via Winget..."
    winget install --id Alacritty.Alacritty -e --source winget
} else {
    Write-Host "   - Alacritty already installed."
}

# 3. Install JetBrains Nerd Font
Write-Host "A  Checking for Nerd Font..." -ForegroundColor Green
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
$fontZip = "$env:TEMP\JetBrainsMono.zip"
$fontDir = "$env:TEMP\JetBrainsMono"

if (-not (Test-Path "C:\Windows\Fonts\JetBrainsMonoNerdFont-Regular.ttf")) {
    Write-Host "   - Downloading JetBrainsMono Nerd Font..."
    Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
    
    Write-Host "   - Installing Font..."
    $fonts = @("JetBrainsMonoNerdFont-Regular.ttf", "JetBrainsMonoNerdFont-Bold.ttf", "JetBrainsMonoNerdFont-Italic.ttf")
    foreach ($font in $fonts) {
        Copy-Item "$fontDir\$font" "C:\Windows\Fonts"
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $font -Value $font -Force | Out-Null
    }
    Write-Host "   - Font Installed."
} else {
    Write-Host "   - Font already installed."
}

# 4. Configure Alacritty (Windows Side)
Write-Host "🔗 Linking Windows Alacritty Config..." -ForegroundColor Green
$appData = $env:APPDATA
$alacrittyConfigDir = "$appData\alacritty"
$repoDir = Get-Location

if (-not (Test-Path $alacrittyConfigDir)) {
    New-Item -ItemType Directory -Path $alacrittyConfigDir | Out-Null
}

# Create Symlinks for Configs
# Note: On Windows, use Copy-Item or New-Item -ItemType SymbolicLink. Ideally SymbolicLink requires developer mode or admin.
# We are admin, so SymbolicLink should work.

function Create-Link {
    param ($target, $link)
    if (Test-Path $link) { Remove-Item $link -Force }
    New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null
    Write-Host "   - Linked $link -> $target"
}

Create-Link "$repoDir\config\alacritty\alacritty_windows.toml" "$alacrittyConfigDir\alacritty.toml"
Create-Link "$repoDir\config\alacritty\alacritty_common.toml" "$alacrittyConfigDir\alacritty_common.toml"
Create-Link "$repoDir\config\alacritty\catppuccin-mocha.toml" "$alacrittyConfigDir\catppuccin-mocha.toml"

# 5. Bootstrap Alpine Environment
Write-Host "🔧 Bootstrapping Alpine Environment..." -ForegroundColor Green
# We need to map the current windows path to WSL path /mnt/c/...
# Remove "C:" and replace "\" with "/"
$currentPath = $repoDir -replace "C:", "/mnt/c" -replace "\\", "/"
$wslSetupCommand = "cd '$currentPath' && chmod +x setup.sh && ./setup.sh install"

Write-Host "   - Running setup.sh inside Alpine..."
wsl -d Alpine -e sh -c $wslSetupCommand

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Cyan
Write-Host "   1. Restart your terminal or launch Alacritty."
Write-Host "   2. If fonts look wrong, reboot Windows."
