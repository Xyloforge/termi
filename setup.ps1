param (
    [switch]$install,
    [switch]$uninstall,
    [switch]$update,
    [switch]$vscode
)

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = "$HOME\.config"
$ProfilePath = $PROFILE

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-ErrorMsg { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Find-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return $true }
    return $false
}

function Install-Core {
    Write-Info "Starting Termi Native Windows setup..."

    if (-not (Find-Winget)) {
        Write-ErrorMsg "Winget is not installed. Please install Winget to proceed."
        exit 1
    }

    Write-Info "Installing packages via Winget..."
    $packages = @(
        "Alacritty.Alacritty",
        "junegunn.fzf",
        "sharkdp.bat",
        "ajeetdsouza.zoxide",
        "JanDeDobbeleer.OhMyPosh"
    )

    foreach ($pkg in $packages) {
        Write-Info "Checking $pkg..."
        winget install --id $pkg --exact --accept-package-agreements --accept-source-agreements --silent
    }

    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
    $fontZip = "$env:TEMP\JetBrainsMono.zip"
    $fontDir = "$env:TEMP\JetBrainsMono"
    
    if (-not (Test-Path "C:\Windows\Fonts\JetBrainsMonoNerdFont-Regular.ttf")) {
        Write-Info "Downloading JetBrainsMono Nerd Font..."
        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
        Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
        
        Write-Info "Installing Font..."
        $fonts = @("JetBrainsMonoNerdFont-Regular.ttf", "JetBrainsMonoNerdFont-Bold.ttf", "JetBrainsMonoNerdFont-Italic.ttf")
        foreach ($font in $fonts) {
            $dest = "C:\Windows\Fonts\$font"
            if (-not (Test-Path $dest)) {
                Copy-Item "$fontDir\$font" $dest -ErrorAction SilentlyContinue
                try {
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $font -Value $font -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Warn "Could not write font into registry. Please run as Administrator if font fails to load."
                }
            }
        }
        Write-Success "Font Installed."
    } else {
        Write-Info "JetBrainsMono Nerd Font already installed."
    }

    Write-Info "Linking custom configurations..."
    
    $alacrittyConfigDir = "$HOME\.config\alacritty"
    if (-not (Test-Path $alacrittyConfigDir)) { New-Item -ItemType Directory -Path $alacrittyConfigDir -Force | Out-Null }
    
    Copy-Item -Path "$RepoDir\config\alacritty\alacritty_common.toml" -Destination "$alacrittyConfigDir\alacritty_common.toml" -Force
    Copy-Item -Path "$RepoDir\config\alacritty\catppuccin-mocha.toml" -Destination "$alacrittyConfigDir\catppuccin-mocha.toml" -Force
    
    $nativeConfigContent = "[general]`nimport = [`"~/.config/alacritty/alacritty_common.toml`"]`n`n[shell]`nprogram = `"powershell.exe`"`nargs = [`"-NoLogo`"]`n`n[keyboard]`nbindings = [`n    { key = `"C`", mods = `"Control|Shift`", action = `"Copy`" },`n    { key = `"V`", mods = `"Control|Shift`", action = `"Paste`" },`n    { key = `"Plus`", mods = `"Control`", action = `"IncreaseFontSize`" },`n    { key = `"Minus`", mods = `"Control`", action = `"DecreaseFontSize`" },`n    { key = `"Key0`", mods = `"Control`", action = `"ResetFontSize`" },`n    { key = `"N`", mods = `"Alt`", action = `"ToggleFullscreen`" }`n]"
    Set-Content -Path "$alacrittyConfigDir\alacritty.toml" -Value $nativeConfigContent -Force

    Write-Info "Configuring PowerShell features (Theme, PSReadLine, Zoxide)..."
    $profileDir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Path $ProfilePath -Force | Out-Null }

    $profileContent = Get-Content $ProfilePath -Raw
    if ($profileContent -match "Termi Native Features") {
        Write-Info "PowerShell profile already configured."
    } else {
        $snippetRows = @(
            "",
            "# ==========================================",
            "# Termi Native Features",
            "# ==========================================",
            "",
            "# 1. Oh My Posh Theme (Catppuccin Mocha)",
            "if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {",
            "    oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json' | Invoke-Expression",
            "}",
            "",
            "# 2. PSReadLine for Syntax Highlighting and Autosuggestions",
            "Import-Module PSReadLine",
            "Set-PSReadLineOption -PredictionSource History",
            "Set-PSReadLineOption -Colors @{",
            "    Command = 'Cyan'",
            "    Parameter = 'Green'",
            "    Operator = 'Magenta'",
            "    Variable = 'Yellow'",
            "    String = 'Blue'",
            "    Number = 'Red'",
            "}",
            "",
            "# 3. Zoxide (Smarter cd)",
            "if (Get-Command zoxide -ErrorAction SilentlyContinue) {",
            "    Invoke-Expression (& { (zoxide init powershell | Out-String) })",
            "}",
            "",
            "# 4. Aliases (matching Zsh setup)",
            "Set-Alias -Name top -Value btop -ErrorAction SilentlyContinue",
            "Set-Alias -Name monitor -Value btop -ErrorAction SilentlyContinue",
            "Set-Alias -Name process -Value btop -ErrorAction SilentlyContinue",
            "",
            "function _ccat_func {",
            "    param([string]`$File)",
            "    Get-Content `$File | Set-Clipboard",
            "    Write-Host '[SUCCESS] Copied to clipboard!'",
            "}",
            "Set-Alias -Name ccat -Value _ccat_func",
            "",
            "function killport {",
            "    param([string]`$Port)",
            "    if (-not `$Port) { Write-Host 'Usage: killport port_number'; return }",
            "    `$Pids = (Get-NetTCPConnection -LocalPort `$Port -ErrorAction SilentlyContinue).OwningProcess",
            "    if (-not `$Pids) { Write-Host `"No process running on port `$Port`" }",
            "    else {",
            "        Write-Host `"Killing processes [`$Pids] running on port `$Port...`"",
            "        Stop-Process -Id `$Pids -Force",
            "        Write-Host 'Done!'",
            "    }",
            "}"
        )
        $snippet = $snippetRows -join "`n"
        Add-Content -Path $ProfilePath -Value $snippet
        Write-Success "Added Termi features to PowerShell profile."
    }
    
    Write-Info "Note: Tmux is ignored as it's not natively supported on Windows PowerShell."

    Write-Success "Setup complete! Restart PowerShell or launch Alacritty."
}

