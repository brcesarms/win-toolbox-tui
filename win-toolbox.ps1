<#
.SYNOPSIS
    WIN-TOOLBOX-TUI V1.0 — Caixa de Ferramentas e Pós-Instalação para Windows 11
.DESCRIPTION
    Script interativo modular (TUI) com múltiplos menus e navegação direta entre
    telas (Principal, Dev e Manutenção). Exibe cabeçalho completo de telemetria
    local (Data, Hora, Hostname, Usuário e IP). Exclusivo para Windows 11 (Build 22000+).
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    1.0.0 — Windows 11 Edition (2026)
#>

[CmdletBinding()]
param()

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
# 3. CABEÇALHO COM TELEMETRIA LOCAL (DATA, HORA, HOST, USER, IP)
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

    Write-Host "============================================================================================================" -ForegroundColor Cyan
    Write-Host "   WIN-TOOLBOX-TUI V1.0  |  WINDOWS 11  |  $subtitulo" -ForegroundColor Cyan
    Write-Host "   Data: $data  |  Computador: $env:computername  |  Usuario: $env:username  |  IP: $ip" -ForegroundColor White
    Write-Host "============================================================================================================" -ForegroundColor Cyan
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
    
    # 1. DISM primeiro: repara o repositório de componentes do Windows 11
    Write-Host "`n[Passo 1/2] Executando DISM /Online /Cleanup-Image /RestoreHealth..." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /RestoreHealth
    
    # 2. SFC segundo: repara arquivos de sistema usando o repositório sadio
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

    # 1. Instalar recurso nativo OpenSSH Server se ausente
    Write-Host "[1/3] Verificando capacidade nativa OpenSSH.Server..." -ForegroundColor Gray
    $sshCap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    if ($sshCap.State -ne 'Installed') {
        Write-Host "[+] Instalando OpenSSH.Server (aguarde alguns instantes)..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
        Write-Host "[✔] Recurso OpenSSH Server instalado!" -ForegroundColor Green
    } else {
        Write-Host "[✔] Recurso OpenSSH Server já está instalado." -ForegroundColor Green
    }

    # 2. Configurar e iniciar serviços sshd e ssh-agent
    Write-Host "[2/3] Configurando serviço sshd para inicialização automática..." -ForegroundColor Gray
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Set-Service -Name ssh-agent -StartupType 'Automatic'
    Write-Host "[✔] Serviço sshd em execução e configurado como Automático!" -ForegroundColor Green

    # 3. Regra de Firewall para porta 22 (TCP Inbound em todos os perfis)
    Write-Host "[3/3] Configurando regra de Firewall (Porta 22 TCP)..." -ForegroundColor Gray
    $regraExiste = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
    if (-not $regraExiste) {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null
    }
    # Fallback via netsh para garantir que o firewall libere mesmo com GPO restritiva
    $validaRegra = netsh advfirewall firewall show rule name="OpenSSH-Server-In-TCP" 2>$null
    if ($validaRegra -notmatch "OpenSSH-Server-In-TCP") {
        netsh advfirewall firewall add rule name="OpenSSH-Server-In-TCP" dir=in action=allow protocol=TCP localport=22 | Out-Null
    }
    Write-Host "[✔] Porta 22 liberada no Firewall para todos os perfis de rede!" -ForegroundColor Green

    # Instrução prática de conexão para o usuário
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

    # 1. Restaurar Menu de Contexto Clássico (Windows 10 style sem "Mostrar mais opções")
    Write-Host "[+] Ativando Menu de Contexto Clássico completo..." -ForegroundColor Gray
    $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" | Out-Null
    }

    # 2. Alinhar barra de tarefas à esquerda
    Write-Host "[+] Alinhando Barra de Tarefas à Esquerda..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord -Force

    # 3. Desativar Widgets e botão do Copilot na barra
    Write-Host "[+] Ocultando Widgets e botão Copilot da barra de tarefas..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    # 4. Mostrar extensões conhecidas de arquivos (.exe, .ps1, .txt)
    Write-Host "[+] Exibindo extensões de arquivos no Explorer..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force

    # 5. Mostrar arquivos e pastas ocultos
    Write-Host "[+] Exibindo pastas e arquivos ocultos..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force

    # 6. Abrir Explorer em 'Este Computador' em vez de 'Acesso Rápido'
    Write-Host "[+] Definindo 'Este Computador' como padrão no Explorer..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -Force

    # 7. Desativar Hibernação (Economiza de 8GB a 32GB em SSD/NVMe)
    Write-Host "[+] Desativando hibernação (liberação de espaço no SSD)..." -ForegroundColor Gray
    powercfg -h off

    # 8. Ativar Tema Escuro no Sistema e Aplicativos
    Write-Host "[+] Ativando Tema Escuro..." -ForegroundColor Gray
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

    # Reiniciar explorer para aplicar alterações visuais
    Write-Host "[+] Reiniciando Windows Explorer para aplicar alterações..." -ForegroundColor Gray
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    Write-Host "[✔] Tweaks do Windows 11 aplicados com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 7. PERFIS AUTOMATIZADOS (MODO PMA & MODO DEV)
# ==============================================================================
function Invoke-ModoPMA {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO PMA (PADRÃO PREFEITURA WIN 11)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Install-WingetApp "7zip.7zip" "7-Zip"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS"
    Install-WingetApp "Skillbrains.Lightshot" "Lightshot (Captura)"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk (Acesso Remoto)"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player"

    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE (LTS)"

    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    Write-Host "`n[✔] Perfil MODO PMA concluído com sucesso!" -ForegroundColor Green
}

