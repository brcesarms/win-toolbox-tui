<#
.SYNOPSIS
    WIN-TOOLBOX-TUI V1.0 — Caixa de Ferramentas e Pós-Instalação para Windows 11
.DESCRIPTION
    Script interativo com interface TUI moderna (Unicode Box Drawing), múltiplos menus,
    barra de progresso dinâmica em lote, telemetria de sistema e suporte completo a Winget.
    Exclusivo para Windows 11 (Build 22000+).
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    1.1.0 — Progress Bar & Modern TUI Edition (Windows 11)
#>

[CmdletBinding()]
param()

# Configuração de codificação UTF-8 para suporte a caracteres Unicode
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================================
# 1. VERIFICAÇÃO DE ELEVAÇÃO (ADMINISTRADOR)
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host "`n[!] Privilégios de Administrador são necessários." -ForegroundColor Yellow
    Write-Host "[*] Reiniciando com elevação de privilégios...`n" -ForegroundColor Cyan
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
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

    $subLine = ("│ TELA: $subtitulo").PadRight(89) + "│"
    $infoLine = ("│ Data: $data  |  Computador: $env:computername  |  Usuario: $env:username  |  IP: $ip").PadRight(89) + "│"

    Write-Host "╭─ WIN-TOOLBOX-TUI V1.0 ──────────────────────────────────────────────── [ WINDOWS 11 ] ─╮" -ForegroundColor Cyan
    Write-Host $subLine -ForegroundColor White
    Write-Host $infoLine -ForegroundColor Gray
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
}

function Show-ProgressBar {
    param(
        [Parameter(Mandatory=$true)] [int]$Current,
        [Parameter(Mandatory=$true)] [int]$Total,
        [Parameter(Mandatory=$false)] [string]$Activity = "Processando..."
    )
    if ($Total -le 0) { return }
    $percent = [math]::Round(($Current / $Total) * 100)
    if ($percent -gt 100) { $percent = 100 }
    
    $barWidth = 30
    $filled = [math]::Round(($percent / 100) * $barWidth)
    if ($filled -gt $barWidth) { $filled = $barWidth }
    $empty = $barWidth - $filled
    
    $bar = ("█" * $filled) + ("░" * $empty)
    
    $badgeLeft = "╭─ PROGRESSO [ $Current / $Total ] "
    $badgeRight = " [ $percent% ] ─╮"
    $dashesCount = 90 - ($badgeLeft.Length + $badgeRight.Length)
    if ($dashesCount -lt 2) { $dashesCount = 2 }
    $dashes = "─" * $dashesCount
    
    $topLine = "$badgeLeft$dashes$badgeRight"
    $content = "│ [$bar] $Activity"
    $padded = $content.PadRight(89) + "│"
    $botLine = "╰────────────────────────────────────────────────────────────────────────────────────────╯"
    
    Write-Host ""
    Write-Host $topLine -ForegroundColor Cyan
    Write-Host $padded -ForegroundColor Yellow
    Write-Host $botLine -ForegroundColor Cyan
    Write-Host ""
}

function Wait-User {
    Write-Host "`n[Pressione ENTER para continuar...]" -ForegroundColor DarkGray
    $null = Read-Host
}

# ==============================================================================
# 4. FUNÇÕES AUXILIARES & WINGET
# ==============================================================================
function Install-WingetApp {
    param(
        [Parameter(Mandatory=$true)] [string]$idApp,
        [Parameter(Mandatory=$false)] [string]$nomeAmigavel = ""
    )
    if ([string]::IsNullOrWhiteSpace($nomeAmigavel)) { $nomeAmigavel = $idApp }
    
    Write-Host "[*] Verificando: $nomeAmigavel ($idApp)..." -NoNewline -ForegroundColor Gray
    
    $check = winget list --id $idApp --exact 2>$null | Select-String $idApp
    if ($check) {
        Write-Host " [JA INSTALADO]" -ForegroundColor Yellow
        return
    }

    Write-Host " [INSTALANDO]" -ForegroundColor Green
    winget install --id $idApp --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[✔] $nomeAmigavel instalado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[!] Falha ou aviso ao instalar $nomeAmigavel (Exit Code: $LASTEXITCODE)." -ForegroundColor Yellow
    }
}