function Uninstall-Core {
    Write-Info "Starting uninstallation..."
    
    $alacrittyConfigDir = "$HOME\.config\alacritty"
    if (Test-Path $alacrittyConfigDir) {
        Remove-Item -Recurse -Force $alacrittyConfigDir
        Write-Success "Removed Alacritty configuration."
    }
    
    if (Test-Path $ProfilePath) {
        $profileContent = Get-Content $ProfilePath -Raw
        $profileContent = $profileContent -replace '(?s)\n# ==========================================\n# Termi Native Features.*', ''
        Set-Content -Path $ProfilePath -Value $profileContent
        Write-Success "Removed Termi features from PowerShell profile."
    }

    Write-Success "Uninstallations complete. Winget packages were left untouched."
}

function Update-Core {
    Write-Info "Updating Termi configuration..."
    Install-Core
}

function Install-VSCode {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-ErrorMsg "VS Code 'code' command not found."
        return
    }

    Write-Info "Installing VS Code Extensions..."
    code --install-extension Catppuccin.catppuccin-vsc
    code --install-extension PKief.material-icon-theme

    Write-Success "VS Code extensions installed."
}

if ($install) {
    Install-Core
} elseif ($uninstall) {
    Uninstall-Core
} elseif ($update) {
    Update-Core
} elseif ($vscode) {
    Install-VSCode
} else {
    Write-Host "Usage: .\setup.ps1 -install | -uninstall | -update | -vscode"
}