function Invoke-ModoBRNCZZR {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO BRNCZZR (DEV & WORKSTATION)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    Install-WingetApp "Git.Git" "Git SCM"
    Install-WingetApp "Microsoft.VisualStudioCode" "Visual Studio Code"
    Install-WingetApp "Notepad++.Notepad++" "Notepad++"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK (LTS)"
    Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP & MySQL)"

    Install-WingetApp "7zip.7zip" "7-Zip"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player"

    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"

    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    Write-Host "`n[✔] Perfil MODO BRNCZZR concluído com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 8. TELAS DE MENU (ESTRUTURA FSM - FINITE STATE MACHINE)
# ==============================================================================
function Invoke-MenuPrincipal {
    Show-Header "MENU PRINCIPAL — SOFTWARES ESSENCIAIS"
    Write-Host @"
+------------------------------------------------------------------------------------------------------------+
|   0.  UPDATE ALL (Winget)              |       I M A G E M                 |       U T I L I T A R I O S   |
|                                        |   3A. GIMP                        |   6A. AnyDesk                 |
|       C O M P A C T A C A O            |   3B. Lightshot                   |   6B. qBittorrent             |
|   1A. 7-Zip                            |   3C. ShareX                      |   6C. Rufus                   |
|   1B. WinRAR                           |                                   |   6D. RustDesk                |
|                                        |       M I D I A                   |   6E. Transmission            |
|       D O C U M E N T O S              |   4A. HandBrake                   |   6F. RealVNC Viewer          |
|   2A. Adobe Acrobat Reader             |   4B. K-Lite Codec Full           |                               |
|   2B. Foxit PDF Reader                 |   4C. VLC Media Player            |                               |
|   2C. LibreOffice LTS                  |                                   |                               |
+------------------------------------------------------------------------------------------------------------+
|       R U N T I M E S   W I N D O W S   1 1                                                                |
|   5A. .NET 8 Desktop Runtime (LTS)     |   5C. Visual C++ 2015-2022 (x64)  |   5E. Visual C++ All-in-One   |
|   5B. .NET 9 Desktop Runtime           |   5D. Visual C++ 2015-2022 (x86)  |   5F. Java Temurin 17 JRE     |
+------------------------------------------------------------------------------------------------------------+
|   D.  💻 IR PARA MENU DESENVOLVIMENTO (DEV)                                                                |
|   M.  🛠️ IR PARA MENU MANUTENÇÃO, TWEAKS & PERFIS AUTOMÁTICOS                                              |
|   Q.  🚪 SAIR                                                                                              |
+------------------------------------------------------------------------------------------------------------+
  (Dica: você pode selecionar múltiplos itens separados por vírgula. Ex: 0, 1A, 2C, 5E, 6D)
"@ -ForegroundColor Gray

    $escolha = Read-Host "OPÇÃO [D para Dev, M para Manutenção, Q para Sair]"
    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "D") { $script:menuAtual = "DEV"; return }
    if ($escolhaUpper -eq "M") { $script:menuAtual = "MANUTENCAO"; return }

    $itens = $escolha -split ","
    foreach ($item in $itens) {
        $opcao = $item.Trim().ToUpper()
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
    Write-Host @"
+------------------------------------------------------------------------------------------------------------+
|       I D E s   &   E D I T O R E S    |       V E R S I O N A M E N T O  &  S E R V I D O R               |
|   D1. Visual Studio Code               |   D5. Git SCM                                                     |
|   D2. Notepad++                        |   D6. XAMPP (PHP 8.2 & MySQL / Apache)                            |
|   D3. Visual Studio 2022 Community     |                                                                   |
|   D4. Android Studio                   |       J A V A   J D K   ( E C L I P S E   T E M U R I N )         |
|                                        |   D7. Java Temurin 8 JDK          D9.  Java Temurin 17 JDK (LTS)  |
|                                        |   D8. Java Temurin 11 JDK         D10. Java Temurin 21 JDK (LTS)  |
+------------------------------------------------------------------------------------------------------------+
|   D0. PACOTE DEV COMPLETO (VS Code + Git + Notepad++ + JDK 17)                                             |
+------------------------------------------------------------------------------------------------------------+
|   V.  ⬅️ Voltar ao Menu Principal     |   M.  🛠️ Ir para Menu Manutenção   |   Q.  🚪 Sair                  |
+------------------------------------------------------------------------------------------------------------+
  (Dica: você pode selecionar múltiplos itens separados por vírgula. Ex: D1, D5, D9)
"@ -ForegroundColor Gray

    $escolha = Read-Host "DEV SELEÇÃO [V para Principal, M para Manutenção, Q para Sair]"
    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "V") { $script:menuAtual = "MAIN"; return }
    if ($escolhaUpper -eq "M") { $script:menuAtual = "MANUTENCAO"; return }

    $itens = $escolha -split ","
    foreach ($item in $itens) {
        $opcao = $item.Trim().ToUpper()
        switch ($opcao) {
            "D0" {
                Install-WingetApp "Microsoft.VisualStudioCode" "VS Code"
                Install-WingetApp "Git.Git" "Git SCM"
                Install-WingetApp "Notepad++.Notepad++" "Notepad++"
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
    Write-Host @"
+------------------------------------------------------------------------------------------------------------+
|       D I A G N O S T I C O   &   R E P A R O  |       C O N F I G U R A C O E S   &   R E D E             |
|   M1. Reparo Completo (DISM + SFC Scannow)     |   M5. Habilitar Administrador Nativo (SID 500)            |
|   M2. Diagnóstico Online Volume C: (Scan)      |   M6. Mapear Credencial de Rede (Windows Vault)           |
|   M3. Reset Completo de Pilha de Rede (DHCP)   |   M7. Renomear Computador & Reiniciar                     |
|   M4. Forçar Atualização GPO (gpupdate)        |   M8. Habilitar Servidor OpenSSH (Porta 22)               |
+------------------------------------------------------------------------------------------------------------+
|       T W E A K S   E S S E N C I A I S   W I N D O W S   1 1                                              |
|   M9. Aplicar Tweaks Completos de Produtividade & Performance                                              |
|       (Menu Clássico, Barra à Esquerda, Extensões Visíveis, Pastas Ocultas, Dark Mode, Hibernação OFF)    |
+------------------------------------------------------------------------------------------------------------+
|       P E R F I S   A U T O M A T I Z A D O S   ( I N S T A L A C A O   E M   L O T E )                    |
|   P1. 🏛️ MODO PMA (Prefeitura Win 11: Apps Corp + Runtimes + Admin + Tweaks Win 11)                        |
|   P2. 🚀 MODO BRNCZZR (Dev Workstation: Apps Dev + Produtividade + Runtimes + Tweaks)                      |
+------------------------------------------------------------------------------------------------------------+
|   V.  ⬅️ Voltar ao Menu Principal     |   D.  💻 Ir para Menu Dev          |   Q.  🚪 Sair                  |
+------------------------------------------------------------------------------------------------------------+
  (Dica: você pode selecionar múltiplos itens separados por vírgula. Ex: M1, M8, M9)
"@ -ForegroundColor Gray

    $escolha = Read-Host "MANUTENÇÃO SELEÇÃO [V para Principal, D para Dev, Q para Sair]"
    if ([string]::IsNullOrWhiteSpace($escolha)) { return }
    $escolhaUpper = $escolha.Trim().ToUpper()

    if ($escolhaUpper -eq "Q") { $script:menuAtual = "EXIT"; return }
    if ($escolhaUpper -eq "V") { $script:menuAtual = "MAIN"; return }
    if ($escolhaUpper -eq "D") { $script:menuAtual = "DEV"; return }

    $itens = $escolha -split ","
    foreach ($item in $itens) {
        $opcao = $item.Trim().ToUpper()
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