function Update-AllWinget {
    Write-Host "`n[*] Atualizando todos os pacotes instalados via Winget..." -ForegroundColor Cyan
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    Write-Host "[✔] Atualizações concluídas." -ForegroundColor Green
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
            Write-Host "[✔] Conta de Administrador ($($admin.Name)) ativada com sucesso!" -ForegroundColor Green
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
    
    Write-Host "`n[✔] Reparo de integridade do sistema concluído!" -ForegroundColor Green
}

function Invoke-DiskCheck {
    Write-Host "`n[*] Executando diagnóstico online do volume C: (Repair-Volume Scan)..." -ForegroundColor Cyan
    try {
        Repair-Volume -DriveLetter C -Scan
        Write-Host "[✔] Verificação de integridade do disco C: concluída sem necessidade de reiniciar." -ForegroundColor Green
    } catch {
        Write-Host "[!] Executando chkdsk C: /scan..." -ForegroundColor Yellow
        chkdsk C: /scan
    }
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
    Write-Host "[✔] Rede atualizada com sucesso!" -ForegroundColor Green
}

function Invoke-UpdateGPO {
    Write-Host "`n[*] Forçando atualização de diretivas de grupo (gpupdate /force)..." -ForegroundColor Cyan
    gpupdate /force
    Write-Host "[✔] GPO atualizada!" -ForegroundColor Green
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
        Write-Host "[✔] Credencial para $ip salva com segurança no Windows!" -ForegroundColor Green
    } else {
        Write-Host "[!] Senha não informada. Credencial não foi criada." -ForegroundColor Yellow
    }
}

function Set-MachineName {
    Write-Host "`n[*] Renomear Computador" -ForegroundColor Cyan
    $novoNome = Read-Host "Digite o novo nome para esta estação de trabalho"
    if (-not [string]::IsNullOrWhiteSpace($novoNome)) {
        Rename-Computer -NewName $novoNome -Force
        Write-Host "[✔] Computador renomeado para: $novoNome" -ForegroundColor Green
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
        Write-Host "[✔] Recurso OpenSSH Server instalado!" -ForegroundColor Green
    } else {
        Write-Host "[✔] Recurso OpenSSH Server já está instalado." -ForegroundColor Green
    }

    Write-Host "[2/3] Configurando serviço sshd para inicialização automática..." -ForegroundColor Gray
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Set-Service -Name ssh-agent -StartupType 'Automatic'
    Write-Host "[✔] Serviço sshd em execução e configurado como Automático!" -ForegroundColor Green

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
    Write-Host "[✔] Porta 22 liberada no Firewall para todos os perfis de rede!" -ForegroundColor Green

    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
        $_.IPAddress -ne "127.0.0.1" -and 
        $_.IPAddress -notlike "169.254*" -and 
        $_.InterfaceAlias -notlike "*Loopback*"
    } | Select-Object -ExpandProperty IPAddress -First 1)

    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host " [✔] SERVIDOR SSH CONFIGURADO E PRONTO PARA CONEXÃO!" -ForegroundColor Green
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

    Write-Host "[✔] Tweaks do Windows 11 aplicados com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 7. PERFIS AUTOMATIZADOS COM PROGRESSO PASSO A PASSO
# ==============================================================================
function Invoke-ModoPMA {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO PMA (PADRÃO PREFEITURA WIN 11)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    $totalPassos = 14
    
    Show-ProgressBar -Current 1 -Total $totalPassos -Activity "Instalando 7-Zip"
    Install-WingetApp "7zip.7zip" "7-Zip"
    
    Show-ProgressBar -Current 2 -Total $totalPassos -Activity "Instalando Mozilla Firefox"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    
    Show-ProgressBar -Current 3 -Total $totalPassos -Activity "Instalando Google Chrome"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    
    Show-ProgressBar -Current 4 -Total $totalPassos -Activity "Instalando Foxit Reader"
    Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader"
    
    Show-ProgressBar -Current 5 -Total $totalPassos -Activity "Instalando LibreOffice LTS"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS"
    
    Show-ProgressBar -Current 6 -Total $totalPassos -Activity "Instalando Lightshot"
    Install-WingetApp "Skillbrains.Lightshot" "Lightshot (Captura)"
    
    Show-ProgressBar -Current 7 -Total $totalPassos -Activity "Instalando RustDesk"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk (Acesso Remoto)"
    
    Show-ProgressBar -Current 8 -Total $totalPassos -Activity "Instalando VLC Media Player"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player"

    Show-ProgressBar -Current 9 -Total $totalPassos -Activity "Instalando .NET 8 Desktop Runtime"
    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
    
    Show-ProgressBar -Current 10 -Total $totalPassos -Activity "Instalando Visual C++ x64"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
    
    Show-ProgressBar -Current 11 -Total $totalPassos -Activity "Instalando Visual C++ x86"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"
    
    Show-ProgressBar -Current 12 -Total $totalPassos -Activity "Instalando Java Temurin 17 JRE"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE (LTS)"

    Show-ProgressBar -Current 13 -Total $totalPassos -Activity "Habilitando Administrador Local"
    Enable-BuiltinAdmin
    
    Show-ProgressBar -Current 14 -Total $totalPassos -Activity "Aplicando Tweaks do Windows 11"
    Apply-Win11Tweaks

    Write-Host "`n[✔] Perfil MODO PMA concluído com sucesso!" -ForegroundColor Green
}

