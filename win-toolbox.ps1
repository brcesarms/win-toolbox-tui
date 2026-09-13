<#
.SYNOPSIS
    win-toolbox-tui — Caixa de Ferramentas e Pós-Instalação para Windows 11
.DESCRIPTION
    Script interativo (TUI) para automação de manutenção, diagnóstico, instalação
    de softwares via winget, tweaks de sistema e perfis automatizados (PMA / Dev).
    Exclusivo para Windows 11 (Build 22000+).
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    6.0.0 — Windows 11 Edition (2026)
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
# 3. FUNÇÕES AUXILIARES & WINGET
# ==============================================================================
function Show-Header {
    Clear-Host
    $dataHora = (Get-Date).ToString("dd/MM/yyyy HH:mm")
    Write-Host "============================================================================================================" -ForegroundColor Cyan
    Write-Host "   WIN-TOOLBOX-TUI v6.0  |  EXCLUSIVO WINDOWS 11  |  $dataHora  |  Host: $env:computername  |  User: $env:username" -ForegroundColor White
    Write-Host "============================================================================================================" -ForegroundColor Cyan
}

function Install-WingetApp {
    param(
        [Parameter(Mandatory=$true)] [string]$idApp,
        [Parameter(Mandatory=$false)] [string]$nomeAmigavel = ""
    )
    if ([string]::IsNullOrWhiteSpace($nomeAmigavel)) { $nomeAmigavel = $idApp }
    
    Write-Host "[*] Verificando: $nomeAmigavel ($idApp)..." -NoNewline -ForegroundColor Gray
    
    # Valida se o winget localiza o pacote já instalado
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
# 4. MANUTENÇÃO, REDE E REPAROS (BOAS PRÁTICAS WIN 11)
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

# ==============================================================================
# 5. TWEAKS EXCLUSIVOS DO WINDOWS 11
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
# 6. PERFIS AUTOMATIZADOS (MODO PMA & MODO DEV)
# ==============================================================================
function Invoke-ModoPMA {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO PMA (PADRÃO PREFEITURA WIN 11)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # Aplicativos corporativos essenciais
    Install-WingetApp "7zip.7zip" "7-Zip"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS"
    Install-WingetApp "Skillbrains.Lightshot" "Lightshot (Captura)"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk (Acesso Remoto)"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player"

    # Runtimes essenciais para Windows 11
    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE (LTS)"

    # Ajustes de sistema da prefeitura
    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    Write-Host "`n[✔] Perfil MODO PMA concluído com sucesso!" -ForegroundColor Green
}

function Invoke-ModoBRNCZZR {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   EXECUTANDO PERFIL: MODO BRNCZZR (DEV & WORKSTATION)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # Ferramentas de Desenvolvimento
    Install-WingetApp "Git.Git" "Git SCM"
    Install-WingetApp "Microsoft.VisualStudioCode" "Visual Studio Code"
    Install-WingetApp "Notepad++.Notepad++" "Notepad++"
    Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK (LTS)"
    Install-WingetApp "ApacheFriends.Xampp.8.2" "XAMPP (PHP & MySQL)"

    # Produtividade e Utilidades
    Install-WingetApp "7zip.7zip" "7-Zip"
    Install-WingetApp "Google.Chrome" "Google Chrome"
    Install-WingetApp "Mozilla.Firefox" "Mozilla Firefox"
    Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS"
    Install-WingetApp "RustDesk.RustDesk" "RustDesk"
    Install-WingetApp "VideoLAN.VLC" "VLC Media Player"

    # Runtimes .NET 8 e VC++
    Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
    Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"

    # Ajustes finos do Windows 11
    Enable-BuiltinAdmin
    Apply-Win11Tweaks

    Write-Host "`n[✔] Perfil MODO BRNCZZR concluído com sucesso!" -ForegroundColor Green
}

# ==============================================================================
# 7. INTERFACE TUI PRINCIPAL (LOOP INTERATIVO)
# ==============================================================================
while ($true) {
    Show-Header
    Write-Host @"
+------------------------------------------------------------------------------------------------------------+
|   0.  UPDATE ALL (Winget)              |       I M A G E M        |       U T I L I T A R I O S            |
|                                        |   4A. GIMP               |   7A. AnyDesk                          |
|       C O M P A C T A C A O            |   4B. Lightshot          |   7B. qBittorrent                      |
|   1A. 7-Zip                            |   4C. ShareX             |   7C. Rufus                            |
|   1B. WinRAR                           |                          |   7D. RustDesk                         |
|                                        |       M I D I A          |   7E. Transmission                     |
|       D E V                            |   5A. HandBrake          |   7F. RealVNC Viewer                   |
|   2A. Android Studio                   |   5B. K-Lite Codec Full  |                                        |
|   2B. Java Temurin 8 JDK               |   5C. VLC Media Player   |       M A N U T E N C A O              |
|   2C. Java Temurin 11 JDK              |                          |    8. Mapear Credencial de Rede        |
|   2D. Java Temurin 17 JDK (LTS)        |       R U N T I M E S    |    9. Habilitar Admin Local (SID 500)  |
|   2E. Java Temurin 21 JDK (LTS)        |   6A. .NET 8 Desktop LTS |   10. Renomear Computador              |
|   2F. Git                              |   6B. .NET 9 Desktop     |   11. Diagnóstico de Disco (Scan C:)   |
|   2G. Notepad++                        |   6C. VC++ 2015-2022 x64 |   12. Reparo Completo (DISM + SFC)     |
|   2H. VS Code                          |   6D. VC++ 2015-2022 x86 |   13. Forçar Atualização GPO           |
|   2I. Visual Studio Community          |   6E. VC++ All-in-One    |   14. Reset Pilha de Rede              |
|                                        |   6F. Java Temurin 17 JRE|   15. Tweaks Essenciais Windows 11     |
|       D O C U M E N T O S              |                          |                                        |
|   3A. Adobe Acrobat Reader             |                          |       P E R F I S   A U T O            |
|   3B. Foxit PDF Reader                 |                          |   16. MODO PMA (Prefeitura Win 11)     |
|   3C. LibreOffice LTS                  |                          |   17. MODO BRNCZZR (Dev Workstation)   |
+------------------------------------------------------------------------------------------------------------+
  (Dica: você pode digitar múltiplos itens separados por vírgula. Ex: 1A, 2F, 6A, 15)
"@ -ForegroundColor Gray

    $escolha = Read-Host "SELEÇÃO [Q para Sair]"
    if ([string]::IsNullOrWhiteSpace($escolha)) { continue }
    if ($escolha.Trim().ToUpper() -eq "Q") {
        Write-Host "`n[+] Encerrando win-toolbox-tui. Até logo!`n" -ForegroundColor Green
        break
    }

    $itens = $escolha -split ","
    foreach ($item in $itens) {
        $opcao = $item.Trim().ToUpper()
        switch ($opcao) {
            "0"  { Update-AllWinget }
            "1A" { Install-WingetApp "7zip.7zip" "7-Zip" }
            "1B" { Install-WingetApp "RARLab.WinRAR" "WinRAR" }
            
            "2A" { Install-WingetApp "Google.AndroidStudio" "Android Studio" }
            "2B" { Install-WingetApp "EclipseAdoptium.Temurin.8.JDK" "Java Temurin 8 JDK" }
            "2C" { Install-WingetApp "EclipseAdoptium.Temurin.11.JDK" "Java Temurin 11 JDK" }
            "2D" { Install-WingetApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK" }
            "2E" { Install-WingetApp "EclipseAdoptium.Temurin.21.JDK" "Java Temurin 21 JDK" }
            "2F" { Install-WingetApp "Git.Git" "Git SCM" }
            "2G" { Install-WingetApp "Notepad++.Notepad++" "Notepad++" }
            "2H" { Install-WingetApp "Microsoft.VisualStudioCode" "VS Code" }
            "2I" { Install-WingetApp "Microsoft.VisualStudio.2022.Community" "Visual Studio 2022 Community" }
            
            "3A" { Install-WingetApp "Adobe.Acrobat.Reader.64-bit" "Adobe Acrobat Reader" }
            "3B" { Install-WingetApp "Foxit.FoxitReader" "Foxit PDF Reader" }
            "3C" { Install-WingetApp "TheDocumentFoundation.LibreOffice.LTS" "LibreOffice LTS" }
            
            "4A" { Install-WingetApp "GIMP.GIMP" "GIMP" }
            "4B" { Install-WingetApp "Skillbrains.Lightshot" "Lightshot" }
            "4C" { Install-WingetApp "ShareX.ShareX" "ShareX" }
            
            "5A" { Install-WingetApp "HandBrake.HandBrake" "HandBrake" }
            "5B" { Install-WingetApp "CodecGuide.K-LiteCodecPack.Full" "K-Lite Codec Pack Full" }
            "5C" { Install-WingetApp "VideoLAN.VLC" "VLC Media Player" }
            
            "6A" { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)" }
            "6B" { Install-WingetApp "Microsoft.DotNet.DesktopRuntime.9" ".NET 9 Desktop Runtime" }
            "6C" { Install-WingetApp "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 x64" }
            "6D" { Install-WingetApp "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 x86" }
            "6E" { Install-WingetApp "abbodi1406.vcredist" "Visual C++ All-in-One Runtime" }
            "6F" { Install-WingetApp "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE" }
            
            "7A" { Install-WingetApp "AnyDeskSoftwareGmbH.AnyDesk" "AnyDesk" }
            "7B" { Install-WingetApp "qBittorrent.qBittorrent" "qBittorrent" }
            "7C" { Install-WingetApp "Rufus.Rufus" "Rufus" }
            "7D" { Install-WingetApp "RustDesk.RustDesk" "RustDesk" }
            "7E" { Install-WingetApp "Transmission.Transmission" "Transmission" }
            "7F" { Install-WingetApp "RealVNC.VNCViewer" "RealVNC Viewer" }
            
            "8"  { Add-NetworkCredential }
            "9"  { Enable-BuiltinAdmin }
            "10" { Set-MachineName }
            "11" { Invoke-DiskCheck }
            "12" { Invoke-SystemRepair }
            "13" { Invoke-UpdateGPO }
            "14" { Invoke-NetworkReset }
            "15" { Apply-Win11Tweaks }
            
            "16" { Invoke-ModoPMA }
            "17" { Invoke-ModoBRNCZZR }
            
            default {
                Write-Host "[!] Opção '$opcao' inválida ou não reconhecida." -ForegroundColor Red
            }
        }
    }

    Write-Host "`nProcessamento da seleção concluído." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
}
