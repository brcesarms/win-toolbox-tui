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
# 3. UTILITÁRIO DE ESPERA (WAIT)
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
        [bool]$Instalado = $false,
        [bool]$Special = $false
    )
    if ($Special) { $Instalado = $false }
    return @{ Code = $Code; Text = $Text; Instalado = $Instalado; Special = $Special }
}

function Show-BiosScreen {
    param(
        [string]$ScreenTitle,
        [object[]]$Items,
        [int]$Sel,
        [hashtable]$Marks,
        [int]$Page = 0,
        [int]$PageSize = 17,
        [int]$PageCount = 1,
        [bool]$Multi = $true,
        [string[]]$Shortcuts = @()
    )
    Clear-Host
    $totalWidth = 90        # largura total da caixa
    $inner = $totalWidth - 4 # conteúdo interno (86) entre "║ " e " ║"
    $esc = [char]27
    $bold = "$esc[1m"
    $reset = "$esc[0m"

    # ---- topo estilo BIOS ----
    Write-Host ("╔" + ("═" * ($totalWidth - 2)) + "╗") -ForegroundColor Cyan
    $topo = (" WIN-TOOLBOX TUI · Setup Utility" + (" " * ($inner - 38 - 15)) + " [ WINDOWS 11 ]")
    Write-Host "║ $($topo.PadRight($inner)) ║" -ForegroundColor Cyan
    Write-Host ("╠" + ("═" * ($totalWidth - 2)) + "╣") -ForegroundColor Cyan

    # ---- título da tela (amarelo centralizado) ----
    $titleText = " $($ScreenTitle.ToUpper()) "
    $pad = [Math]::Max(0, [int](($inner - $titleText.Length) / 2))
    $hl = ((" " * $pad) + $titleText).PadRight($inner)
    Write-Host "║ " -NoNewline -ForegroundColor Cyan
    Write-Host ("$bold$hl$reset") -NoNewline -ForegroundColor Yellow
    Write-Host " ║" -ForegroundColor Cyan

    # ---- legenda (verde = instalado · cinza = pendente · marcados) ----
    $legend = " [✓] Verde = INSTALADO   ·   [ ] cinza = pendente   ·   marcados p/ instalar: $($Marks.Count)"
    Write-Host "║ $($legend.PadRight($inner)) ║" -ForegroundColor DarkGray

    # ---- itens da página atual ----
    $start = $Page * $PageSize
    $end = [Math]::Min($Items.Count, $start + $PageSize)
    for ($i = $start; $i -lt $end; $i++) {
        $it = $Items[$i]
        $mark = " "
        if ($Marks.ContainsKey($it.Code)) { $mark = "✓" }
        $cursor = "  "
        if ($i -eq $Sel) { $cursor = "► " }
        $texto = "$cursor[$mark] $($it.Code.PadRight(4)) $($it.Text)"
        $sufixo = ""
        $cor = "Gray"
        if ($it.Special) {
            $cor = "Yellow"
        } elseif ($it.Instalado) {
            $cor = "Green"
            $sufixo = "[INSTALADO]"
        }
        $maxTexto = $inner - $sufixo.Length
        if ($texto.Length -gt $maxTexto) {
            $texto = $texto.Substring(0, [Math]::Max(0, $maxTexto - 1)) + "…"
        }
        $linha = $texto.PadRight($inner - $sufixo.Length) + $sufixo

        Write-Host "║ " -NoNewline -ForegroundColor Cyan
        if ($i -eq $Sel) {
            Write-Host ($linha.PadRight($inner)) -NoNewline -BackgroundColor Green -ForegroundColor Black
        } else {
            Write-Host ($linha.PadRight($inner)) -NoNewline -ForegroundColor $cor
        }
        Write-Host " ║" -ForegroundColor Cyan
    }

    # ---- rodapé: dicas + paginação + telemetria ----
    Write-Host ("╠" + ("═" * ($totalWidth - 2)) + "╣") -ForegroundColor Cyan
    if ($Multi) {
        $dica = " ↑↓ mover · Espaço marcar [✓] · Enter executar · Esc voltar · Q sair"
    } else {
        $dica = " ↑↓ mover · Enter abrir · Esc voltar · Q sair"
    }
    if ($PageCount -gt 1) { $dica += "  ·  Página $($Page + 1)/$PageCount" }
    if ($Shortcuts.Count -gt 0) { $dica += "  ·  atalhos: $($Shortcuts -join '/')" }
    $data = (Get-Date).ToString("dd/MM/yyyy")
    $info = " Data: $data | Computador: $env:computername | Usuário: $env:username"
    Write-Host "║ $($dica.PadRight($inner)) ║" -ForegroundColor Cyan
    Write-Host "║ $($info.PadRight($inner)) ║" -ForegroundColor DarkGray
    Write-Host ("╚" + ("═" * ($totalWidth - 2)) + "╝") -ForegroundColor Cyan
}