function Invoke-ModoBRNCZZR {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO BRNCZZR (DEV & WORKSTATION)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    $totalPassos = 12

    Show-ProgressBar -Current 1 -Total $totalPassos -Activity "Instalando Git SCM"
    Install-WingetApp "Git.Git" "Git SCM"
    
    Show-ProgressBar -Current 2 -Total $totalPassos -Activity "Instalando Visual Studio Code"
    Install-WingetApp "Microsoft.VisualStudioCode" "Visual Studio Code"
    
    Show-ProgressBar -Current 3 -Total $totalPassos -Activity "Instalando Notepad++"
    Install-WingetApp "Notepad++.Notepad++" "Notepad++"
    
    Show-ProgressBar -Current 4 -Total $totalPassos -Activity "Instalando Java Temurin 17 JDK"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK (LTS)"
    
    Show-ProgressBar -Current 5 -Total $totalPassos -Activity "Instalando XAMPP"
    Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP & MySQL)"

    Show-ProgressBar -Current 6 -Total $totalPassos -Activity "Instalando 7-Zip"
    Install-WingetApp "7zip.7zip" "7-Zip"
    
    Show-ProgressBar -Current 7 -Total $totalPassos -Activity "Instalando Google Chrome"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    
    Show-ProgressBar -Current 8 -Total $totalPassos -Activity "Instalando Mozilla Firefox"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    
    Show-ProgressBar -Current 9 -Total $totalPassos -Activity "Instalando LibreOffice LTS"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS"
    
    Show-ProgressBar -Current 10 -Total $totalPassos -Activity "Instalando RustDesk & VLC"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player"

    Show-ProgressBar -Current 11 -Total $totalPassos -Activity "Instalando Runtimes .NET 8 & VC++"
    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"

    Show-ProgressBar -Current 12 -Total $totalPassos -Activity "Configurando Admin & Tweaks Win 11"
    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    Write-Host "`n[✔] Perfil MODO BRNCZZR concluído com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 8. TELAS DE MENU COM POLIMENTO TUI MODERNO
