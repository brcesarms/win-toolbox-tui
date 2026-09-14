<#
.SYNOPSIS
    WIN-TOOLBOX-TUI V1.0 — Caixa de Ferramentas e Pós-Instalação para Windows 11
.DESCRIPTION
    Script interativo com interface TUI moderna (Unicode Box Drawing), múltiplos menus,
    status dinâmico de instalação em tempo real ([✓] Verde / [ ] Branco), títulos em negrito ANSI,
    janela de execução desacoplada (sem poluir o menu), telemetria de rede e suporte nativo ao Windows Terminal.
    Exclusivo para Windows 11 (Build 22000+).
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    1.4.0 — Decoupled Execution Window, Zero-Scroll Menu & Native Progress (Windows 11)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string]$ExecutarLote = "",
    [Parameter(Mandatory=$false)] [switch]$JanelaFilha
)

# Configuração de codificação UTF-8 para suporte a caracteres Unicode
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================================
# 1. VERIFICAÇÃO DE ELEVAÇÃO (ADMINISTRADOR)
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host "`n[!] Privilégios de Administrador são necessários." -ForegroundColor Yellow
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        # Modo one-liner (irm | iex): o script não existe como arquivo local e não pode se auto-elevar.
        Write-Host "[!] Modo one-liner detectado: o script não pode se auto-elevar por não existir como arquivo." -ForegroundColor Red
        Write-Host "[*] Feche este PowerShell, abra o PowerShell COMO ADMINISTRADOR e execute novamente:" -ForegroundColor Cyan
        Write-Host "    irm https://raw.githubusercontent.com/brcesarms/win-toolbox-tui/main/win-toolbox.ps1 | iex" -ForegroundColor Yellow
        Pause
        Exit 1
    }
    Write-Host "[*] Reiniciando com elevação de privilégios...`n" -ForegroundColor Cyan
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if (-not [string]::IsNullOrEmpty($ExecutarLote)) { $argList += " -ExecutarLote `"$ExecutarLote`"" }
    if ($JanelaFilha) { $argList += " -JanelaFilha" }
    Start-Process powershell.exe $argList -Verb RunAs
    Exit
}

# ==============================================================================
# 2. VALIDAÇÃO EXCLUSIVA DE WINDOWS 11
# ==============================================================================
$osBuild = [Environment]::OSVersion.Version.Build
if ($osBuild -lt 22000) {
    Write-Host "`n[ERRO CRÍTICO] Este script foi projetado EXCLUSIVAMENTE para o Windows 11." -ForegroundColor Red
    Write-Host "Versão detectada: Windows Build $osBuild (inferior ao Windows 11 Build 22000)." -ForegroundColor Yellow
    Write-Host "Execução abortada por segurança.`n" -ForegroundColor Red
    Pause
    Exit 1
}

# ==============================================================================
# 3. CABEÇALHO E BARRA DE PROGRESSO DINÂMICA
# ==============================================================================
function Show-Header {
    param([string]$subtitulo = "MENU PRINCIPAL")
    Clear-Host

    $data = (Get-Date).ToString("dd/MM/yyyy")

    # Obter o IPv4 principal ativo da máquina
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
        $_.IPAddress -ne "127.0.0.1" -and 
        $_.IPAddress -notlike "169.254*" -and 
        $_.InterfaceAlias -notlike "*Loopback*" -and
        $_.InterfaceAlias -notlike "*vEthernet*"
    } | Select-Object -ExpandProperty IPAddress -First 1)

    if ([string]::IsNullOrWhiteSpace($ip)) { $ip = "N/A" }

    $esc = [char]27
    $norm = "$esc[22m"
    $reset = "$esc[0m"

    Write-Host "╭─ WIN-TOOLBOX-TUI V1.0 ──────────────────────────────────────────────── [ WINDOWS 11 ] ─╮" -ForegroundColor Cyan
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + " TELA: $subtitulo".PadRight(88) + "$reset") -NoNewline -ForegroundColor Cyan
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + " Data: $data  |  Computador: $env:computername  |  Usuario: $env:username  |  IP: $ip".PadRight(88) + "$reset") -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
}


function Wait-User {
    Write-Host "`n[Pressione ENTER para continuar...]" -ForegroundColor DarkGray
    $null = Read-Host
}

# ==============================================================================
# 4. CACHE DE DETECÇÃO, RENDERIZADORES TUI & WINGET
# ==============================================================================
$script:InstalledCache = @{}