function Read-BiosMenu {
    param(
        [Parameter(Mandatory=$true)] [string]$Title,
        [Parameter(Mandatory=$true)] [object[]]$Items,
        [bool]$Multi = $true,
        [string[]]$Shortcuts = @()
    )

    $sel = 0
    $marks = @{}
    $pageSize = 17
    $pageCount = [Math]::Max(1, [Math]::Ceiling($Items.Count / $pageSize))
    $page = 0

    while ($true) {
        Show-BiosScreen -ScreenTitle $Title -Items $Items -Sel $sel -Marks $marks `
            -Page $page -PageSize $pageSize -PageCount $pageCount -Multi $Multi -Shortcuts $Shortcuts

        # Fallback para hosts sem ReadKey (pede códigos por texto)
        try {
            $key = [Console]::ReadKey($true)
        } catch {
            $resp = Read-Host "Digite codigos (ex: 1A,2C) ou Q para sair"
            $respU = $resp.Trim().ToUpper()
            if ($respU -eq "Q") { return "Q" }
            return $respU
        }

        switch ($key.Key) {
            "UpArrow" {
                $sel--
                if ($sel -lt $page * $pageSize) {
                    if ($page -gt 0) {
                        $page--
                        $sel = ($page * $pageSize) + $pageSize - 1
                        if ($sel -ge $Items.Count) { $sel = $Items.Count - 1 }
                    } else {
                        $sel = 0
                    }
                }
            }
            "DownArrow" {
                $sel++
                $fimPagina = [Math]::Min($Items.Count, (($page + 1) * $pageSize) - 1)
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
            "End"      { $page = $pageCount - 1; $sel = $Items.Count - 1 }
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
            "Escape" { return "ESC" }
            "Q"      { return "Q" }
            default {
                $ch = "$($key.KeyChar)".ToUpper()
                if ($ch -and ($Shortcuts -contains $ch)) { return $ch }
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
    
    # Execução sempre in-process (padrão da indústria: WinUtil, MAS, winget-install).
    # Sem Start-Process/janela filha — um único caminho, robusto no one-liner irm | iex.
    Clear-Host
    Write-Host ("╭─ EXECUTANDO TAREFAS SELECIONADAS " + ("─" * 39) + " [ PROCESSO ATUAL ] ─╮") -ForegroundColor Cyan
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host (" Lote em andamento: $escolha".PadRight(88)) -NoNewline -ForegroundColor Yellow
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    Write-Host ""
    
    Execute-BatchOptions $escolha
    Wait-User
    
    $script:InstalledCache.Clear()
}

# ==============================================================================
# 9. TELAS DE MENU ESTILO BIOS (SETUP UTILITY)
# ==============================================================================
function Invoke-MenuPrincipal {
    $items = @(
        (New-BiosItem "SOFT" "Softwares Essenciais & Runtimes"),
        (New-BiosItem "DEV"  "Desenvolvimento (IDEs, Git, JDKs)"),
        (New-BiosItem "MANT" "Manutenção & Perfis Automatizados"),
        (New-BiosItem "EXIT" "Sair")
    )

    $res = Read-BiosMenu -Title "SETUP UTILITY" -Items $items -Multi $false
    switch ($res) {
        "SOFT" { $script:menuAtual = "SOFT" }
        "DEV"  { $script:menuAtual = "DEV" }
        "MANT" { $script:menuAtual = "MANUTENCAO" }
        "EXIT" { $script:menuAtual = "EXIT" }
        "Q"    { $script:menuAtual = "EXIT" }
        "ESC"  { $script:menuAtual = "MAIN" }
    }
}

function Invoke-MenuSoftwares {
    $items = @(
        (New-BiosItem "0"  "ATUALIZAÇÃO GERAL — atualizar todos os pacotes winget" -Special $true),
        (New-BiosItem "1A" "7-Zip" -Instalado (Test-IsInstalled "7zip")),
        (New-BiosItem "1B" "WinRAR" -Instalado (Test-IsInstalled "winrar")),
        (New-BiosItem "2A" "Adobe Acrobat Reader" -Instalado (Test-IsInstalled "adobe")),
        (New-BiosItem "2B" "Foxit PDF Reader" -Instalado (Test-IsInstalled "foxit")),
        (New-BiosItem "2C" "LibreOffice LTS" -Instalado (Test-IsInstalled "libreoffice")),
        (New-BiosItem "3A" "GIMP" -Instalado (Test-IsInstalled "gimp")),
        (New-BiosItem "3B" "Lightshot" -Instalado (Test-IsInstalled "lightshot")),
        (New-BiosItem "3C" "ShareX" -Instalado (Test-IsInstalled "sharex")),
        (New-BiosItem "4A" "HandBrake" -Instalado (Test-IsInstalled "handbrake")),
        (New-BiosItem "4B" "K-Lite Codec Pack Full" -Instalado (Test-IsInstalled "klite")),
        (New-BiosItem "4C" "VLC Media Player" -Instalado (Test-IsInstalled "vlc")),
        (New-BiosItem "5A" ".NET 8 Desktop Runtime" -Instalado (Test-IsInstalled "dotnet8")),
        (New-BiosItem "5B" ".NET 9 Desktop Runtime" -Instalado (Test-IsInstalled "dotnet9")),
        (New-BiosItem "5C" "Visual C++ 15-22 x64" -Instalado (Test-IsInstalled "vcredist_x64")),
        (New-BiosItem "5D" "Visual C++ 15-22 x86" -Instalado (Test-IsInstalled "vcredist_x86")),
        (New-BiosItem "5E" "Visual C++ All-in-One (abbodi1406)" -Instalado (Test-IsInstalled "vcredist_all")),
        (New-BiosItem "5F" "Java Temurin 17 JRE" -Instalado (Test-IsInstalled "temurin17jre")),
        (New-BiosItem "6A" "AnyDesk" -Instalado (Test-IsInstalled "anydesk")),
        (New-BiosItem "6B" "qBittorrent" -Instalado (Test-IsInstalled "qbittorrent")),
        (New-BiosItem "6C" "Rufus (Boot)" -Instalado (Test-IsInstalled "rufus")),
        (New-BiosItem "6D" "RustDesk" -Instalado (Test-IsInstalled "rustdesk")),
        (New-BiosItem "6E" "Transmission" -Instalado (Test-IsInstalled "transmission")),
        (New-BiosItem "6F" "RealVNC Viewer" -Instalado (Test-IsInstalled "realvnc"))
    )

    $res = Read-BiosMenu -Title "SOFTWARES ESSENCIAIS & RUNTIMES" -Items $items -Multi $true -Shortcuts @("D", "M")
    switch ($res) {
        "Q"   { $script:menuAtual = "EXIT" }
        "ESC" { $script:menuAtual = "MAIN" }
        "D"   { $script:menuAtual = "DEV" }
        "M"   { $script:menuAtual = "MANUTENCAO" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res } else { $script:menuAtual = "SOFT" }
        }
    }
}

function Invoke-MenuDev {
    $items = @(
        (New-BiosItem "D0" "PACOTE DEV COMPLETO — VS Code + Git + Notepad++ + JDK 17" -Special $true),
        (New-BiosItem "D1" "Visual Studio Code" -Instalado (Test-IsInstalled "vscode")),
        (New-BiosItem "D2" "Notepad++" -Instalado (Test-IsInstalled "notepadplusplus")),
        (New-BiosItem "D3" "Visual Studio 2022 Community" -Instalado (Test-IsInstalled "vs2022")),
        (New-BiosItem "D4" "Android Studio" -Instalado (Test-IsInstalled "androidstudio")),
        (New-BiosItem "D5" "Git SCM" -Instalado (Test-IsInstalled "git")),
        (New-BiosItem "D6" "XAMPP (PHP 8.2 & MySQL)" -Instalado (Test-IsInstalled "xampp")),
        (New-BiosItem "D7" "Java Temurin 8 JDK" -Instalado (Test-IsInstalled "temurin8jdk")),
        (New-BiosItem "D8" "Java Temurin 11 JDK" -Instalado (Test-IsInstalled "temurin11jdk")),
        (New-BiosItem "D9" "Java Temurin 17 JDK (LTS)" -Instalado (Test-IsInstalled "temurin17jdk")),
        (New-BiosItem "D10" "Java Temurin 21 JDK (LTS)" -Instalado (Test-IsInstalled "temurin21jdk"))
    )

    $res = Read-BiosMenu -Title "DESENVOLVIMENTO (DEV)" -Items $items -Multi $true -Shortcuts @("S", "M")
    switch ($res) {
        "Q"   { $script:menuAtual = "EXIT" }
        "ESC" { $script:menuAtual = "MAIN" }
        "S"   { $script:menuAtual = "SOFT" }
        "M"   { $script:menuAtual = "MANUTENCAO" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res } else { $script:menuAtual = "DEV" }
        }
    }
}

function Invoke-MenuManutencao {
    $items = @(
        (New-BiosItem "M1" "Reparo Completo (DISM + SFC)" -Instalado (Test-IsInstalled "system_repair")),
        (New-BiosItem "M2" "Diagnóstico Volume C: (Scan)" -Instalado (Test-IsInstalled "disk_check")),
        (New-BiosItem "M3" "Reset Pilha de Rede (DHCP)" -Instalado (Test-IsInstalled "net_reset")),
        (New-BiosItem "M4" "Forçar Atualização GPO" -Instalado (Test-IsInstalled "gpo_update")),
        (New-BiosItem "M5" "Habilitar Admin (SID 500)" -Instalado (Test-IsInstalled "admin500")),
        (New-BiosItem "M6" "Mapear Credencial de Rede" -Instalado (Test-IsInstalled "net_cred")),
        (New-BiosItem "M7" "Renomear Computador" -Instalado (Test-IsInstalled "rename_pc")),
        (New-BiosItem "M8" "Habilitar Servidor OpenSSH (22)" -Instalado (Test-IsInstalled "sshd")),
        (New-BiosItem "M9" "Tweaks Win 11 (Menu Clássico, Dark, Barra Esquerda, Sem Widgets/Copilot)" -Instalado (Test-IsInstalled "win11_tweaks")),
        (New-BiosItem "P1" "MODO PMA — Prefeitura Win 11 (Apps + Runtimes + Admin + Tweaks)" -Special $true),
        (New-BiosItem "P2" "MODO BRNCZZR — Dev Workstation (Apps Dev + Runtimes + Tweaks)" -Special $true)
    )

    $res = Read-BiosMenu -Title "MANUTENÇÃO & PERFIS" -Items $items -Multi $true -Shortcuts @("S", "D")
    switch ($res) {
        "Q"   { $script:menuAtual = "EXIT" }
        "ESC" { $script:menuAtual = "MAIN" }
        "S"   { $script:menuAtual = "SOFT" }
        "D"   { $script:menuAtual = "DEV" }
        default {
            if (-not [string]::IsNullOrWhiteSpace($res)) { Dispatch-Execution $res } else { $script:menuAtual = "MANUTENCAO" }
        }
    }
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
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    Write-Host ""
    
    Execute-BatchOptions $ExecutarLote
    
    Write-Host ""
    Write-Host "╭────────────────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Green
    Write-Host "│" -NoNewline -ForegroundColor Green
    Write-Host (" [✓] Todas as tarefas solicitadas foram concluídas!".PadRight(88)) -NoNewline -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Green
    
    # Modo automático (-ExecutarLote): interativo aguarda ENTER; headless (Task Scheduler/RMM) sai direto.
    if ([Environment]::UserInteractive) {
        Wait-User
    } else {
        Write-Host "`n[+] Modo não-interativo (headless): encerrando." -ForegroundColor Gray
    }
    exit 0
}

$script:menuAtual = "MAIN"

while ($script:menuAtual -ne "EXIT") {
    switch ($script:menuAtual) {
        "MAIN"        { Invoke-MenuPrincipal }
        "SOFT"        { Invoke-MenuSoftwares }
        "DEV"         { Invoke-MenuDev }
        "MANUTENCAO"  { Invoke-MenuManutencao }
    }
}

Write-Host "`n[+] Encerrando win-toolbox-tui. Até logo!`n" -ForegroundColor Green
