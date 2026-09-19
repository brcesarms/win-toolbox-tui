<#
.SYNOPSIS
    WIN-TOOLBOX-TUI V2.0 — Caixa de Ferramentas e Pós-Instalação para Windows 11
.DESCRIPTION
    Script interativo com interface estilo BIOS / Setup Utility: bordas duplas,
    navegação por setas (↑↓), Espaço marca [✓], Enter executa, Esc volta e Q sai —
    100% nativo PowerShell ([Console]::ReadKey, sem dependências externas).
    Detecção de apps já instalados ([INSTALADO] em verde), execução 100% in-process
    (compatível com o one-liner irm | iex), telemetria de rede e suporte ao Windows Terminal.
    Exclusivo para Windows 11 (Build 22000+).
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    2.0.0 — Setup Utility estilo BIOS (setas ↑↓ + Espaço + Enter), Winget Sem Travamento, one-liner irm|iex
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string]$ExecutarLote = ""
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
# 3. CONFIGURAÇÃO DE DIMENSÕES DA JANELA (PADRÃO 120 COLUNAS X 30 LINHAS)
# ==============================================================================
try {
    if ($Host.UI.RawUI) {
        $curW = $Host.UI.RawUI.WindowSize.Width
        $curH = $Host.UI.RawUI.WindowSize.Height
        if ($curW -lt 120 -or $curH -lt 30) {
            $buf = $Host.UI.RawUI.BufferSize
            $newBufW = [Math]::Max($buf.Width, 120)
            $newBufH = [Math]::Max($buf.Height, 30)
            $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($newBufW, $newBufH)
            $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 30)
        }
    }
} catch { }

# ==============================================================================
# 4. UTILITÁRIO DE ESPERA (WAIT)
# ==============================================================================
function Wait-User {
    Write-Host "`n[Pressione ENTER para continuar...]" -ForegroundColor DarkGray
    $null = Read-Host
}