# ==============================================================================
function Invoke-MenuPrincipal {
    Show-Header "MENU PRINCIPAL — SOFTWARES ESSENCIAIS & RUNTIMES"

    Write-Host "╭────────────────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host "│ [0] ATUALIZAÇÃO GERAL: Atualizar todos os pacotes instalados via Winget                │" -ForegroundColor Yellow
    Write-Host "├─────────────────────────┬─────────────────────────────┬────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ COMPACTAÇÃO             │ DOCUMENTOS                  │ IMAGEM & VÍDEO                 │" -ForegroundColor Cyan
    Write-Host "│ [1A] 7-Zip              │ [2A] Adobe Acrobat Reader   │ [3A] GIMP                      │" -ForegroundColor White
    Write-Host "│ [1B] WinRAR             │ [2B] Foxit PDF Reader       │ [3B] Lightshot                 │" -ForegroundColor White
    Write-Host "│                         │ [2C] LibreOffice LTS        │ [3C] ShareX                    │" -ForegroundColor White
    Write-Host "│                         │                             │ [4A] HandBrake                 │" -ForegroundColor White
    Write-Host "│                         │                             │ [4B] K-Lite Codec Full         │" -ForegroundColor White
    Write-Host "│                         │                             │ [4C] VLC Media Player          │" -ForegroundColor White
    Write-Host "├─────────────────────────┼─────────────────────────────┴────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ RUNTIMES WINDOWS 11     │ ACESSO REMOTO & UTILITÁRIOS                                  │" -ForegroundColor Cyan
    Write-Host "│ [5A] .NET 8 Desktop LTS │ [6A] RustDesk               [6D] qBittorrent                 │" -ForegroundColor White
    Write-Host "│ [5B] .NET 9 Desktop     │ [6B] AnyDesk                [6E] Transmission                │" -ForegroundColor White
    Write-Host "│ [5C] VC++ 2015-2022 x64 │ [6C] Rufus (Pendrive Boot)  [6F] RealVNC Viewer              │" -ForegroundColor White
    Write-Host "│ [5D] VC++ 2015-2022 x86 │                                                              │" -ForegroundColor White
    Write-Host "│ [5E] VC++ All-in-One    │                                                              │" -ForegroundColor White
    Write-Host "│ [5F] Java Temurin 17 JRE│                                                              │" -ForegroundColor White
    Write-Host "├─────────────────────────┴──────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ NAVEGAÇÃO:   [D] Menu Dev    │    [M] Menu Manutenção & Perfis    │    [Q] Sair        │" -ForegroundColor Yellow
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    
    Write-Host "╭─ STATUS DO SISTEMA ─────────────────────────────────────────────────────── [ PRONTO ] ─╮" -ForegroundColor DarkCyan
    Write-Host "│  Selecione os itens para iniciar. Execuções em lote exibirão a barra de progresso.     │" -ForegroundColor Gray
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkCyan
    
    Write-Host "╭─ Digite as opções desejadas separadas por vírgula (ex: 0, 1A, 2C, 5E, 6D)" -ForegroundColor Cyan
    $escolha = Read-Host "╰─❯ "
    
    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "D") { $script:menuAtual = "DEV"; return }
    if ($escolhaUpper -eq "M") { $script:menuAtual = "MANUTENCAO"; return }

    $itens = @($escolha -split "," | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $totalItens = $itens.Count
    $itemAtual = 0

    foreach ($item in $itens) {
        $itemAtual++
        $opcao = $item.Trim().ToUpper()
        
        Show-ProgressBar -Current $itemAtual -Total $totalItens -Activity "Processando opção: [$opcao]"
        
        switch ($opcao) {
            "0"  { Update-AllWinget }
            "1A" { Install-WingetApp "7zip.7zip" "7-Zip" }
            "1B" { Install-WingetApp "RARLab.WinRAR" "WinRAR" }
            "2A" { Install-WingetApp "Adobe.Acrobat.Reader.64-bit" "Adobe Acrobat Reader" }
            "2B" { Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader" }
            "2C" { Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" }
            "3A" { Install-WingetApp "GIMP.GIMP" "GIMP" }
            "3B" { Install-WingetApp "Skillbrains.Lightshot" "Lightshot" }
            "3C" { Install-WingetApp "ShareX.ShareX" "ShareX" }
            "4A" { Install-WingetApp "HandBrake.HandBrake" "HandBrake" }
            "4B" { Install-WingetApp "CodecGuide.K-LiteCodecPack.Full" "K-Lite Codec Pack Full" }
            "4C" { Install-WingetApp "VideoLAN.VLC" "VLC Media Player" }
            "5A" { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" }
            "5B" { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.9" ".NET 9 Desktop Runtime" }
            "5C" { Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 x64" }
            "5D" { Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 x86" }
            "5E" { Install-WingetApp "abbodi1406.vcredist" "Visual C++ All-in-One Runtime" }
            "5F" { Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE" }
            "6A" { Install-WingetApp "AnyDeskSoftwareGmbH.AnyDesk" "AnyDesk" }
            "6B" { Install-WingetApp "qBittorrent.qBittorrent" "qBittorrent" }
            "6C" { Install-WingetApp "Rufus.Rufus" "Rufus" }
            "6D" { Install-WingetApp "RustDesk.RustDesk" "RustDesk" }
            "6E" { Install-WingetApp "Transmission.Transmission" "Transmission" }
            "6F" { Install-WingetApp "RealVNC.VNCViewer" "RealVNC Viewer" }
            default {
                Write-Host "[!] Opção '$opcao' não reconhecida no Menu Principal." -ForegroundColor Red
            }
        }
    }
    Wait-User
}

function Invoke-MenuDev {
    Show-Header "MENU DESENVOLVIMENTO (DEV)"

    Write-Host "╭────────────────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host "│ [D0] PACOTE DEV COMPLETO: Instalar VS Code + Git + Notepad++ + JDK 17                  │" -ForegroundColor Yellow
    Write-Host "├────────────────────────────────────────┬───────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ IDEs & EDITORES                        │ VERSIONAMENTO & SERVIDORES                    │" -ForegroundColor Cyan
    Write-Host "│ [D1] Visual Studio Code                │ [D5] Git SCM                                  │" -ForegroundColor White
    Write-Host "│ [D2] Notepad++                         │ [D6] XAMPP (PHP 8.2 & MySQL / Apache)         │" -ForegroundColor White
    Write-Host "│ [D3] Visual Studio 2022 Community      │                                               │" -ForegroundColor White
    Write-Host "│ [D4] Android Studio                    │ JAVA DEVELOPMENT KIT (JDK)                    │" -ForegroundColor Cyan
    Write-Host "│                                        │ [D7] Java Temurin 8 JDK                       │" -ForegroundColor White
    Write-Host "│                                        │ [D8] Java Temurin 11 JDK                      │" -ForegroundColor White
    Write-Host "│                                        │ [D9] Java Temurin 17 JDK (LTS)                │" -ForegroundColor White
    Write-Host "│                                        │ [D10] Java Temurin 21 JDK (LTS)               │" -ForegroundColor White
    Write-Host "├────────────────────────────────────────┴───────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ NAVEGAÇÃO:   [V] Menu Principal    │    [M] Menu Manutenção & Perfis    │    [Q] Sair  │" -ForegroundColor Yellow
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    
    Write-Host "╭─ STATUS DO SISTEMA ─────────────────────────────────────────────────────── [ PRONTO ] ─╮" -ForegroundColor DarkCyan
    Write-Host "│  Selecione os itens para iniciar. Execuções em lote exibirão a barra de progresso.     │" -ForegroundColor Gray
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkCyan

    Write-Host "╭─ Selecione ferramentas de DEV (ex: D0 ou D1, D5, D9)" -ForegroundColor Cyan
    $escolha = Read-Host "╰─❯ "

    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "V") { $script:menuAtual = "MAIN"; return }
    if ($escolhaUpper -eq "M") { $script:menuAtual = "MANUTENCAO"; return }

    $itens = @($escolha -split "," | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $totalItens = $itens.Count
    $itemAtual = 0

    foreach ($item in $itens) {
        $itemAtual++
        $opcao = $item.Trim().ToUpper()
        
        Show-ProgressBar -Current $itemAtual -Total $totalItens -Activity "Processando opção: [$opcao]"
        
        switch ($opcao) {
            "D0" {
                Show-ProgressBar -Current 1 -Total 4 -Activity "Instalando VS Code"
                Install-WingetApp "Microsoft.VisualStudioCode" "VS Code"
                
                Show-ProgressBar -Current 2 -Total 4 -Activity "Instalando Git SCM"
                Install-WingetApp "Git.Git" "Git SCM"
                
                Show-ProgressBar -Current 3 -Total 4 -Activity "Instalando Notepad++"
                Install-WingetApp "Notepad++.Notepad++" "Notepad++"
                
                Show-ProgressBar -Current 4 -Total 4 -Activity "Instalando Java Temurin 17 JDK"
                Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK"
            }
            "D1"  { Install-WingetApp "Microsoft.VisualStudioCode" "VS Code" }
            "D2"  { Install-WingetApp "Notepad++.Notepad++" "Notepad++" }
            "D3"  { Install-WingetApp "Microsoft.VisualStudio.2022.Community" "Visual Studio 2022 Community" }
            "D4"  { Install-WingetApp "Google.AndroidStudio" "Android Studio" }
            "D5"  { Install-WingetApp "Git.Git" "Git SCM" }
            "D6"  { Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP 8.2 & MySQL)" }
            "D7"  { Install-WingetApp "EclipseAdoptium.Temurin.8.JDK" "Java Temurin 8 JDK" }
            "D8"  { Install-WingetApp "EclipseAdoptium.Temurin.11.JDK" "Java Temurin 11 JDK" }
            "D9"  { Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK" }
            "D10" { Install-WingetApp "EclipseAdoptium.Temurin.21.JDK" "Java Temurin 21 JDK" }
            default {
                Write-Host "[!] Opção '$opcao' inválida no menu Dev." -ForegroundColor Red
            }
        }
    }
    Wait-User
}

function Invoke-MenuManutencao {
    Show-Header "MENU MANUTENÇÃO, TWEAKS & PERFIS AUTO"

    Write-Host "╭────────────────────────────────────────┬───────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host "│ DIAGNÓSTICO & REPARO                   │ CONFIGURAÇÕES, REDE & ACESSO                  │" -ForegroundColor Cyan
    Write-Host "│ [M1] Reparo Completo (DISM + SFC)      │ [M5] Habilitar Administrador (SID 500)        │" -ForegroundColor White
    Write-Host "│ [M2] Diagnóstico Volume C: (Scan)      │ [M6] Mapear Credencial de Rede (Vault)        │" -ForegroundColor White
    Write-Host "│ [M3] Reset Pilha de Rede (DHCP/DNS)    │ [M7] Renomear Computador & Reiniciar          │" -ForegroundColor White
    Write-Host "│ [M4] Forçar Atualização GPO (gpupdate) │ [M8] Habilitar Servidor OpenSSH (Porta 22)    │" -ForegroundColor White
    Write-Host "├────────────────────────────────────────┴───────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ TWEAKS DE SISTEMA E PERFORMANCE DO WINDOWS 11                                          │" -ForegroundColor Cyan
    Write-Host "│ [M9] Aplicar Tweaks Completos (Menu Clássico, Barra à Esquerda, Extensões Visíveis,    │" -ForegroundColor White
    Write-Host "│      Pastas Ocultas, Tema Escuro, Hibernação Desativada, Ocultar Widgets & Copilot)    │" -ForegroundColor White
    Write-Host "├────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ PERFIS AUTOMATIZADOS (INSTALAÇÃO EM LOTE)                                              │" -ForegroundColor Cyan
    Write-Host "│ [P1] MODO PMA: Padrão Prefeitura Win 11 (Apps Corporativos + Runtimes + Admin + Tweaks)│" -ForegroundColor White
    Write-Host "│ [P2] MODO BRNCZZR: Dev Workstation (Apps Dev + Produtividade + Runtimes + Tweaks)      │" -ForegroundColor White
    Write-Host "├────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ NAVEGAÇÃO:   [V] Menu Principal    │    [D] Menu Desenvolvimento (DEV)   │    [Q] Sair │" -ForegroundColor Yellow
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    
    Write-Host "╭─ STATUS DO SISTEMA ─────────────────────────────────────────────────────── [ PRONTO ] ─╮" -ForegroundColor DarkCyan
    Write-Host "│  Selecione os itens para iniciar. Execuções em lote exibirão a barra de progresso.     │" -ForegroundColor Gray
    Write-Host "╰────────────────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkCyan

    Write-Host "╭─ Selecione tarefas de manutenção ou perfis (ex: M1, M8 ou P1)" -ForegroundColor Cyan
    $escolha = Read-Host "╰─❯ "

    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "V") { $script:menuAtual = "MAIN"; return }
    if ($escolhaUpper -eq "D") { $script:menuAtual = "DEV"; return }

    $itens = @($escolha -split "," | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $totalItens = $itens.Count
    $itemAtual = 0

    foreach ($item in $itens) {
        $itemAtual++
        $opcao = $item.Trim().ToUpper()
        
        Show-ProgressBar -Current $itemAtual -Total $totalItens -Activity "Processando opção: [$opcao]"
        
        switch ($opcao) {
            "M1" { Invoke-SystemRepair }
            "M2" { Invoke-DiskCheck }
            "M3" { Invoke-NetworkReset }
            "M4" { Invoke-UpdateGPO }
            "M5" { Enable-BuiltinAdmin }
            "M6" { Add-NetworkCredential }
            "M7" { Set-MachineName }
            "M8" { Enable-OpenSSHServer }
            "M9" { Apply-Win11Tweaks }
            "P1" { Invoke-ModoPMA }
            "P2" { Invoke-ModoBRNCZZR }
            default {
                Write-Host "[!] Opção '$opcao' inválida no menu de Manutenção." -ForegroundColor Red
            }
        }
    }
    Wait-User
}

# ==============================================================================
# 9. LOOP PRINCIPAL DE CONTROLE (MÁQUINA DE ESTADOS)
# ==============================================================================
$script:menuAtual = "MAIN"

while ($script:menuAtual -ne "EXIT") {
    switch ($script:menuAtual) {
        "MAIN"        { Invoke-MenuPrincipal }
        "DEV"         { Invoke-MenuDev }
        "MANUTENCAO"  { Invoke-MenuManutencao }
    }
}

Write-Host "`n[+] Encerrando win-toolbox-tui. Até logo!`n" -ForegroundColor Green