function Test-IsInstalled {
    param([string]$key)
    
    if ($script:InstalledCache.ContainsKey($key)) {
        return $script:InstalledCache[$key]
    }
    
    $result = $false
    try {
        switch ($key) {
            "7zip"            { $result = (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") -or (Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe") }
            "winrar"          { $result = (Test-Path "$env:ProgramFiles\WinRAR\WinRAR.exe") }
            "adobe"           { $result = (Test-Path "$env:ProgramFiles\Adobe\Acrobat DC\Acrobat\Acrobat.exe") -or (Test-Path "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe") }
            "foxit"           { $result = (Test-Path "${env:ProgramFiles(x86)}\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") -or (Test-Path "$env:ProgramFiles\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") }
            "libreoffice"     { $result = (Test-Path "$env:ProgramFiles\LibreOffice\program\soffice.exe") }
            "gimp"            { $result = (Test-Path "$env:ProgramFiles\GIMP 2\bin\gimp-2.10.exe") -or (Test-Path "$env:ProgramFiles\GIMP 3\bin\gimp.exe") }
            "lightshot"       { $result = (Test-Path "${env:ProgramFiles(x86)}\Skillbrains\Lightshot\Lightshot.exe") }
            "sharex"          { $result = (Test-Path "$env:ProgramFiles\ShareX\ShareX.exe") }
            "handbrake"       { $result = (Test-Path "$env:ProgramFiles\HandBrake\HandBrake.exe") }
            "klite"           { $result = (Test-Path "HKLM:\SOFTWARE\KLiteCodecPack") -or (Test-Path "HKLM:\SOFTWARE\WOW6432Node\KLiteCodecPack") -or (Test-Path "${env:ProgramFiles(x86)}\K-Lite Codec Pack") }
            "vlc"             { $result = (Test-Path "$env:ProgramFiles\VideoLAN\VLC\vlc.exe") }
            "dotnet8"         { $result = (Test-Path "$env:ProgramFiles\dotnet\shared\Microsoft.WindowsDesktop.App\8.*") }
            "dotnet9"         { $result = (Test-Path "$env:ProgramFiles\dotnet\shared\Microsoft.WindowsDesktop.App\9.*") }
            "vcredist_x64"    { $result = (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64") }
            "vcredist_x86"    { $result = (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86") }
            "vcredist_all"    { $result = (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64") -and (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86") }
            "temurin17jre"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jre-17*") }
            "anydesk"         { $result = (Test-Path "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe") }
            "qbittorrent"     { $result = (Test-Path "$env:ProgramFiles\qBittorrent\qbittorrent.exe") }
            "rufus"           { $result = (Test-Path "$env:LOCALAPPDATA\Programs\Rufus\rufus.exe") -or (Test-Path "$env:ProgramFiles\Rufus\rufus.exe") }
            "rustdesk"        { $result = (Test-Path "$env:ProgramFiles\RustDesk\rustdesk.exe") }
            "transmission"    { $result = (Test-Path "$env:ProgramFiles\Transmission\transmission-qt.exe") }
            "realvnc"         { $result = (Test-Path "$env:ProgramFiles\RealVNC\VNC Viewer\vncviewer.exe") }
            "vscode"          { $result = (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -or (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe") }
            "notepadplusplus" { $result = (Test-Path "$env:ProgramFiles\Notepad++\notepad++.exe") }
            "vs2022"          { $result = (Test-Path "$env:ProgramFiles\Microsoft Visual Studio\2022") }
            "androidstudio"   { $result = (Test-Path "$env:ProgramFiles\Android\Android Studio\bin\studio64.exe") }
            "git"             { $result = (Test-Path "$env:ProgramFiles\Git\bin\git.exe") -or ((Get-Command git -ErrorAction SilentlyContinue) -ne $null) }
            "xampp"           { $result = (Test-Path "C:\xampp\xampp-control.exe") }
            "temurin8jdk"     { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-8*") }
            "temurin11jdk"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-11*") }
            "temurin17jdk"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-17*") }
            "temurin21jdk"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-21*") }
            "admin500"        { $result = ((Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID -like "*-500" -and $_.Enabled -eq $true }) -ne $null) }
            "sshd"            { $result = ((Get-Service sshd -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }) -ne $null) }
            "win11_tweaks"    { $result = (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32") }
            default           { $result = $false }
        }
    } catch {
        $result = $false
    }
    
    $script:InstalledCache[$key] = $result
    return $result
}

function Get-ItemDisplay {
    param(
        [Parameter(Mandatory=$true)] [string]$Key,
        [Parameter(Mandatory=$true)] [string]$Code,
        [Parameter(Mandatory=$true)] [string]$Title
    )
    $isInst = Test-IsInstalled $Key
    if ($isInst) {
        return @{
            Text = " [✓] $Code. $Title"
            Color = "Green"
        }
    } else {
        return @{
            Text = " [ ] $Code. $Title"
            Color = "Gray"
        }
    }
}

function Write-TuiRow3Col {
    param(
        [hashtable]$it1,
        [hashtable]$it2,
        [hashtable]$it3
    )
    $esc = [char]27
    $norm = "$esc[22m"
    $reset = "$esc[0m"

    $t1 = if ($it1 -and $it1.Text) { $it1.Text } else { "" }
    $c1 = if ($it1 -and $it1.Color) { $it1.Color } else { "Gray" }
    
    $t2 = if ($it2 -and $it2.Text) { $it2.Text } else { "" }
    $c2 = if ($it2 -and $it2.Color) { $it2.Color } else { "Gray" }
    
    $t3 = if ($it3 -and $it3.Text) { $it3.Text } else { "" }
    $c3 = if ($it3 -and $it3.Color) { $it3.Color } else { "Gray" }
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + $t1.PadRight(25) + "$reset") -NoNewline -ForegroundColor $c1
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + $t2.PadRight(29) + "$reset") -NoNewline -ForegroundColor $c2
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + $t3.PadRight(32) + "$reset") -NoNewline -ForegroundColor $c3
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiHeader3Col {
    param([string]$h1, [string]$h2, [string]$h3)
    $esc = [char]27
    $bold = "$esc[1;93m"
    $reset = "$esc[0m"
    
    $p1 = $h1.PadRight(25)
    $p2 = $h2.PadRight(29)
    $p3 = $h3.PadRight(32)
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p1$reset" -NoNewline
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p2$reset" -NoNewline
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p3$reset" -NoNewline
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiRowSplit {
    param(
        [hashtable]$it1,
        [hashtable]$it2a,
        [hashtable]$it2b
    )
    $esc = [char]27
    $norm = "$esc[22m"
    $reset = "$esc[0m"

    $t1 = if ($it1 -and $it1.Text) { $it1.Text } else { "" }
    $c1 = if ($it1 -and $it1.Color) { $it1.Color } else { "Gray" }
    
    $t2a = if ($it2a -and $it2a.Text) { $it2a.Text } else { "" }
    $c2a = if ($it2a -and $it2a.Color) { $it2a.Color } else { "Gray" }
    
    $t2b = if ($it2b -and $it2b.Text) { $it2b.Text } else { "" }
    $c2b = if ($it2b -and $it2b.Color) { $it2b.Color } else { "Gray" }
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + $t1.PadRight(25) + "$reset") -NoNewline -ForegroundColor $c1
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + $t2a.PadRight(30) + "$reset") -NoNewline -ForegroundColor $c2a
    Write-Host ("$norm" + $t2b.PadRight(32) + "$reset") -NoNewline -ForegroundColor $c2b
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiHeaderSplit {
    param([string]$h1, [string]$h2)
    $esc = [char]27
    $bold = "$esc[1;93m"
    $reset = "$esc[0m"
    
    $p1 = $h1.PadRight(25)
    $p2 = $h2.PadRight(62)
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p1$reset" -NoNewline
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p2$reset" -NoNewline
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiRow2Col {
    param(
        [hashtable]$it1,
        [hashtable]$it2,
        [string]$title1 = "",
        [string]$title2 = ""
    )
    $esc = [char]27
    $bold = "$esc[1;93m"
    $norm = "$esc[22m"
    $reset = "$esc[0m"
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($title1)) {
        $p1 = $title1.PadRight(40)
        Write-Host "$bold$p1$reset" -NoNewline
    } elseif ($it1 -and $it1.Text) {
        $c1 = if ($it1.Color) { $it1.Color } else { "Gray" }
        Write-Host ("$norm" + $it1.Text.PadRight(40) + "$reset") -NoNewline -ForegroundColor $c1
    } else {
        Write-Host ("".PadRight(40)) -NoNewline -ForegroundColor Gray
    }
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($title2)) {
        $p2 = $title2.PadRight(47)
        Write-Host "$bold$p2$reset" -NoNewline
    } elseif ($it2 -and $it2.Text) {
        $c2 = if ($it2.Color) { $it2.Color } else { "Gray" }
        Write-Host ("$norm" + $it2.Text.PadRight(47) + "$reset") -NoNewline -ForegroundColor $c2
    } else {
        Write-Host ("".PadRight(47)) -NoNewline -ForegroundColor Gray
    }
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiHeader2Col {
    param([string]$h1, [string]$h2)
    $esc = [char]27
    $bold = "$esc[1;93m"
    $reset = "$esc[0m"
    
    $p1 = $h1.PadRight(40)
    $p2 = $h2.PadRight(47)
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p1$reset" -NoNewline
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p2$reset" -NoNewline
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiRowFull {
    param(
        [hashtable]$it,
        [string]$text = "",
        [string]$color = "Gray"
    )
    $esc = [char]27
    $norm = "$esc[22m"
    $reset = "$esc[0m"

    $finalText = if ($it -and $it.Text) { $it.Text } else { $text }
    $finalColor = if ($it -and $it.Color) { $it.Color } else { $color }
    
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("$norm" + $finalText.PadRight(88) + "$reset") -NoNewline -ForegroundColor $finalColor
    Write-Host "│" -ForegroundColor Cyan
}

function Write-TuiHeaderFull {
    param([string]$h)
    $esc = [char]27
    $bold = "$esc[1;93m"
    $reset = "$esc[0m"
    
    $p = $h.PadRight(88)
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host "$bold$p$reset" -NoNewline
    Write-Host "│" -ForegroundColor Cyan
}

function Install-WingetApp {
    param(
        [Parameter(Mandatory=$true)] [string]$idApp,
        [Parameter(Mandatory=$false)] [string]$nomeAmigavel = "",
        [Parameter(Mandatory=$false)] [string]$cacheKey = ""
    )
    if ([string]::IsNullOrWhiteSpace($nomeAmigavel)) { $nomeAmigavel = $idApp }
    
    Write-Host "[*] Verificando: $nomeAmigavel ($idApp)..." -NoNewline -ForegroundColor Gray
    
    if (-not [string]::IsNullOrWhiteSpace($cacheKey) -and (Test-IsInstalled $cacheKey)) {
        Write-Host " [JA INSTALADO]" -ForegroundColor Yellow
        $script:InstalledCache[$cacheKey] = $true
        return
    }

    $check = winget list --id $idApp --exact 2>$null | Select-String $idApp
    if ($check) {
        Write-Host " [JA INSTALADO]" -ForegroundColor Yellow
        if (-not [string]::IsNullOrWhiteSpace($cacheKey)) {
            $script:InstalledCache[$cacheKey] = $true
        }
        return
    }

    Write-Host " [INSTALANDO]" -ForegroundColor Green
    winget install --id $idApp --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[✓] $nomeAmigavel instalado com sucesso!" -ForegroundColor Green
        if (-not [string]::IsNullOrWhiteSpace($cacheKey)) {
            $script:InstalledCache[$cacheKey] = $true
        }
    } else {
        Write-Host "[!] Falha ou aviso ao instalar $nomeAmigavel (Exit Code: $LASTEXITCODE)." -ForegroundColor Yellow
    }
}

function Update-AllWinget {
    Write-Host "`n[*] Atualizando todos os pacotes instalados via Winget..." -ForegroundColor Cyan
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    Write-Host "[✓] Atualizações concluídas." -ForegroundColor Green
}

# ==============================================================================
# 5. MANUTENÇÃO, REDE E REPAROS (BOAS PRÁTICAS WIN 11)
# ==============================================================================
function Enable-BuiltinAdmin {
    Write-Host "`n[*] Habilitando conta de Administrador nativa (Detecção por SID 500)..." -ForegroundColor Cyan
    try {
        $admin = Get-LocalUser | Where-Object { $_.SID -like "*-500" }
        if ($admin) {
            Enable-LocalUser -SID $admin.SID
            Write-Host "[✓] Conta de Administrador ($($admin.Name)) ativada com sucesso!" -ForegroundColor Green
            $script:InstalledCache["admin500"] = $true
        } else {
            Write-Host "[!] Conta com SID final 500 não encontrada." -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERRO] Falha ao habilitar administrador: $_" -ForegroundColor Red
    }
}

function Invoke-SystemRepair {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "[*] INICIANDO REPARO DO SISTEMA (ORDEM OFICIAL MICROSOFT)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    
    Write-Host "`n[Passo 1/2] Executando DISM /Online /Cleanup-Image /RestoreHealth..." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /RestoreHealth
    
    Write-Host "`n[Passo 2/2] Executando SFC /scannow..." -ForegroundColor Yellow
    sfc /scannow
    
    Write-Host "`n[✓] Reparo de integridade do sistema concluído!" -ForegroundColor Green
    $script:InstalledCache["system_repair"] = $true
}

function Invoke-DiskCheck {
    Write-Host "`n[*] Executando diagnóstico online do volume C: (Repair-Volume Scan)..." -ForegroundColor Cyan
    try {
        Repair-Volume -DriveLetter C -Scan
        Write-Host "[✓] Verificação de integridade do disco C: concluída sem necessidade de reiniciar." -ForegroundColor Green
    } catch {
        Write-Host "[!] Executando chkdsk C: /scan..." -ForegroundColor Yellow
        chkdsk C: /scan
    }
    $script:InstalledCache["disk_check"] = $true
}

function Invoke-NetworkReset {
    Write-Host "`n[*] Executando renovação de pilha de rede e adaptadores..." -ForegroundColor Cyan
    
    Clear-DnsClientCache
    Write-Host "[+] Cache DNS limpo." -ForegroundColor Gray

    ipconfig /flushdns | Out-Null
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    arp -d * 2>$null
    Write-Host "[+] IP liberado e renovado via DHCP." -ForegroundColor Gray

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        Write-Host "[+] Reiniciando adaptador: $($adapter.Name)..." -ForegroundColor Gray
        Restart-NetAdapter -Name $adapter.Name -Confirm:$false
    }
    Write-Host "[✓] Rede atualizada com sucesso!" -ForegroundColor Green
    $script:InstalledCache["net_reset"] = $true
}

function Invoke-UpdateGPO {
    Write-Host "`n[*] Forçando atualização de diretivas de grupo (gpupdate /force)..." -ForegroundColor Cyan
    gpupdate /force
    Write-Host "[✓] GPO atualizada!" -ForegroundColor Green
    $script:InstalledCache["gpo_update"] = $true
}

function Add-NetworkCredential {
    Write-Host "`n[*] Mapeamento de Credencial de Rede (Windows Credential Manager)" -ForegroundColor Cyan
    $ip = Read-Host "Digite o IP ou Hostname do Servidor [Padrão: 192.168.0.34]"
    if ([string]::IsNullOrWhiteSpace($ip)) { $ip = "192.168.0.34" }
    
    $user = Read-Host "Digite o Usuário de Rede [Padrão: padrao]"
    if ([string]::IsNullOrWhiteSpace($user)) { $user = "padrao" }
    
    $pass = Read-Host "Digite a Senha de Rede" -AsSecureString
    $passPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
    
    if (-not [string]::IsNullOrWhiteSpace($passPlain)) {
        cmdkey /add:$ip /user:$user /pass:$passPlain | Out-Null
        Write-Host "[✓] Credencial para $ip salva com segurança no Windows!" -ForegroundColor Green
        $script:InstalledCache["net_cred"] = $true
    } else {
        Write-Host "[!] Senha não informada. Credencial não foi criada." -ForegroundColor Yellow
    }
}

function Set-MachineName {
    Write-Host "`n[*] Renomear Computador" -ForegroundColor Cyan
    $novoNome = Read-Host "Digite o novo nome para esta estação de trabalho"
    if (-not [string]::IsNullOrWhiteSpace($novoNome)) {
        Rename-Computer -NewName $novoNome -Force
        Write-Host "[✓] Computador renomeado para: $novoNome" -ForegroundColor Green
        $script:InstalledCache["rename_pc"] = $true
        $reiniciar = Read-Host "Deseja reiniciar o Windows agora para aplicar a alteração? (S/N)"
        if ($reiniciar -match "^[sSyY]") {
            Restart-Computer
        } else {
            Write-Host "[!] Lembre-se de reiniciar a máquina mais tarde." -ForegroundColor Yellow
        }
    }
}

function Enable-OpenSSHServer {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "[*] HABILITANDO SERVIDOR OPENSSH NO WINDOWS 11" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Write-Host "[1/3] Verificando capacidade nativa OpenSSH.Server..." -ForegroundColor Gray
    $sshCap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    if ($sshCap.State -ne 'Installed') {
        Write-Host "[+] Instalando OpenSSH.Server (aguarde alguns instantes)..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
        Write-Host "[✓] Recurso OpenSSH Server instalado!" -ForegroundColor Green
    } else {
        Write-Host "[✓] Recurso OpenSSH Server já está instalado." -ForegroundColor Green
    }

    Write-Host "[2/3] Configurando serviço sshd para inicialização automática..." -ForegroundColor Gray
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Set-Service -Name ssh-agent -StartupType 'Automatic'
    Write-Host "[✓] Serviço sshd em execução e configurado como Automático!" -ForegroundColor Green

    Write-Host "[3/3] Configurando regra de Firewall (Porta 22 TCP)..." -ForegroundColor Gray
    $regraExiste = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
    if (-not $regraExiste) {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null
    }
    $validaRegra = netsh advfirewall firewall show rule name="OpenSSH-Server-In-TCP" 2>$null
    if ($validaRegra -notmatch "OpenSSH-Server-In-TCP") {
        netsh advfirewall firewall add rule name="OpenSSH-Server-In-TCP" dir=in action=allow protocol=TCP localport=22 | Out-Null
    }
    Write-Host "[✓] Porta 22 liberada no Firewall para todos os perfis de rede!" -ForegroundColor Green

    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
        $_.IPAddress -ne "127.0.0.1" -and 
        $_.IPAddress -notlike "169.254*" -and 
        $_.InterfaceAlias -notlike "*Loopback*"
    } | Select-Object -ExpandProperty IPAddress -First 1)

    $script:InstalledCache["sshd"] = $true

    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host " [✓] SERVIDOR SSH CONFIGURADO E PRONTO PARA CONEXÃO!" -ForegroundColor Green
    Write-Host "     Comando para conectar do Linux/Mac/Terminal:" -ForegroundColor White
    Write-Host "     ssh $env:username@$ip" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Green
}

# ==============================================================================
# 6. TWEAKS EXCLUSIVOS DO WINDOWS 11
# ==============================================================================
function Apply-Win11Tweaks {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "[*] APLICANDO TWEAKS DE SISTEMA E PERFORMANCE NO WIN 11" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Write-Host "[+] Ativando Menu de Contexto Clássico completo..." -ForegroundColor Gray
    $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" | Out-Null
    }

    Write-Host "[+] Alinhando Barra de Tarefas à Esquerda..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord -Force

    Write-Host "[+] Ocultando Widgets e botão Copilot da barra de tarefas..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    Write-Host "[+] Exibindo extensões de arquivos no Explorer..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force

    Write-Host "[+] Exibindo pastas e arquivos ocultos..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force

    Write-Host "[+] Definindo 'Este Computador' como padrão no Explorer..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -Force

    Write-Host "[+] Desativando hibernação (liberação de espaço no SSD)..." -ForegroundColor Gray
    powercfg -h off

    Write-Host "[+] Ativando Tema Escuro..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

    Write-Host "[+] Reiniciando Windows Explorer para aplicar alterações..." -ForegroundColor Gray
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    $script:InstalledCache["win11_tweaks"] = $true
    Write-Host "[✓] Tweaks do Windows 11 aplicados com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 7. PERFIS AUTOMATIZADOS COM PROGRESSO PASSO A PASSO
# ==============================================================================
function Invoke-ModoPMA {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO PMA (PADRÃO PREFEITURA WIN 11)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Install-WingetApp "7zip.7zip" "7-Zip" "7zip"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader" "foxit"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" "libreoffice"
    Install-WingetApp "Skillbrains.Lightshot" "Lightshot (Captura)" "lightshot"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk (Acesso Remoto)" "rustdesk"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player" "vlc"
    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" "dotnet8"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)" "vcredist_x64"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)" "vcredist_x86"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE (LTS)" "temurin17jre"
    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    $script:InstalledCache["perfil_pma"] = $true
    Write-Host "`n[✓] Perfil MODO PMA concluído com sucesso!" -ForegroundColor Green
}

function Invoke-ModoBRNCZZR {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO BRNCZZR (DEV & WORKSTATION)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Install-WingetApp "Git.Git" "Git SCM" "git"
    Install-WingetApp "Microsoft.VisualStudioCode" "Visual Studio Code" "vscode"
    Install-WingetApp "Notepad++.Notepad++" "Notepad++" "notepadplusplus"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK (LTS)" "temurin17jdk"
    Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP & MySQL)" "xampp"
    Install-WingetApp "7zip.7zip" "7-Zip" "7zip"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" "libreoffice"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk" "rustdesk"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player" "vlc"
    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" "dotnet8"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)" "vcredist_x64"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)" "vcredist_x86"
    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    $script:InstalledCache["perfil_brnczzr"] = $true
    Write-Host "`n[✓] Perfil MODO BRNCZZR concluído com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 8. MOTOR DE EXECUÇÃO DE TAREFAS & DISPATCHER DESACOPLADO
# ==============================================================================
function Execute-SingleOption {
    param([Parameter(Mandatory=$true)] [string]$opcao)
    
    $op = $opcao.Trim().ToUpper()
    switch ($op) {
        "0"   { Update-AllWinget }
        "1A"  { Install-WingetApp "7zip.7zip" "7-Zip" "7zip" }
        "1B"  { Install-WingetApp "RARLab.WinRAR" "WinRAR" "winrar" }
        "2A"  { Install-WingetApp "Adobe.Acrobat.Reader.64-bit" "Adobe Acrobat Reader" "adobe" }
        "2B"  { Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader" "foxit" }
        "2C"  { Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" "libreoffice" }
        "3A"  { Install-WingetApp "GIMP.GIMP" "GIMP" "gimp" }
        "3B"  { Install-WingetApp "Skillbrains.Lightshot" "Lightshot" "lightshot" }
        "3C"  { Install-WingetApp "ShareX.ShareX" "ShareX" "sharex" }
        "4A"  { Install-WingetApp "HandBrake.HandBrake" "HandBrake" "handbrake" }
        "4B"  { Install-WingetApp "CodecGuide.K-LiteCodecPack.Full" "K-Lite Codec Pack Full" "klite" }
        "4C"  { Install-WingetApp "VideoLAN.VLC" "VLC Media Player" "vlc" }
        "5A"  { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" "dotnet8" }
        "5B"  { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.9" ".NET 9 Desktop Runtime" "dotnet9" }
        "5C"  { Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 x64" "vcredist_x64" }
        "5D"  { Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 x86" "vcredist_x86" }
        "5E"  { Install-WingetApp "abbodi1406.vcredist" "Visual C++ All-in-One Runtime" "vcredist_all" }
        "5F"  { Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE" "temurin17jre" }
        "6A"  { Install-WingetApp "AnyDeskSoftwareGmbH.AnyDesk" "AnyDesk" "anydesk" }
        "6B"  { Install-WingetApp "qBittorrent.qBittorrent" "qBittorrent" "qbittorrent" }
        "6C"  { Install-WingetApp "Rufus.Rufus" "Rufus" "rufus" }
        "6D"  { Install-WingetApp "RustDesk.RustDesk" "RustDesk" "rustdesk" }
        "6E"  { Install-WingetApp "Transmission.Transmission" "Transmission" "transmission" }
        "6F"  { Install-WingetApp "RealVNC.VNCViewer" "RealVNC Viewer" "realvnc" }
        
        "D0"  { 
            Install-WingetApp "Microsoft.VisualStudioCode" "VS Code" "vscode"
            Install-WingetApp "Git.Git" "Git SCM" "git"
            Install-WingetApp "Notepad++.Notepad++" "Notepad++" "notepadplusplus"
            Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK" "temurin17jdk"
        }
        "D1"  { Install-WingetApp "Microsoft.VisualStudioCode" "VS Code" "vscode" }
        "D2"  { Install-WingetApp "Notepad++.Notepad++" "Notepad++" "notepadplusplus" }
        "D3"  { Install-WingetApp "Microsoft.VisualStudio.2022.Community" "Visual Studio 2022 Community" "vs2022" }
        "D4"  { Install-WingetApp "Google.AndroidStudio" "Android Studio" "androidstudio" }
        "D5"  { Install-WingetApp "Git.Git" "Git SCM" "git" }
        "D6"  { Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP 8.2 & MySQL)" "xampp" }
        "D7"  { Install-WingetApp "EclipseAdoptium.Temurin.8.JDK" "Java Temurin 8 JDK" "temurin8jdk" }
        "D8"  { Install-WingetApp "EclipseAdoptium.Temurin.11.JDK" "Java Temurin 11 JDK" "temurin11jdk" }
        "D9"  { Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK" "temurin17jdk" }
        "D10" { Install-WingetApp "EclipseAdoptium.Temurin.21.JDK" "Java Temurin 21 JDK" "temurin21jdk" }
        
        "M1"  { Invoke-SystemRepair }
        "M2"  { Invoke-DiskCheck }
        "M3"  { Invoke-NetworkReset }
        "M4"  { Invoke-UpdateGPO }
        "M5"  { Enable-BuiltinAdmin }
        "M6"  { Add-NetworkCredential }
        "M7"  { Set-MachineName }
        "M8"  { Enable-OpenSSHServer }
        "M9"  { Apply-Win11Tweaks }
        "P1"  { Invoke-ModoPMA }
        "P2"  { Invoke-ModoBRNCZZR }
        
        default {
            Write-Host "[!] Opção '$op' não reconhecida." -ForegroundColor Red
        }
    }
}

function Execute-BatchOptions {
    param([Parameter(Mandatory=$true)] [string]$lote)
    
    $itens = @($lote -split "," | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($item in $itens) {
        $op = $item.Trim()
        if (-not [string]::IsNullOrWhiteSpace($op)) {
            Execute-SingleOption $op
        }
    }
}

function Dispatch-Execution {
    param([Parameter(Mandatory=$true)] [string]$escolha)
    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    
    $isSSH = (-not [string]::IsNullOrEmpty($env:SSH_CONNECTION)) -or (-not [string]::IsNullOrEmpty($env:SSH_CLIENT))
    
    # Resolve o caminho do script (vazio no modo one-liner "irm | iex" — sem arquivo local)
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = $MyInvocation.PSCommandPath
    }
    if ([string]::IsNullOrWhiteSpace($scriptPath) -and $PSScriptRoot) {
        $scriptPath = Join-Path $PSScriptRoot "win-toolbox.ps1"
    }
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = (Get-Item "win-toolbox.ps1" -ErrorAction SilentlyContinue).FullName
    }
    $temArquivoLocal = (-not [string]::IsNullOrWhiteSpace($scriptPath)) -and (Test-Path $scriptPath -PathType Leaf)
    
    if ($isSSH -or (-not $temArquivoLocal)) {
        # Execução no processo atual: modo SSH ou one-liner (irm | iex) sem arquivo para re-executar.
        # Sem isso, o Start-Process tentaria abrir "-File """ e a seleção pareceria "não fazer nada".
        Clear-Host
        Write-Host ("╭─ EXECUTANDO TAREFAS SELECIONADAS " + ("─" * 39) + " [ PROCESSO ATUAL ] ─╮") -ForegroundColor Cyan
        Write-Host "│" -NoNewline -ForegroundColor Cyan
        Write-Host (" Lote em andamento: $escolha".PadRight(88)) -NoNewline -ForegroundColor Yellow
        Write-Host "│" -ForegroundColor Cyan
        Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
        Write-Host ""
        Execute-BatchOptions $escolha
        Wait-User
    } else {
        # Janela filha desacoplada (modo arquivo local): executa sem poluir o menu
        try {
            $procArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -ExecutarLote `"$escolha`" -JanelaFilha"
            Start-Process powershell.exe -ArgumentList $procArgs -Wait
        } catch {
            Write-Host "[!] Não foi possível abrir a janela de execução desacoplada ($_)" -ForegroundColor Yellow
            Write-Host "[*] Executando as tarefas no processo atual..." -ForegroundColor Cyan
            Execute-BatchOptions $escolha
            Wait-User
        }
    }
    
    $script:InstalledCache.Clear()
}

# ==============================================================================
# 9. TELAS DE MENU COM POLIMENTO TUI MODERNO
# ==============================================================================
function Invoke-MenuPrincipal {
    Show-Header "MENU PRINCIPAL — SOFTWARES ESSENCIAIS & RUNTIMES"

    # Obter estados de cada aplicativo
    $i1A = Get-ItemDisplay "7zip" "1A" "7-Zip"
    $i1B = Get-ItemDisplay "winrar" "1B" "WinRAR"
    
    $i2A = Get-ItemDisplay "adobe" "2A" "Adobe Acrobat"
    $i2B = Get-ItemDisplay "foxit" "2B" "Foxit PDF Reader"
    $i2C = Get-ItemDisplay "libreoffice" "2C" "LibreOffice LTS"
    
    $i3A = Get-ItemDisplay "gimp" "3A" "GIMP"
    $i3B = Get-ItemDisplay "lightshot" "3B" "Lightshot"
    $i3C = Get-ItemDisplay "sharex" "3C" "ShareX"
    
    $i4A = Get-ItemDisplay "handbrake" "4A" "HandBrake"
    $i4B = Get-ItemDisplay "klite" "4B" "K-Lite Codec Full"
    $i4C = Get-ItemDisplay "vlc" "4C" "VLC Media Player"
    
    $i5A = Get-ItemDisplay "dotnet8" "5A" ".NET 8 Desktop"
    $i5B = Get-ItemDisplay "dotnet9" "5B" ".NET 9 Desktop"
    $i5C = Get-ItemDisplay "vcredist_x64" "5C" "VC++ 15-22 x64"
    $i5D = Get-ItemDisplay "vcredist_x86" "5D" "VC++ 15-22 x86"
    $i5E = Get-ItemDisplay "vcredist_all" "5E" "VC++ All-in-One"
    $i5F = Get-ItemDisplay "temurin17jre" "5F" "Temurin 17 JRE"
    
    $i6A = Get-ItemDisplay "anydesk" "6A" "AnyDesk"
    $i6B = Get-ItemDisplay "qbittorrent" "6B" "qBittorrent"
    $i6C = Get-ItemDisplay "rufus" "6C" "Rufus (Boot)"
    $i6D = Get-ItemDisplay "rustdesk" "6D" "RustDesk"
    $i6E = Get-ItemDisplay "transmission" "6E" "Transmission"
    $i6F = Get-ItemDisplay "realvnc" "6F" "RealVNC Viewer"

    Write-Host "╭────────────────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-TuiRowFull -text " [0] ATUALIZAÇÃO GERAL: Atualizar todos os pacotes instalados via Winget" -color "Yellow"
    Write-Host "├─────────────────────────┬─────────────────────────────┬────────────────────────────────┤" -ForegroundColor Cyan
    
    Write-TuiHeader3Col " COMPACTAÇÃO" " DOCUMENTOS" " IMAGEM & VÍDEO"
    Write-TuiRow3Col $i1A $i2A $i3A
    Write-TuiRow3Col $i1B $i2B $i3B
    Write-TuiRow3Col $null $i2C $i3C
    Write-TuiRow3Col $null $null $i4A
    Write-TuiRow3Col $null $null $i4B
    Write-TuiRow3Col $null $null $i4C
    
    Write-Host "├─────────────────────────┼─────────────────────────────┴────────────────────────────────┤" -ForegroundColor Cyan
    Write-TuiHeaderSplit " RUNTIMES WIN 11" " ACESSO REMOTO & UTILITÁRIOS"
    Write-TuiRowSplit $i5A $i6A $i6D
    Write-TuiRowSplit $i5B $i6B $i6E
    Write-TuiRowSplit $i5C $i6C $i6F
    Write-TuiRowSplit $i5D $null $null
    Write-TuiRowSplit $i5E $null $null
    Write-TuiRowSplit $i5F $null $null
    
    Write-Host "├─────────────────────────┴──────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-TuiRowFull -text " NAVEGAÇÃO:   [D] Menu Dev    │    [M] Menu Manutenção & Perfis    │    [Q] Sair" -color "Yellow"
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    
    $instCount = ($script:InstalledCache.Values | Where-Object { $_ -eq $true }).Count
    $statusText = if ($instCount -gt 0) {
        " [✓] Verde = Instalado/Concluído ($instCount detectados) | [ ] Branco = Pendente"
    } else {
        " [✓] Verde = Instalado/Concluído | [ ] Branco = Pendente. Suporta execução em lote."
    }
    
    Write-Host "╭─ STATUS DO SISTEMA ─────────────────────────────────────────────────────── [ PRONTO ] ─╮" -ForegroundColor DarkCyan
    Write-Host "│" -NoNewline -ForegroundColor DarkCyan
    Write-Host ($statusText.PadRight(88)) -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkCyan
    
    Write-Host "╭─ Digite as opções desejadas separadas por vírgula (ex: 0, 1A, 2C, 5E, 6D)" -ForegroundColor Cyan
    $escolha = Read-Host "╰─❯ "
    
    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "D") { $script:menuAtual = "DEV"; return }
    if ($escolhaUpper -eq "M") { $script:menuAtual = "MANUTENCAO"; return }
    Dispatch-Execution $escolha
}

function Invoke-MenuDev {
    Show-Header "MENU DESENVOLVIMENTO (DEV)"

    $iD1  = Get-ItemDisplay "vscode" "D1" "Visual Studio Code"
    $iD2  = Get-ItemDisplay "notepadplusplus" "D2" "Notepad++"
    $iD3  = Get-ItemDisplay "vs2022" "D3" "VS 2022 Community"
    $iD4  = Get-ItemDisplay "androidstudio" "D4" "Android Studio"

    $iD5  = Get-ItemDisplay "git" "D5" "Git SCM"
    $iD6  = Get-ItemDisplay "xampp" "D6" "XAMPP (PHP 8.2 & MySQL)"
    $iD7  = Get-ItemDisplay "temurin8jdk" "D7" "Java Temurin 8 JDK"
    $iD8  = Get-ItemDisplay "temurin11jdk" "D8" "Java Temurin 11 JDK"
    $iD9  = Get-ItemDisplay "temurin17jdk" "D9" "Java Temurin 17 JDK (LTS)"
    $iD10 = Get-ItemDisplay "temurin21jdk" "D10" "Java Temurin 21 JDK (LTS)"

    Write-Host "╭────────────────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-TuiRowFull -text " [D0] PACOTE DEV COMPLETO: Instalar VS Code + Git + Notepad++ + JDK 17" -color "Yellow"
    Write-Host "├────────────────────────────────────────┬───────────────────────────────────────────────┤" -ForegroundColor Cyan
    
    Write-TuiHeader2Col " IDEs & EDITORES" " VERSIONAMENTO & SERVIDORES"
    Write-TuiRow2Col $iD1 $iD5
    Write-TuiRow2Col $iD2 $iD6
    Write-TuiRow2Col $iD3 $null "" " JAVA DEVELOPMENT KIT (JDK)"
    Write-TuiRow2Col $iD4 $iD7
    Write-TuiRow2Col $null $iD8
    Write-TuiRow2Col $null $iD9
    Write-TuiRow2Col $null $iD10
    
    Write-Host "├────────────────────────────────────────┴───────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-TuiRowFull -text " NAVEGAÇÃO:   [V] Menu Principal    │    [M] Menu Manutenção & Perfis    │    [Q] Sair" -color "Yellow"
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    
    $instCount = ($script:InstalledCache.Values | Where-Object { $_ -eq $true }).Count
    $statusText = if ($instCount -gt 0) {
        " [✓] Verde = Instalado/Concluído ($instCount detectados) | [ ] Branco = Pendente"
    } else {
        " [✓] Verde = Instalado/Concluído | [ ] Branco = Pendente. Suporta execução em lote."
    }

    Write-Host "╭─ STATUS DO SISTEMA ─────────────────────────────────────────────────────── [ PRONTO ] ─╮" -ForegroundColor DarkCyan
    Write-Host "│" -NoNewline -ForegroundColor DarkCyan
    Write-Host ($statusText.PadRight(88)) -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkCyan

    Write-Host "╭─ Selecione ferramentas de DEV (ex: D0 ou D1, D5, D9)" -ForegroundColor Cyan
    $escolha = Read-Host "╰─❯ "

    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "V") { $script:menuAtual = "MAIN"; return }
    if ($escolhaUpper -eq "M") { $script:menuAtual = "MANUTENCAO"; return }

    Dispatch-Execution $escolha
}

function Invoke-MenuManutencao {
    Show-Header "MENU MANUTENÇÃO, TWEAKS & PERFIS AUTO"

    $iM1 = Get-ItemDisplay "system_repair" "M1" "Reparo Completo (DISM + SFC)"
    $iM2 = Get-ItemDisplay "disk_check" "M2" "Diagnóstico Volume C: (Scan)"
    $iM3 = Get-ItemDisplay "net_reset" "M3" "Reset Pilha de Rede (DHCP)"
    $iM4 = Get-ItemDisplay "gpo_update" "M4" "Forçar Atualização GPO"

    $iM5 = Get-ItemDisplay "admin500" "M5" "Habilitar Admin (SID 500)"
    $iM6 = Get-ItemDisplay "net_cred" "M6" "Mapear Credencial de Rede"
    $iM7 = Get-ItemDisplay "rename_pc" "M7" "Renomear Computador"
    $iM8 = Get-ItemDisplay "sshd" "M8" "Habilitar Servidor OpenSSH (22)"

    $iM9 = Get-ItemDisplay "win11_tweaks" "M9" "Tweaks Win 11 (Menu Clássico, Dark, Barra Esquerda, Sem Widgets/Copilot)"
    $iP1 = Get-ItemDisplay "perfil_pma" "P1" "MODO PMA (Prefeitura Win 11: Apps Corporativos + Runtimes + Admin + Tweaks)"
    $iP2 = Get-ItemDisplay "perfil_brnczzr" "P2" "MODO BRNCZZR (Dev Workstation: Apps Dev + Runtimes + Tweaks)"

    Write-Host "╭────────────────────────────────────────┬───────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-TuiHeader2Col " DIAGNÓSTICO & REPARO" " CONFIGURAÇÕES, REDE & ACESSO"
    Write-TuiRow2Col $iM1 $iM5
    Write-TuiRow2Col $iM2 $iM6
    Write-TuiRow2Col $iM3 $iM7
    Write-TuiRow2Col $iM4 $iM8
    Write-Host "├────────────────────────────────────────┴───────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-TuiHeaderFull " TWEAKS DE SISTEMA E PERFORMANCE DO WINDOWS 11"
    Write-TuiRowFull $iM9
    Write-Host "├────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-TuiHeaderFull " PERFIS AUTOMATIZADOS (INSTALAÇÃO EM LOTE)"
    Write-TuiRowFull $iP1
    Write-TuiRowFull $iP2
    Write-Host "├────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-TuiRowFull -text " NAVEGAÇÃO:   [V] Menu Principal    │    [D] Menu Desenvolvimento (DEV)   │    [Q] Sair" -color "Yellow"
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    
    $instCount = ($script:InstalledCache.Values | Where-Object { $_ -eq $true }).Count
    $statusText = if ($instCount -gt 0) {
        " [✓] Verde = Instalado/Concluído ($instCount detectados) | [ ] Branco = Pendente"
    } else {
        " [✓] Verde = Instalado/Concluído | [ ] Branco = Pendente. Suporta execução em lote."
    }

    Write-Host "╭─ STATUS DO SISTEMA ─────────────────────────────────────────────────────── [ PRONTO ] ─╮" -ForegroundColor DarkCyan
    Write-Host "│" -NoNewline -ForegroundColor DarkCyan
    Write-Host ($statusText.PadRight(88)) -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkCyan

    Write-Host "╭─ Selecione tarefas de manutenção ou perfis (ex: M1, M8 ou P1)" -ForegroundColor Cyan
    $escolha = Read-Host "╰─❯ "

    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "V") { $script:menuAtual = "MAIN"; return }
    if ($escolhaUpper -eq "D") { $script:menuAtual = "DEV"; return }
    Dispatch-Execution $escolha
}

# ==============================================================================
# 10. DISPATCHER E LOOP PRINCIPAL DE CONTROLE (MÁQUINA DE ESTADOS)
# ==============================================================================
if (-not [string]::IsNullOrWhiteSpace($ExecutarLote)) {
    $host.UI.RawUI.WindowTitle = "WIN-TOOLBOX-TUI — [Executando: $ExecutarLote]"
    Clear-Host
    Write-Host ("╭─ EXECUTANDO TAREFAS SELECIONADAS " + ("─" * 33) + " [ PROCESSO ATIVO ] ─╮") -ForegroundColor Cyan
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host (" Lote em andamento: $ExecutarLote".PadRight(88)) -NoNewline -ForegroundColor Yellow
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host (" Esta janela exibirá o progresso real e fechará automaticamente ao término.".PadRight(88)) -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    Write-Host ""
    
    Execute-BatchOptions $ExecutarLote
    
    Write-Host ""
    Write-Host "╭────────────────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Green
    Write-Host "│" -NoNewline -ForegroundColor Green
    Write-Host (" [✓] Todas as tarefas solicitadas foram concluídas!".PadRight(88)) -NoNewline -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Green
    
    if ($JanelaFilha) {
        Write-Host "`n[+] Fechando esta janela em 2 segundos..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
        exit 0
    } else {
        Wait-User
        exit 0
    }
}

$script:menuAtual = "MAIN"

while ($script:menuAtual -ne "EXIT") {
    switch ($script:menuAtual) {
        "MAIN"        { Invoke-MenuPrincipal }
        "DEV"         { Invoke-MenuDev }
        "MANUTENCAO"  { Invoke-MenuManutencao }
    }
}

Write-Host "`n[+] Encerrando win-toolbox-tui. Até logo!`n" -ForegroundColor Green