# ==============================================================================
# 4. CACHE DE DETECÇÃO & WINGET
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
            "adobe"           { $result = (Test-Path "$env:ProgramFiles\Adobe\Acrobat DC\Acrobat\Acrobat.exe") -or (Test-Path "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe") }
            "anydesk"         { $result = (Test-Path "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe") }
            "brave"           { $result = (Test-Path "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe") -or (Test-Path "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe") -or (Test-Path "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe") }
            "chrome"          { $result = (Test-Path "$env:ProgramFiles\Google\Chrome\Application\chrome.exe") -or (Test-Path "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe") -or (Test-Path "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") }
            "foxit"           { $result = (Test-Path "${env:ProgramFiles(x86)}\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") -or (Test-Path "$env:ProgramFiles\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") }
            "gimp"            { $result = (Test-Path "$env:ProgramFiles\GIMP 2\bin\gimp-2.10.exe") -or (Test-Path "$env:ProgramFiles\GIMP 3\bin\gimp.exe") }
            "handbrake"       { $result = (Test-Path "$env:ProgramFiles\HandBrake\HandBrake.exe") }
            "klite"           { $result = (Test-Path "HKLM:\SOFTWARE\KLiteCodecPack") -or (Test-Path "HKLM:\SOFTWARE\WOW6432Node\KLiteCodecPack") -or (Test-Path "${env:ProgramFiles(x86)}\K-Lite Codec Pack") }
            "libreoffice"     { $result = (Test-Path "$env:ProgramFiles\LibreOffice\program\soffice.exe") }
            "lightshot"       { $result = (Test-Path "${env:ProgramFiles(x86)}\Skillbrains\Lightshot\Lightshot.exe") }
            "qbittorrent"     { $result = (Test-Path "$env:ProgramFiles\qBittorrent\qbittorrent.exe") }
            "realvnc"         { $result = (Test-Path "$env:ProgramFiles\RealVNC\VNC Viewer\vncviewer.exe") }
            "rufus"           { $result = (Test-Path "$env:LOCALAPPDATA\Programs\Rufus\rufus.exe") -or (Test-Path "$env:ProgramFiles\Rufus\rufus.exe") }
            "rustdesk"        { $result = (Test-Path "$env:ProgramFiles\RustDesk\rustdesk.exe") }
            "sharex"          { $result = (Test-Path "$env:ProgramFiles\ShareX\ShareX.exe") }
            "transmission"    { $result = (Test-Path "$env:ProgramFiles\Transmission\transmission-qt.exe") }
            "vlc"             { $result = (Test-Path "$env:ProgramFiles\VideoLAN\VLC\vlc.exe") }
            "winrar"          { $result = (Test-Path "$env:ProgramFiles\WinRAR\WinRAR.exe") }
            
            # Runtimes
            "dotnet8"         { $result = (Test-Path "$env:ProgramFiles\dotnet\shared\Microsoft.WindowsDesktop.App\8.*") }
            "dotnet9"         { $result = (Test-Path "$env:ProgramFiles\dotnet\shared\Microsoft.WindowsDesktop.App\9.*") }
            "temurin17jre"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jre-17*") }
            "vcredist_x64"    { $result = (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64") }
            "vcredist_x86"    { $result = (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86") }
            "vcredist_all"    { $result = (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64") -and (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86") }
            
            # Dev
            "androidstudio"   { $result = (Test-Path "$env:ProgramFiles\Android\Android Studio\bin\studio64.exe") }
            "git"             { $result = (Test-Path "$env:ProgramFiles\Git\bin\git.exe") -or ((Get-Command git -ErrorAction SilentlyContinue) -ne $null) }
            "notepadplusplus" { $result = (Test-Path "$env:ProgramFiles\Notepad++\notepad++.exe") }
            "temurin8jdk"     { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-8*") }
            "temurin11jdk"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-11*") }
            "temurin17jdk"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-17*") }
            "temurin21jdk"    { $result = (Test-Path "$env:ProgramFiles\Eclipse Adoptium\jdk-21*") }
            "vscode"          { $result = (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -or (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe") }
            "vs2022"          { $result = (Test-Path "$env:ProgramFiles\Microsoft Visual Studio\2022") }
            "xampp"           { $result = (Test-Path "C:\xampp\xampp-control.exe") }
            
            # Manutenção & Configurações
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

# ==============================================================================
# 3.5 MOTOR DE INTERFACE ESTILO BIOS (SETUP UTILITY)
# ==============================================================================
# Experiência fiel ao firmware: bordas duplas, navegação por setas ↑↓, Espaço marca
# [✓], Enter executa, Esc volta, Q sai. 100% nativo ([Console]::ReadKey), sem gum
# nem instalação — roda direto no one-liner: irm ... | iex

function New-BiosItem {
    param(
        [string]$Code,
        [string]$Text,
        [string]$Desc = "",
        [string]$PackageId = "",
        [string]$Category = "",
        [bool]$Instalado = $false,
        [bool]$Special = $false
    )
    if ($Special) { $Instalado = $false }
    return @{ 
        Code      = $Code
        Text      = $Text
        Desc      = $Desc
        PackageId = $PackageId
        Category  = $Category
        Instalado = $Instalado
        Special   = $Special 
    }
}

function Get-BiosHelpLines {
    param([object]$Item)

    $lines = [System.Collections.Generic.List[object]]::new()
    
    # 0: Cabeçalho do Painel
    $lines.Add(@{ Text = " Informações do Item"; Color = "Yellow" })
    
    # 1: Linha divisória horizontal
    $lines.Add(@{ Text = ("─" * 45); Color = "DarkCyan" })
    
    if ($Item -eq $null) {
        while ($lines.Count -lt 21) {
            $lines.Add(@{ Text = ""; Color = "DarkGray" })
        }
        return $lines
    }

    # 2: Nome do Item
    $nome = if ($Item.Text) { [string]$Item.Text } else { "Item" }
    if ($nome.Length -gt 43) { $nome = $nome.Substring(0, 42) + "…" }
    $lines.Add(@{ Text = " $nome"; Color = "White" })

    # 3: Categoria
    $cat = if ($Item.Category) { " Categoria: $($Item.Category)" } else { "" }
    if ($cat.Length -gt 44) { $cat = $cat.Substring(0, 43) + "…" }
    $lines.Add(@{ Text = $cat; Color = "DarkGray" })

    # 4: Linha em branco
    $lines.Add(@{ Text = ""; Color = "DarkGray" })

    # 5: Rótulo Descrição
    $lines.Add(@{ Text = " Descrição:"; Color = "Cyan" })

    # 6..8: Word-wrap da descrição em até 43 caracteres por linha
    $desc = if ($Item.Desc) { [string]$Item.Desc } else { "Sem descrição adicional para este item." }
    $words = $desc -split '\s+'
    $curLine = " "
    $descLines = [System.Collections.Generic.List[string]]::new()
    foreach ($w in $words) {
        if ([string]::IsNullOrWhiteSpace($w)) { continue }
        if (($curLine + " " + $w).Trim().Length -le 43) {
            if ($curLine -eq " ") { $curLine += $w } else { $curLine += " $w" }
        } else {
            $descLines.Add($curLine)
            $curLine = " " + $w
        }
    }
    if ($curLine.Trim().Length -gt 0) { $descLines.Add($curLine) }

    for ($k = 0; $k -lt 3; $k++) {
        if ($k -lt $descLines.Count) {
            $d = $descLines[$k]
            if ($d.Length -gt 45) { $d = $d.Substring(0, 45) }
            $lines.Add(@{ Text = $d; Color = "Gray" })
        } else {
            $lines.Add(@{ Text = ""; Color = "Gray" })
        }
    }

    # 9: Linha em branco
    $lines.Add(@{ Text = ""; Color = "DarkGray" })

    # 10: Rótulo Pacote
    $lines.Add(@{ Text = " Identificador / Pacote:"; Color = "Cyan" })

    # 11: ID do Pacote
    $pkg = if ($Item.PackageId) { "   $($Item.PackageId)" } else { "   N/A" }
    if ($pkg.Length -gt 45) { $pkg = $pkg.Substring(0, 44) + "…" }
    $lines.Add(@{ Text = $pkg; Color = "White" })

    # 12: Linha em branco
    $lines.Add(@{ Text = ""; Color = "DarkGray" })

    # 13: Rótulo Status
    $lines.Add(@{ Text = " Status no Windows:"; Color = "Cyan" })

    # 14: Valor Status
    if ($Item.Special) {
        $lines.Add(@{ Text = "   [*] Rotina em Lote / Especial"; Color = "Yellow" })
    } elseif ($Item.Instalado) {
        $lines.Add(@{ Text = "   [✓] Já instalado no sistema"; Color = "Green" })
    } else {
        $lines.Add(@{ Text = "   [ ] Não instalado / Pendente"; Color = "DarkGray" })
    }

    # 15: Linha em branco
    $lines.Add(@{ Text = ""; Color = "DarkGray" })

    # 16: Linha divisória inferior
    $lines.Add(@{ Text = ("─" * 45); Color = "DarkCyan" })

    # 17..20: Atalhos do Setup
    $lines.Add(@{ Text = " Atalhos do Setup:"; Color = "DarkGray" })
    $lines.Add(@{ Text = "   [Espaço]  Marca p/ fila em lote"; Color = "Gray" })
    $lines.Add(@{ Text = "   [Enter]   Executa seleção"; Color = "Gray" })
    $lines.Add(@{ Text = "   [Q]       Fecha o terminal"; Color = "Gray" })

    while ($lines.Count -lt 21) {
        $lines.Add(@{ Text = ""; Color = "DarkGray" })
    }
    return $lines
}

$script:screenCleared = $false
$script:CachedIP = ""

function Get-LocalIP {
    if (-not [string]::IsNullOrWhiteSpace($script:CachedIP)) {
        return $script:CachedIP
    }
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
            $_.IPAddress -ne "127.0.0.1" -and 
            $_.IPAddress -notlike "169.254*" -and 
            $_.InterfaceAlias -notlike "*Loopback*"
        } | Select-Object -ExpandProperty IPAddress -First 1)
        if (-not $ip) {
            $ip = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) | 
                Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and $_.IPAddressToString -notlike "127.*" -and $_.IPAddressToString -notlike "169.254*" } | 
                Select-Object -ExpandProperty IPAddressToString -First 1
        }
        if (-not $ip) { $ip = "Sem Rede" }
        $script:CachedIP = $ip
        return $ip
    } catch {
        return "127.0.0.1"
    }
}

function Show-BiosScreen {
    param(
        [string]$ActiveTab = "APPS",
        [object[]]$Items,
        [int]$Sel,
        [hashtable]$Marks,
        [int]$Page = 0,
        [int]$PageSize = 21,
        [int]$PageCount = 1,
        [bool]$Multi = $true
    )
    
    try {
        [Console]::CursorVisible = $false
        if (-not $script:screenCleared) {
            Clear-Host
            $script:screenCleared = $true
        } else {
            [Console]::SetCursorPosition(0, 0)
        }
    } catch {
        Clear-Host
    }

    $totalWidth = 120        # largura total da caixa padronizada 120x30
    $inner = $totalWidth - 4 # conteúdo interno (116) entre "║ " e " ║"

    # ---- topo estilo BIOS ----
    Write-Host ("╔" + ("═" * ($totalWidth - 2)) + "╗") -ForegroundColor Cyan
    $topo = (" WIN-TOOLBOX TUI · Setup Utility" + (" " * 69) + "[ WINDOWS 11 ] ")
    Write-Host "║ $($topo.PadRight($inner)) ║" -ForegroundColor Cyan
    $data = (Get-Date).ToString("dd/MM/yyyy")
    $ip = Get-LocalIP
    $info = " Data: $data | Computador: $env:computername | Usuário: $env:username | IP: $ip"
    Write-Host "║ $($info.PadRight($inner)) ║" -ForegroundColor DarkGray
    Write-Host ("╠" + ("═" * ($totalWidth - 2)) + "╣") -ForegroundColor Cyan

    # ---- barra de menus estilo BIOS (sempre visível no topo, 120 colunas) ----
    # Espaçamento exato: 2 (borda "║ ") + 10 + 8 (Apps) + 16 + 12 (Runtimes) + 16 + 7 (Dev) + 16 + 17 (Configurações) + 14 + 2 (" ║") = 120
    Write-Host "║ " -NoNewline -ForegroundColor Cyan
    Write-Host (" " * 10) -NoNewline
    
    if ($ActiveTab -eq "APPS") {
        Write-Host "[ APPS ]" -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    } else {
        Write-Host "  Apps  " -NoNewline -ForegroundColor DarkGray
    }
    
    Write-Host (" " * 16) -NoNewline
    
    if ($ActiveTab -eq "RUNTIMES") {
        Write-Host "[ RUNTIMES ]" -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    } else {
        Write-Host "  Runtimes  " -NoNewline -ForegroundColor DarkGray
    }
    
    Write-Host (" " * 16) -NoNewline
    
    if ($ActiveTab -eq "DEV") {
        Write-Host "[ DEV ]" -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    } else {
        Write-Host "  Dev  " -NoNewline -ForegroundColor DarkGray
    }
    
    Write-Host (" " * 16) -NoNewline
    
    if ($ActiveTab -eq "CONFIG") {
        Write-Host "[ CONFIGURAÇÕES ]" -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    } else {
        Write-Host "  Configurações  " -NoNewline -ForegroundColor DarkGray
    }
    
    Write-Host (" " * 14) -NoNewline
    Write-Host " ║" -ForegroundColor Cyan
    # Split header: 70 chars esquerda + 47 chars direita (1 + 70 + 1 + 47 + 1 = 120 colunas)
    Write-Host ("╠" + ("═" * 70) + "╦" + ("═" * 47) + "╣") -ForegroundColor Cyan

    # ---- itens da página atual e painel de ajuda ----
    $start = $Page * $PageSize
    $end = [Math]::Min($Items.Count, $start + $PageSize)

    $selectedItem = if ($Sel -ge 0 -and $Sel -lt $Items.Count) { $Items[$Sel] } else { $null }
    $helpLines = Get-BiosHelpLines -Item $selectedItem

    for ($j = 0; $j -lt $PageSize; $j++) {
        $i = $start + $j

        # --- LADO ESQUERDO: LISTA DE ITENS (68 colunas) ---
        $leftFull = ""
        $leftColor = "Gray"
        $isSelected = ($i -eq $Sel)

        if ($i -lt $end) {
            $it = $Items[$i]
            $mark = " "
            if ($it.Instalado -or $Marks.ContainsKey($it.Code)) { $mark = "✓" }
            $cursor = "  "
            if ($isSelected) { $cursor = "► " }

            $prefix = "$cursor[$mark] $($it.Code.PadRight(4)) "
            $sufixo = ""
            if ($it.Special) {
                $leftColor = "Yellow"
            } elseif ($it.Instalado) {
                $leftColor = "Green"
                $sufixo = "[INSTALADO]"
            } elseif ($Marks.ContainsKey($it.Code)) {
                $leftColor = "Cyan"
            }

            $maxNome = 68 - $prefix.Length - $sufixo.Length
            if (-not [string]::IsNullOrWhiteSpace($sufixo)) { $maxNome -= 1 }

            $nome = $it.Text
            if ($nome.Length -gt $maxNome) {
                $nome = $nome.Substring(0, [Math]::Max(0, $maxNome - 1)) + "…"
            }

            $meio = $prefix + $nome
            if (-not [string]::IsNullOrWhiteSpace($sufixo)) {
                $leftFull = $meio.PadRight(68 - $sufixo.Length) + $sufixo
            } else {
                $leftFull = $meio.PadRight(68)
            }
            if ($leftFull.Length -gt 68) { $leftFull = $leftFull.Substring(0, 68) }
        } else {
            $leftFull = "".PadRight(68)
        }

        # --- LADO DIREITO: PAINEL DE AJUDA DO ITEM (45 colunas) ---
        $rLine = $helpLines[$j]
        $rText = $rLine.Text
        if ($rText.Length -gt 45) { $rText = $rText.Substring(0, 45) }
        $rightFormatted = $rText.PadRight(45)
        $rightColor = $rLine.Color

        # Linha montada: "║ " (2) + Left (68) + " ║ " (3) + Right (45) + " ║" (2) = 120 colunas
        Write-Host "║ " -NoNewline -ForegroundColor Cyan
        if ($isSelected -and ($i -lt $end)) {
            Write-Host $leftFull -NoNewline -BackgroundColor Green -ForegroundColor Black
        } else {
            Write-Host $leftFull -NoNewline -ForegroundColor $leftColor
        }
        Write-Host " ║ " -NoNewline -ForegroundColor Cyan
        Write-Host $rightFormatted -NoNewline -ForegroundColor $rightColor
        Write-Host " ║" -ForegroundColor Cyan
    }

    # ---- rodapé: dicas de navegação espaçadas estilo BIOS ----
    Write-Host ("╠" + ("═" * 70) + "╩" + ("═" * 47) + "╣") -ForegroundColor Cyan

    $navItems = @("←→ Trocar Menu", "↑↓ Mover", "Espaço [✓] Marcar", "Enter Executar")
    if ($Marks.Count -gt 0) {
        $navItems += "Marcados: $($Marks.Count)"
    }
    if ($PageCount -gt 1) {
        $navItems += "Pg $($Page + 1)/$PageCount"
    }
    $navItems += "Q Sair"

    $totalTextLen = 0
    foreach ($item in $navItems) { $totalTextLen += $item.Length }
    
    $totalSpaces = [Math]::Max(0, $inner - $totalTextLen)
    $numGaps = $navItems.Count + 1
    $baseGap = [Math]::Floor($totalSpaces / $numGaps)
    $extra = $totalSpaces % $numGaps

    $linhaDica = ""
    for ($g = 0; $g -lt $numGaps; $g++) {
        $gapSize = $baseGap
        if ($g -lt $extra) { $gapSize++ }
        $linhaDica += (" " * $gapSize)
        if ($g -lt $navItems.Count) {
            $linhaDica += $navItems[$g]
        }
    }
    if ($linhaDica.Length -gt $inner) { $linhaDica = $linhaDica.Substring(0, $inner) }

    Write-Host "║ " -NoNewline -ForegroundColor Cyan
    Write-Host ($linhaDica.PadRight($inner)) -NoNewline -ForegroundColor Cyan
    Write-Host " ║" -ForegroundColor Cyan

    # Borda inferior com -NoNewline para evitar scroll na linha 30
    Write-Host ("╚" + ("═" * ($totalWidth - 2)) + "╝") -NoNewline -ForegroundColor Cyan
}

function Read-BiosMenu {
    param(
        [Parameter(Mandatory=$true)] [string]$ActiveTab,
        [Parameter(Mandatory=$true)] [object[]]$Items,
        [bool]$Multi = $true
    )

    $sel = 0
    $marks = @{}
    $pageSize = 21
    $pageCount = [Math]::Max(1, [Math]::Ceiling($Items.Count / $pageSize))
    $page = 0

    while ($true) {
        Show-BiosScreen -ActiveTab $ActiveTab -Items $Items -Sel $sel -Marks $marks `
            -Page $page -PageSize $pageSize -PageCount $pageCount -Multi $Multi

        # Fallback para hosts sem ReadKey (pede códigos por texto)
        try {
            $key = [Console]::ReadKey($true)
        } catch {
            $resp = Read-Host "Digite codigos (ex: 1A,2C) ou Q para sair"
            $respU = $resp.Trim().ToUpper()
            if ($respU -eq "Q") { 
                try { [Console]::CursorVisible = $true } catch { }
                [System.Environment]::Exit(0)
                Stop-Process -Id $PID -Force
                return "Q" 
            }
            return $respU
        }

        switch ($key.Key) {
            "LeftArrow" {
                switch ($ActiveTab) {
                    "APPS"     { return "TAB_CONFIG" }
                    "RUNTIMES" { return "TAB_APPS" }
                    "DEV"      { return "TAB_RUNTIMES" }
                    "CONFIG"   { return "TAB_DEV" }
                }
            }
            "RightArrow" {
                switch ($ActiveTab) {
                    "APPS"     { return "TAB_RUNTIMES" }
                    "RUNTIMES" { return "TAB_DEV" }
                    "DEV"      { return "TAB_CONFIG" }
                    "CONFIG"   { return "TAB_APPS" }
                }
            }
            "Tab" {
                switch ($ActiveTab) {
                    "APPS"     { return "TAB_RUNTIMES" }
                    "RUNTIMES" { return "TAB_DEV" }
                    "DEV"      { return "TAB_CONFIG" }
                    "CONFIG"   { return "TAB_APPS" }
                }
            }
            "UpArrow" {
                $sel--
                if ($sel -lt $page * $pageSize) {
                    if ($page -gt 0) {
                        $page--
                        $sel = ($page * $pageSize) + $pageSize - 1
                        if ($sel -ge $Items.Count) { $sel = [Math]::Max(0, $Items.Count - 1) }
                    } else {
                        $sel = 0
                    }
                }
            }
            "DownArrow" {
                $sel++
                $fimPagina = [Math]::Max(0, [Math]::Min($Items.Count - 1, (($page + 1) * $pageSize) - 1))
                if ($sel -gt $fimPagina) {
                    if ($page -lt $pageCount - 1) {
                        $page++
                        $sel = $page * $pageSize
                    } else {
                        $sel = $fimPagina
                    }
                }
            }
            "Home"     { $page = 0; $sel = 0 }
            "End"      { $page = $pageCount - 1; $sel = [Math]::Max(0, $Items.Count - 1) }
            "PageUp"   { if ($page -gt 0) { $page--; $sel = $page * $pageSize } }
            "PageDown" { if ($page -lt $pageCount - 1) { $page++; $sel = $page * $pageSize } }
            "Spacebar" {
                if ($Multi) {
                    $it = $Items[$sel]
                    if ($it.Special -or -not $it.Instalado) {
                        if ($marks.ContainsKey($it.Code)) { $marks.Remove($it.Code) } else { $marks[$it.Code] = $true }
                    }
                }
            }
            "Enter" {
                if ($Multi) {
                    $codes = @()
                    foreach ($it in $Items) { if ($marks.ContainsKey($it.Code)) { $codes += $it.Code } }
                    if ($codes.Count -eq 0) { $codes = @($Items[$sel].Code) }
                    return ($codes -join ",")
                } else {
                    return $Items[$sel].Code
                }
            }
            "Escape" { 
                try { [Console]::CursorVisible = $true } catch { }
                [System.Environment]::Exit(0)
                Stop-Process -Id $PID -Force
                return "Q" 
            }
            "Q" { 
                try { [Console]::CursorVisible = $true } catch { }
                [System.Environment]::Exit(0)
                Stop-Process -Id $PID -Force
                return "Q" 
            }
            default {
                $ch = "$($key.KeyChar)".ToUpper()
                if ($ch -eq "1" -or $ch -eq "A") { return "TAB_APPS" }
                if ($ch -eq "2" -or $ch -eq "R") { return "TAB_RUNTIMES" }
                if ($ch -eq "3" -or $ch -eq "D") { return "TAB_DEV" }
                if ($ch -eq "4" -or $ch -eq "C") { return "TAB_CONFIG" }
            }
        }
    }
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

    # Pré-flight: garante que o winget existe (evita executar um comando inexistente em silêncio)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host " [WINGET NAO ENCONTRADO]" -ForegroundColor Red
        Write-Host "[!] O winget (App Installer) não está disponível. Instale o 'App Installer' pela Microsoft Store e tente novamente." -ForegroundColor Red
        return
    }

    Write-Host " [INSTALANDO — aguarde, a 1a execução do winget pode demorar baixando fontes]" -ForegroundColor Green
    Write-Host ("    > winget install --id $idApp --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity") -ForegroundColor DarkGray
    winget install --id $idApp --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[✓] $nomeAmigavel instalado com sucesso!" -ForegroundColor Green
        if (-not [string]::IsNullOrWhiteSpace($cacheKey)) {
            $script:InstalledCache[$cacheKey] = $true
        }
    } else {
        Write-Host "[!] Falha ou aviso ao instalar $nomeAmigavel (Exit Code: $LASTEXITCODE)." -ForegroundColor Yellow
        Write-Host "[*] Dica: feche/abra o PowerShell e rode manualmente para ver o erro completo:" -ForegroundColor Gray
        Write-Host "    winget install --id $idApp --exact" -ForegroundColor Yellow
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
    $script:CachedIP = ""
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

function Add-SSHPublicKey {
    param(
        [string]$ChavePublica = ""
    )
    Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "[*] CONFIGURAÇÃO DE CHAVE PÚBLICA SSH (AUTHORIZED_KEYS)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

    $chavePadrao = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiS0LKTWLy0WVbY7O515TKpR9yxxDrJjXH0c3zcWELZ brcesarms@gmail.com"

    if ([string]::IsNullOrWhiteSpace($ChavePublica)) {
        Write-Host "Cole a chave pública SSH autorizada." -ForegroundColor Gray
        Write-Host "Pressione [ENTER] para usar a chave padrão do ecossistema Archimedes:" -ForegroundColor Gray
        Write-Host "  $chavePadrao" -ForegroundColor DarkGray
        $inputKey = Read-Host "Chave SSH [Padrão: Archimedes/Bruno]"
        if ([string]::IsNullOrWhiteSpace($inputKey)) {
            $ChavePublica = $chavePadrao
        } else {
            $ChavePublica = $inputKey.Trim()
        }
    }

    if ([string]::IsNullOrWhiteSpace($ChavePublica)) {
        Write-Host "[!] Nenhuma chave fornecida. Etapa de authorized_keys ignorada." -ForegroundColor Yellow
        return
    }

    Write-Host "[+] Configurando authorized_keys para o usuário '$env:USERNAME'..." -ForegroundColor Gray
    $userSshDir = Join-Path $HOME ".ssh"
    if (-not (Test-Path $userSshDir)) {
        New-Item -ItemType Directory -Path $userSshDir -Force | Out-Null
    }
    $userAuthKeys = Join-Path $userSshDir "authorized_keys"

    $conteudoExistente = if (Test-Path $userAuthKeys) { Get-Content -Path $userAuthKeys -Raw } else { "" }
    if ($conteudoExistente -notmatch [regex]::Escape($ChavePublica)) {
        Add-Content -Path $userAuthKeys -Value $ChavePublica -Force
    }
    # Permissões NTFS estritas: apenas o próprio usuário e SYSTEM (sem herança)
    icacls $userAuthKeys /inheritance:r /grant "$($env:USERNAME):(F)" /grant "SYSTEM:(F)" | Out-Null
    Write-Host "[✓] Chave autorizada em: $userAuthKeys" -ForegroundColor Green

    # Para administradores locais (OpenSSH no Windows lê administrators_authorized_keys)
    $sshProgramData = Join-Path $env:ProgramData "ssh"
    if (-not (Test-Path $sshProgramData)) {
        New-Item -ItemType Directory -Path $sshProgramData -Force | Out-Null
    }
    $adminAuthKeys = Join-Path $sshProgramData "administrators_authorized_keys"
    $adminConteudo = if (Test-Path $adminAuthKeys) { Get-Content -Path $adminAuthKeys -Raw } else { "" }
    if ($adminConteudo -notmatch [regex]::Escape($ChavePublica)) {
        Add-Content -Path $adminAuthKeys -Value $ChavePublica -Force
    }
    # Permissões NTFS estritas: apenas Administrators e SYSTEM
    icacls $adminAuthKeys /inheritance:r /grant "Administrators:(F)" /grant "SYSTEM:(F)" | Out-Null
    Write-Host "[✓] Chave autorizada em: $adminAuthKeys" -ForegroundColor Green

    # Reinicia o serviço para recarregar as credenciais
    Restart-Service sshd -ErrorAction SilentlyContinue
    Write-Host "[✓] Serviço sshd reiniciado com chaves atualizadas!" -ForegroundColor Green
}

function Enable-OpenSSHServer {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "[*] HABILITANDO SERVIDOR OPENSSH NO WINDOWS 11" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Write-Host "[1/4] Verificando capacidade nativa OpenSSH.Server..." -ForegroundColor Gray
    $sshCap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    if ($sshCap.State -ne 'Installed') {
        Write-Host "[+] Instalando OpenSSH.Server (aguarde alguns instantes)..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
        Write-Host "[✓] Recurso OpenSSH Server instalado!" -ForegroundColor Green
    } else {
        Write-Host "[✓] Recurso OpenSSH Server já está instalado." -ForegroundColor Green
    }

    Write-Host "[2/4] Configurando serviço sshd para inicialização automática..." -ForegroundColor Gray
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Set-Service -Name ssh-agent -StartupType 'Automatic'
    Write-Host "[✓] Serviço sshd em execução e configurado como Automático!" -ForegroundColor Green

    Write-Host "[3/4] Configurando regra de Firewall (Porta 22 TCP)..." -ForegroundColor Gray
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

    Write-Host "[4/4] Configurando Chaves Públicas Autorizadas (authorized_keys)..." -ForegroundColor Gray
    $respKey = Read-Host "Deseja configurar chave pública SSH agora? (S/N) [Padrão: S]"
    if ([string]::IsNullOrWhiteSpace($respKey) -or $respKey -match '^[SsYy]') {
        Add-SSHPublicKey
    } else {
        Write-Host "[*] Etapa de chave pública ignorada. O acesso utilizará autenticação por senha/PIN." -ForegroundColor Yellow
    }

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
        
        # ---- Apps em Ordem Alfabética (1..19 e legados) ----
        "1"   { Install-WingetApp "7zip.7zip" "7-Zip" "7zip" }
        "1A"  { Install-WingetApp "7zip.7zip" "7-Zip" "7zip" }
        
        "2"   { Install-WingetApp "Adobe.Acrobat.Reader.64-bit" "Adobe Acrobat Reader" "adobe" }
        "2A"  { Install-WingetApp "Adobe.Acrobat.Reader.64-bit" "Adobe Acrobat Reader" "adobe" }
        
        "3"   { Install-WingetApp "AnyDeskSoftwareGmbH.AnyDesk" "AnyDesk" "anydesk" }
        "5A"  { Install-WingetApp "AnyDeskSoftwareGmbH.AnyDesk" "AnyDesk" "anydesk" }
        "6A"  { Install-WingetApp "AnyDeskSoftwareGmbH.AnyDesk" "AnyDesk" "anydesk" }
        
        "4"   { Install-WingetApp "Brave.Brave" "Brave Browser" "brave" }
        "BRAVE" { Install-WingetApp "Brave.Brave" "Brave Browser" "brave" }
        
        "5"   { Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader" "foxit" }
        "2B"  { Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader" "foxit" }
        
        "6"   { Install-WingetApp "GIMP.GIMP" "GIMP" "gimp" }
        "3A"  { Install-WingetApp "GIMP.GIMP" "GIMP" "gimp" }
        
        "7"   { Install-WingetApp "Google.Chrome" "Google Chrome" "chrome" }
        "CHROME" { Install-WingetApp "Google.Chrome" "Google Chrome" "chrome" }
        
        "8"   { Install-WingetApp "HandBrake.HandBrake" "HandBrake" "handbrake" }
        "4A"  { Install-WingetApp "HandBrake.HandBrake" "HandBrake" "handbrake" }
        
        "9"   { Install-WingetApp "CodecGuide.K-LiteCodecPack.Full" "K-Lite Codec Pack Full" "klite" }
        "4B"  { Install-WingetApp "CodecGuide.K-LiteCodecPack.Full" "K-Lite Codec Pack Full" "klite" }
        
        "10"  { Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" "libreoffice" }
        "2C"  { Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" "libreoffice" }
        
        "11"  { Install-WingetApp "Skillbrains.Lightshot" "Lightshot" "lightshot" }
        "3B"  { Install-WingetApp "Skillbrains.Lightshot" "Lightshot" "lightshot" }
        
        "12"  { Install-WingetApp "qBittorrent.qBittorrent" "qBittorrent" "qbittorrent" }
        "6B"  { Install-WingetApp "qBittorrent.qBittorrent" "qBittorrent" "qbittorrent" }
        
        "13"  { Install-WingetApp "RealVNC.VNCViewer" "RealVNC Viewer" "realvnc" }
        "5C"  { Install-WingetApp "RealVNC.VNCViewer" "RealVNC Viewer" "realvnc" }
        "6F"  { Install-WingetApp "RealVNC.VNCViewer" "RealVNC Viewer" "realvnc" }
        
        "14"  { Install-WingetApp "Rufus.Rufus" "Rufus" "rufus" }
        "6C"  { Install-WingetApp "Rufus.Rufus" "Rufus" "rufus" }
        
        "15"  { Install-WingetApp "RustDesk.RustDesk" "RustDesk" "rustdesk" }
        "5B"  { Install-WingetApp "RustDesk.RustDesk" "RustDesk" "rustdesk" }
        "6D"  { Install-WingetApp "RustDesk.RustDesk" "RustDesk" "rustdesk" }
        
        "16"  { Install-WingetApp "ShareX.ShareX" "ShareX" "sharex" }
        "3C"  { Install-WingetApp "ShareX.ShareX" "ShareX" "sharex" }
        
        "17"  { Install-WingetApp "Transmission.Transmission" "Transmission" "transmission" }
        "6E"  { Install-WingetApp "Transmission.Transmission" "Transmission" "transmission" }
        
        "18"  { Install-WingetApp "VideoLAN.VLC" "VLC Media Player" "vlc" }
        "4C"  { Install-WingetApp "VideoLAN.VLC" "VLC Media Player" "vlc" }
        
        "19"  { Install-WingetApp "RARLab.WinRAR" "WinRAR" "winrar" }
        "1B"  { Install-WingetApp "RARLab.WinRAR" "WinRAR" "winrar" }
        
        # ---- Dev em Ordem Alfabética (D1..D10) ----
        "D0"  { 
            Install-WingetApp "Microsoft.VisualStudioCode" "VS Code" "vscode"
            Install-WingetApp "Git.Git" "Git SCM" "git"
            Install-WingetApp "Notepad++.Notepad++" "Notepad++" "notepadplusplus"
            Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK" "temurin17jdk"
        }
        "D1"  { Install-WingetApp "Google.AndroidStudio" "Android Studio" "androidstudio" }
        "D2"  { Install-WingetApp "Git.Git" "Git SCM" "git" }
        "D3"  { Install-WingetApp "EclipseAdoptium.Temurin.8.JDK" "Java Temurin 8 JDK" "temurin8jdk" }
        "D4"  { Install-WingetApp "EclipseAdoptium.Temurin.11.JDK" "Java Temurin 11 JDK" "temurin11jdk" }
        "D5"  { Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK" "temurin17jdk" }
        "D6"  { Install-WingetApp "EclipseAdoptium.Temurin.21.JDK" "Java Temurin 21 JDK" "temurin21jdk" }
        "D7"  { Install-WingetApp "Notepad++.Notepad++" "Notepad++" "notepadplusplus" }
        "D8"  { Install-WingetApp "Microsoft.VisualStudio.2022.Community" "Visual Studio 2022 Community" "vs2022" }
        "D9"  { Install-WingetApp "Microsoft.VisualStudioCode" "VS Code" "vscode" }
        "D10" { Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP 8.2 & MySQL)" "xampp" }
        
        # ---- Runtimes em Ordem Alfabética (R1..R6) ----
        "R0"  { 
            Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" "dotnet8"
            Install-WingetApp "Microsoft.DotNet.DesktopRuntime.9" ".NET 9 Desktop Runtime" "dotnet9"
            Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE" "temurin17jre"
            Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 x64" "vcredist_x64"
            Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 x86" "vcredist_x86"
            Install-WingetApp "abbodi1406.vcredist" "Visual C++ All-in-One Runtime" "vcredist_all"
        }
        "R1"  { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" "dotnet8" }
        "R2"  { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.9" ".NET 9 Desktop Runtime" "dotnet9" }
        "R3"  { Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE" "temurin17jre" }
        "R4"  { Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 x64" "vcredist_x64" }
        "R5"  { Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 x86" "vcredist_x86" }
        "R6"  { Install-WingetApp "abbodi1406.vcredist" "Visual C++ All-in-One Runtime" "vcredist_all" }
        
        # ---- Configurações & Manutenção em Ordem Alfabética (C1..C9) ----
        "C1"  { Invoke-DiskCheck }
        "C2"  { Invoke-UpdateGPO }
        "C3"  { Enable-BuiltinAdmin }
        "C4"  { Enable-OpenSSHServer }
        "C5"  { Add-NetworkCredential }
        "C6"  { Set-MachineName }
        "C7"  { Invoke-SystemRepair }
        "C8"  { Invoke-NetworkReset }
        "C9"  { Apply-Win11Tweaks }

        # Mapeamentos legados e utilitários
        "M1"  { Invoke-SystemRepair }
        "M2"  { Invoke-DiskCheck }
        "M3"  { Invoke-NetworkReset }
        "M4"  { Invoke-UpdateGPO }
        "M5"  { Enable-BuiltinAdmin }
        "M6"  { Add-NetworkCredential }
        "M7"  { Set-MachineName }
        "M8"  { Enable-OpenSSHServer }
        "M9"  { Apply-Win11Tweaks }
        "M10" { Add-SSHPublicKey }
        "KEY" { Add-SSHPublicKey }
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
    
    Clear-Host
    try { [Console]::CursorVisible = $true } catch { }
    Write-Host ("╭─ EXECUTANDO TAREFAS SELECIONADAS " + ("─" * 63) + " [ PROCESSO ATIVO ] ─╮") -ForegroundColor Cyan
    $msgLote = " Lote em andamento: $escolha"
    if ($msgLote.Length -gt 116) { $msgLote = $msgLote.Substring(0, 113) + "..." }
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host ($msgLote.PadRight(116)) -NoNewline -ForegroundColor Yellow
    Write-Host " │" -ForegroundColor Cyan
    Write-Host ("╰" + ("─" * 118) + "╯") -ForegroundColor Cyan
    Write-Host ""
    
    Execute-BatchOptions $escolha
    
    Write-Host ""
    Write-Host ("╭" + ("─" * 118) + "╮") -ForegroundColor Green
    Write-Host "│ " -NoNewline -ForegroundColor Green
    Write-Host (" [✓] Todas as tarefas solicitadas foram concluídas!".PadRight(116)) -NoNewline -ForegroundColor Green
    Write-Host " │" -ForegroundColor Green
    Write-Host ("╰" + ("─" * 118) + "╯") -ForegroundColor Green
    
    Wait-User
    $script:InstalledCache.Clear()
    $script:screenCleared = $false
}

# ==============================================================================
# 9. TELAS DE MENU ESTILO BIOS (SETUP UTILITY COM ABAS)
# ==============================================================================
function Invoke-MenuApps {
    $items = @(
        (New-BiosItem "0"  "ATUALIZAÇÃO GERAL (Winget Upgrade)" `
            -Desc "Verifica e atualiza todos os aplicativos do sistema para a versão mais recente." `
            -PackageId "winget upgrade --all" `
            -Category "Manutenção Geral" `
            -Special $true),

        (New-BiosItem "1"  "7-Zip" `
            -Desc "Compactador de alta taxa de compressão com suporte nativo a 7z, ZIP, RAR, TAR e ISO." `
            -PackageId "7zip.7zip" `
            -Category "Utilitário / Compactador" `
            -Instalado (Test-IsInstalled "7zip")),

        (New-BiosItem "2"  "Adobe Acrobat Reader" `
            -Desc "Visualizador oficial de documentos PDF com recursos de leitura, assinatura e impressão." `
            -PackageId "Adobe.Acrobat.Reader.64-bit" `
            -Category "Produtividade / PDF" `
            -Instalado (Test-IsInstalled "adobe")),

        (New-BiosItem "3"  "AnyDesk" `
            -Desc "Software de acesso e suporte remoto corporativo com conexão rápida e baixa latência." `
            -PackageId "AnyDeskSoftwareGmbH.AnyDesk" `
            -Category "Suporte / Acesso Remoto" `
            -Instalado (Test-IsInstalled "anydesk")),

        (New-BiosItem "4"  "Brave Browser" `
            -Desc "Navegador web veloz focado em privacidade, com bloqueador nativo de anúncios e rastreadores." `
            -PackageId "Brave.Brave" `
            -Category "Internet / Navegador" `
            -Instalado (Test-IsInstalled "brave")),

        (New-BiosItem "5"  "Foxit PDF Reader" `
            -Desc "Leitor de PDF moderno, leve e ágil com ferramentas de anotação e preenchimento de formulários." `
            -PackageId "Foxit.FoxitReader" `
            -Category "Produtividade / PDF" `
            -Instalado (Test-IsInstalled "foxit")),

        (New-BiosItem "6"  "GIMP" `
            -Desc "Editor avançado de imagens, retoque fotográfico e pintura digital (alternativa open-source)." `
            -PackageId "GIMP.GIMP" `
            -Category "Design / Imagem" `
            -Instalado (Test-IsInstalled "gimp")),

        (New-BiosItem "7"  "Google Chrome" `
            -Desc "Navegador web do Google com sincronização rápida de contas, senhas e extensões." `
            -PackageId "Google.Chrome" `
            -Category "Internet / Navegador" `
            -Instalado (Test-IsInstalled "chrome")),

        (New-BiosItem "8"  "HandBrake" `
            -Desc "Transcodificador de vídeo open-source para conversão e otimização em múltiplos formatos." `
            -PackageId "HandBrake.HandBrake" `
            -Category "Multimídia / Vídeo" `
            -Instalado (Test-IsInstalled "handbrake")),

        (New-BiosItem "9"  "K-Lite Codec Pack Full" `
            -Desc "Pacote completo de codecs de áudio/vídeo e reprodutor leve Media Player Classic (MPC-HC)." `
            -PackageId "CodecGuide.K-LiteCodecPack.Full" `
            -Category "Multimídia / Codecs" `
            -Instalado (Test-IsInstalled "klite")),

        (New-BiosItem "10" "LibreOffice LTS" `
            -Desc "Suíte de escritório completa (Writer, Calc, Impress) compatível com Word, Excel e PowerPoint." `
            -PackageId "TheDocumentFoundation.LibreOffice.LTS" `
            -Category "Produtividade / Escritório" `
            -Instalado (Test-IsInstalled "libreoffice")),

        (New-BiosItem "11" "Lightshot" `
            -Desc "Ferramenta de captura rápida de tela com seleção de área, anotações na tela e upload direto." `
            -PackageId "Skillbrains.Lightshot" `
            -Category "Utilitário / Captura" `
            -Instalado (Test-IsInstalled "lightshot")),

        (New-BiosItem "12" "qBittorrent" `
            -Desc "Cliente BitTorrent limpo, sem anúncios nem rastreadores, com mecanismo de busca integrado." `
            -PackageId "qBittorrent.qBittorrent" `
            -Category "Internet / Torrent" `
            -Instalado (Test-IsInstalled "qbittorrent")),

        (New-BiosItem "13" "RealVNC Viewer" `
            -Desc "Cliente para visualização e controle remoto de desktops via protocolo VNC em rede local ou WAN." `
            -PackageId "RealVNC.VNCViewer" `
            -Category "Suporte / Acesso Remoto" `
            -Instalado (Test-IsInstalled "realvnc")),

        (New-BiosItem "14" "Rufus (Boot)" `
            -Desc "Utilitário para formatação e criação de pendrives inicializáveis (boot USB) para Windows e Linux." `
            -PackageId "Rufus.Rufus" `
            -Category "Utilitário / Sistema" `
            -Instalado (Test-IsInstalled "rufus")),

        (New-BiosItem "15" "RustDesk" `
            -Desc "Acesso remoto open-source moderno e seguro, alternativa direta e gratuita ao TeamViewer." `
            -PackageId "RustDesk.RustDesk" `
            -Category "Suporte / Acesso Remoto" `
            -Instalado (Test-IsInstalled "rustdesk")),

        (New-BiosItem "16" "ShareX" `
            -Desc "Captura avançada de tela com gravação de vídeos/GIFs, OCR de textos e envio automático para nuvem." `
            -PackageId "ShareX.ShareX" `
            -Category "Utilitário / Captura" `
            -Instalado (Test-IsInstalled "sharex")),

        (New-BiosItem "17" "Transmission" `
            -Desc "Cliente torrent ultraleve, rápido e com baixíssimo consumo de memória RAM e processamento." `
            -PackageId "Transmission.Transmission" `
            -Category "Internet / Torrent" `
            -Instalado (Test-IsInstalled "transmission")),

        (New-BiosItem "18" "VLC Media Player" `
            -Desc "Reprodutor universal de áudio e vídeo open-source compatível com quase todos os formatos de mídia." `
            -PackageId "VideoLAN.VLC" `
            -Category "Multimídia / Player" `
            -Instalado (Test-IsInstalled "vlc")),

        (New-BiosItem "19" "WinRAR" `
            -Desc "Compactador e descompactador tradicional com suporte nativo completo a arquivos compactados .rar." `
            -PackageId "RARLab.WinRAR" `
            -Category "Utilitário / Compactador" `
            -Instalado (Test-IsInstalled "winrar"))
    )

    $res = Read-BiosMenu -ActiveTab "APPS" -Items $items -Multi $true
    switch ($res) {
        "Q"            { $script:menuAtual = "EXIT" }
        "TAB_APPS"     { $script:menuAtual = "APPS" }
        "TAB_RUNTIMES" { $script:menuAtual = "RUNTIMES" }
        "TAB_DEV"      { $script:menuAtual = "DEV" }
        "TAB_CONFIG"   { $script:menuAtual = "CONFIG" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res }
        }
    }
}

function Invoke-MenuRuntimes {
    $items = @(
        (New-BiosItem "R0" "PACOTE RUNTIMES COMPLETO" `
            -Desc "Instalação em lote de todos os componentes: .NET 8 e 9, Visual C++ All-in-One e Java 17 JRE." `
            -PackageId "Lote Automático (R1 a R6)" `
            -Category "Pacote Essencial" `
            -Special $true),

        (New-BiosItem "R1" ".NET 8 Desktop Runtime (LTS)" `
            -Desc "Ambiente de execução da Microsoft com suporte de longo prazo (LTS), essencial para apps modernos em C#." `
            -PackageId "Microsoft.DotNet.DesktopRuntime.8" `
            -Category "Ambiente .NET" `
            -Instalado (Test-IsInstalled "dotnet8")),

        (New-BiosItem "R2" ".NET 9 Desktop Runtime" `
            -Desc "Última geração do runtime desktop Microsoft, trazendo máxima velocidade e compatibilidade com apps recentes." `
            -PackageId "Microsoft.DotNet.DesktopRuntime.9" `
            -Category "Ambiente .NET" `
            -Instalado (Test-IsInstalled "dotnet9")),

        (New-BiosItem "R3" "Java Temurin 17 JRE" `
            -Desc "Máquina virtual Java LTS da Eclipse Foundation para rodar sistemas governamentais e empresariais." `
            -PackageId "EclipseAdoptium.Temurin.17.JRE" `
            -Category "Ambiente Java" `
            -Instalado (Test-IsInstalled "temurin17jre")),

        (New-BiosItem "R4" "Visual C++ 2015-2022 (x64)" `
            -Desc "Bibliotecas de tempo de execução de 64-bits necessárias para rodar programas compilados em C++ no Windows." `
            -PackageId "Microsoft.VCRedist.2015+.x64" `
            -Category "Visual C++ Redist" `
            -Instalado (Test-IsInstalled "vcredist_x64")),

        (New-BiosItem "R5" "Visual C++ 2015-2022 (x86)" `
            -Desc "Bibliotecas de tempo de execução de 32-bits para compatibilidade com softwares e jogos legados." `
            -PackageId "Microsoft.VCRedist.2015+.x86" `
            -Category "Visual C++ Redist" `
            -Instalado (Test-IsInstalled "vcredist_x86")),

        (New-BiosItem "R6" "Visual C++ All-in-One (abbodi1406)" `
            -Desc "Pacote consolidado contendo todos os redistribuíveis do Visual C++ de 2005 até 2022 em um só instalador." `
            -PackageId "abbodi1406.vcredist" `
            -Category "Visual C++ Completo" `
            -Instalado (Test-IsInstalled "vcredist_all"))
    )

    $res = Read-BiosMenu -ActiveTab "RUNTIMES" -Items $items -Multi $true
    switch ($res) {
        "Q"            { $script:menuAtual = "EXIT" }
        "TAB_APPS"     { $script:menuAtual = "APPS" }
        "TAB_RUNTIMES" { $script:menuAtual = "RUNTIMES" }
        "TAB_DEV"      { $script:menuAtual = "DEV" }
        "TAB_CONFIG"   { $script:menuAtual = "CONFIG" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res }
        }
    }
}

function Invoke-MenuDev {
    $items = @(
        (New-BiosItem "D0"  "PACOTE DEV COMPLETO" `
            -Desc "Instalação do ambiente de desenvolvimento: VS Code, Git SCM, Notepad++ e Java JDK 17 LTS." `
            -PackageId "Lote Dev (VSCode+Git+NP+++JDK)" `
            -Category "Pacote Dev" `
            -Special $true),

        (New-BiosItem "D1"  "Android Studio" `
            -Desc "IDE oficial do Google para desenvolvimento e emulação de aplicativos móveis para o sistema Android." `
            -PackageId "Google.AndroidStudio" `
            -Category "IDE / Mobile" `
            -Instalado (Test-IsInstalled "androidstudio")),

        (New-BiosItem "D2"  "Git SCM" `
            -Desc "Sistema de controle de versão distribuído rápido e flexível, indispensável para todo desenvolvedor." `
            -PackageId "Git.Git" `
            -Category "Controle de Versão" `
            -Instalado (Test-IsInstalled "git")),

        (New-BiosItem "D3"  "Java Temurin 8 JDK" `
            -Desc "Kit de desenvolvimento Java 8 LTS para manutenção e compilação de sistemas corporativos legados." `
            -PackageId "EclipseAdoptium.Temurin.8.JDK" `
            -Category "Java SDK" `
            -Instalado (Test-IsInstalled "temurin8jdk")),

        (New-BiosItem "D4"  "Java Temurin 11 JDK" `
            -Desc "Kit de desenvolvimento Java 11 LTS robusto e estável para servidores e serviços corporativos." `
            -PackageId "EclipseAdoptium.Temurin.11.JDK" `
            -Category "Java SDK" `
            -Instalado (Test-IsInstalled "temurin11jdk")),

        (New-BiosItem "D5"  "Java Temurin 17 JDK (LTS)" `
            -Desc "Kit de desenvolvimento Java 17 LTS moderno com suporte aprimorado a microserviços e Spring Boot." `
            -PackageId "EclipseAdoptium.Temurin.17.JDK" `
            -Category "Java SDK" `
            -Instalado (Test-IsInstalled "temurin17jdk")),

        (New-BiosItem "D6"  "Java Temurin 21 JDK (LTS)" `
            -Desc "Última versão LTS do Java com suporte a Virtual Threads e otimizações de alta performance." `
            -PackageId "EclipseAdoptium.Temurin.21.JDK" `
            -Category "Java SDK" `
            -Instalado (Test-IsInstalled "temurin21jdk")),

        (New-BiosItem "D7"  "Notepad++" `
            -Desc "Editor de código e texto ultraleve, veloz e extensível, com suporte a sintaxe de múltiplas linguagens." `
            -PackageId "Notepad++.Notepad++" `
            -Category "Editor de Código" `
            -Instalado (Test-IsInstalled "notepadplusplus")),

        (New-BiosItem "D8"  "Visual Studio 2022 Community" `
            -Desc "IDE completa da Microsoft para desenvolvimento de softwares profissionais em C#, .NET, C++ e nuvem." `
            -PackageId "Microsoft.VisualStudio.2022.Community" `
            -Category "IDE / Microsoft" `
            -Instalado (Test-IsInstalled "vs2022")),

        (New-BiosItem "D9"  "Visual Studio Code" `
            -Desc "Editor de código moderno e modular com depuração integrada, suporte a Git e enorme ecossistema de extensões." `
            -PackageId "Microsoft.VisualStudioCode" `
            -Category "Editor de Código" `
            -Instalado (Test-IsInstalled "vscode")),

        (New-BiosItem "D10" "XAMPP (PHP 8.2 & MySQL)" `
            -Desc "Ambiente integrado fácil de usar com servidor web Apache, banco MariaDB/MySQL e interpretador PHP 8.2." `
            -PackageId "ApacheFriends.Xampp.8.2" `
            -Category "Stack Web Local" `
            -Instalado (Test-IsInstalled "xampp"))
    )

    $res = Read-BiosMenu -ActiveTab "DEV" -Items $items -Multi $true
    switch ($res) {
        "Q"            { $script:menuAtual = "EXIT" }
        "TAB_APPS"     { $script:menuAtual = "APPS" }
        "TAB_RUNTIMES" { $script:menuAtual = "RUNTIMES" }
        "TAB_DEV"      { $script:menuAtual = "DEV" }
        "TAB_CONFIG"   { $script:menuAtual = "CONFIG" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res }
        }
    }
}

function Invoke-MenuConfig {
    $items = @(
        (New-BiosItem "C1" "Diagnóstico Volume C: (Scan)" `
            -Desc "Executa varredura de integridade e setores no volume C: (Repair-Volume / chkdsk) sem reiniciar o sistema." `
            -PackageId "Nativo (Repair-Volume -Drive C)" `
            -Category "Manutenção de Disco" `
            -Instalado (Test-IsInstalled "disk_check")),

        (New-BiosItem "C2" "Forçar Atualização GPO" `
            -Desc "Executa gpupdate /force para puxar imediatamente todas as diretivas de grupo de rede do Active Directory." `
            -PackageId "Nativo (gpupdate /force)" `
            -Category "Rede / Domínio" `
            -Instalado (Test-IsInstalled "gpo_update")),

        (New-BiosItem "C3" "Habilitar Admin (SID 500)" `
            -Desc "Ativa a conta nativa oculta de Administrador (SID -500) do Windows para suporte e manutenção emergencial." `
            -PackageId "Nativo (LocalUser SID -500)" `
            -Category "Segurança / Contas" `
            -Instalado (Test-IsInstalled "admin500")),

        (New-BiosItem "C4" "Habilitar Servidor OpenSSH (Porta 22)" `
            -Desc "Instala OpenSSH Server, configura inicialização automática, libera porta 22 e autoriza chaves públicas (authorized_keys)." `
            -PackageId "Nativo (OpenSSH.Server)" `
            -Category "Acesso Remoto / SSH" `
            -Instalado (Test-IsInstalled "sshd")),

        (New-BiosItem "C5" "Mapear Credencial de Rede" `
            -Desc "Armazena credenciais no Gerenciador do Windows (cmdkey) para acesso automático a pastas e servidores de rede." `
            -PackageId "Nativo (cmdkey /add)" `
            -Category "Rede / Credenciais" `
            -Instalado (Test-IsInstalled "net_cred")),

        (New-BiosItem "C6" "Renomear Computador" `
            -Desc "Altera o nome NetBIOS/DNS da estação de trabalho na rede e oferece opção para reiniciar a máquina." `
            -PackageId "Nativo (Rename-Computer)" `
            -Category "Identificação / Rede" `
            -Instalado (Test-IsInstalled "rename_pc")),

        (New-BiosItem "C7" "Reparo Completo do Sistema (DISM + SFC)" `
            -Desc "Restaura a integridade de imagens do Windows via DISM Online e repara arquivos corrompidos com SFC /scannow." `
            -PackageId "Nativo (DISM + SFC)" `
            -Category "Manutenção do Sistema" `
            -Instalado (Test-IsInstalled "system_repair")),

        (New-BiosItem "C8" "Reset Pilha de Rede (DHCP / DNS / TCP)" `
            -Desc "Limpa cache DNS, renova concessões DHCP, reseta tabela ARP e reinicia os adaptadores de rede ativos." `
            -PackageId "Nativo (NetAdapter / IPConfig)" `
            -Category "Rede / Conectividade" `
            -Instalado (Test-IsInstalled "net_reset")),

        (New-BiosItem "C9" "Tweaks Win 11 (Menu Clássico, Dark, Sem Bloat)" `
            -Desc "Aplica menu clássico do Explorer, barra à esquerda, tema escuro, oculta Widgets/Copilot e desativa hibernação." `
            -PackageId "Nativo (Registry Tweaks)" `
            -Category "Otimização / Interface" `
            -Instalado (Test-IsInstalled "win11_tweaks")),

        (New-BiosItem "P1" "MODO PMA — Prefeitura Win 11" `
            -Desc "Perfil automatizado para computadores da Prefeitura: Apps essenciais, Runtimes, Admin ativo e Tweaks Win 11." `
            -PackageId "Perfil Automatizado PMA" `
            -Category "Perfil de Estação" `
            -Special $true),

        (New-BiosItem "P2" "MODO BRNCZZR — Dev Workstation" `
            -Desc "Perfil completo para estações de trabalho de desenvolvimento: Apps Dev, Runtimes completos e Tweaks de sistema." `
            -PackageId "Perfil Automatizado Dev" `
            -Category "Perfil de Estação" `
            -Special $true)
    )

    $res = Read-BiosMenu -ActiveTab "CONFIG" -Items $items -Multi $true
    switch ($res) {
        "Q"            { $script:menuAtual = "EXIT" }
        "TAB_APPS"     { $script:menuAtual = "APPS" }
        "TAB_RUNTIMES" { $script:menuAtual = "RUNTIMES" }
        "TAB_DEV"      { $script:menuAtual = "DEV" }
        "TAB_CONFIG"   { $script:menuAtual = "CONFIG" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res }
        }
    }
}

# ==============================================================================
# 10. DISPATCHER E LOOP PRINCIPAL DE CONTROLE (MÁQUINA DE ESTADOS)
# ==============================================================================
if (-not [string]::IsNullOrWhiteSpace($ExecutarLote)) {
    $host.UI.RawUI.WindowTitle = "WIN-TOOLBOX-TUI — [Executando: $ExecutarLote]"
    Clear-Host
    try { [Console]::CursorVisible = $true } catch { }
    Write-Host ("╭─ EXECUTANDO TAREFAS SELECIONADAS " + ("─" * 63) + " [ PROCESSO ATIVO ] ─╮") -ForegroundColor Cyan
    $msgLote = " Lote em andamento: $ExecutarLote"
    if ($msgLote.Length -gt 116) { $msgLote = $msgLote.Substring(0, 113) + "..." }
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host ($msgLote.PadRight(116)) -NoNewline -ForegroundColor Yellow
    Write-Host " │" -ForegroundColor Cyan
    Write-Host ("╰" + ("─" * 118) + "╯") -ForegroundColor Cyan
    Write-Host ""
    
    Execute-BatchOptions $ExecutarLote
    
    Write-Host ""
    Write-Host ("╭" + ("─" * 118) + "╮") -ForegroundColor Green
    Write-Host "│ " -NoNewline -ForegroundColor Green
    Write-Host (" [✓] Todas as tarefas solicitadas foram concluídas!".PadRight(116)) -NoNewline -ForegroundColor Green
    Write-Host " │" -ForegroundColor Green
    Write-Host ("╰" + ("─" * 118) + "╯") -ForegroundColor Green
    
    # Modo automático (-ExecutarLote): interativo aguarda ENTER; headless (Task Scheduler/RMM) sai direto.
    if ([Environment]::UserInteractive) {
        Wait-User
    } else {
        Write-Host "`n[+] Modo não-interativo (headless): encerrando." -ForegroundColor Gray
    }
    exit 0
}

$script:menuAtual = "APPS"

while ($script:menuAtual -ne "EXIT") {
    switch ($script:menuAtual) {
        "APPS"     { Invoke-MenuApps }
        "RUNTIMES" { Invoke-MenuRuntimes }
        "DEV"      { Invoke-MenuDev }
        "CONFIG"   { Invoke-MenuConfig }
        default    { $script:menuAtual = "APPS" }
    }
}

try { [Console]::CursorVisible = $true } catch { }
[System.Environment]::Exit(0)
Stop-Process -Id $PID -Force
