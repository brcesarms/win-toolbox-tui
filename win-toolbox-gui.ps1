<#
.SYNOPSIS
    WIN-TOOLBOX-TUI [POC GUI v0.3.0] — Interface gráfica 100% nativa (Windows Forms)
.DESCRIPTION
    Janela construída inteiramente com PowerShell + Windows Forms (.NET nativo, SEM XAML).
    Checkboxes reais clicáveis, paleta de cores idêntica ao TUI:
    Cyan (#22D3EE) · Amarelo (#FFD54A) · Verde (#3FB950) · Cinza (#8B949E) ·
    DarkGray (#6E7681) · Vermelho (#F85149).
    Fase 1 (POC): aba funcional com instalação via winget em background (runspace).
    Compatível com o one-liner: irm .../win-toolbox-gui.ps1 | iex
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    0.3.0 — POC GUI Windows Forms (nativo)
#>

[CmdletBinding()]
param()

# ==============================================================================
# 0. VERIFICAÇÃO DE ELEVAÇÃO (informa no log; instalação exige admin)
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

# ==============================================================================
# 1. CARREGAMENTO .NET (WINDOWS FORMS — sem XAML, 100% nativo)
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==============================================================================
# 2. PALETA DO TUI (convertida de ANSI para System.Drawing.Color)
# ==============================================================================
function Hex { param([string]$h) [System.Drawing.ColorTranslator]::FromHtml($h) }

$cBg      = Hex "#0D1117"
$cPanel   = Hex "#161B22"
$cCard    = Hex "#1C2128"
$cBorder  = Hex "#30363D"
$cCyan    = Hex "#22D3EE"
$cYellow  = Hex "#FFD54A"
$cGreen   = Hex "#3FB950"
$cRed     = Hex "#F85149"
$cText    = Hex "#E6EDF3"
$cMuted   = Hex "#8B949E"
$cDark    = Hex "#6E7681"
$cTrack   = Hex "#21262D"
$cLogBg   = Hex "#010409"

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$fontSec   = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontApp   = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fontAppB  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontInfo  = New-Object System.Drawing.Font("Segoe UI", 9)
$fontTab   = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$fontLog   = New-Object System.Drawing.Font("Consolas", 10)

# ==============================================================================
# 3. JANELA PRINCIPAL
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "WIN-TOOLBOX-TUI · GUI · Windows 11"
$form.Size            = New-Object System.Drawing.Size(1040, 760)
$form.MinimumSize     = New-Object System.Drawing.Size(900, 640)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = $fontInfo
$form.Padding         = [System.Windows.Forms.Padding]::new(10)
$form.AutoScaleMode   = "Font"

# ==============================================================================
# 4. CABEÇALHO (espelha o Show-Header do TUI)
# ==============================================================================
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock       = "Top"
$pnlHeader.Height     = 138
$pnlHeader.BackColor  = $cBg

# Linha 1: título Cyan + badge "WINDOWS 11" amarelo
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text       = "WIN-TOOLBOX-TUI"
$lblTitulo.Font       = $fontTitle
$lblTitulo.ForeColor  = $cCyan
$lblTitulo.AutoSize   = $true
$lblTitulo.Location   = New-Object System.Drawing.Point(12, 6)

$badgeW11 = New-Object System.Windows.Forms.Label
$badgeW11.Text        = "  WINDOWS 11  "
$badgeW11.Font        = $fontSec
$badgeW11.ForeColor   = $cBg
$badgeW11.BackColor   = $cYellow
$badgeW11.AutoSize    = $true
$badgeW11.Padding     = [System.Windows.Forms.Padding]::new(6, 2, 6, 2)
$badgeW11.Anchor      = "Top|Right"
$badgeW11.Location    = New-Object System.Drawing.Point(900, 12)

# Linha 2: tela corrente (TELA: do TUI)
$lblTela = New-Object System.Windows.Forms.Label
$lblTela.Text         = "TELA: SOFTWARES ESSENCIAIS"
$lblTela.Font         = $fontSec
$lblTela.ForeColor    = $cCyan
$lblTela.AutoSize     = $true
$lblTela.Location     = New-Object System.Drawing.Point(12, 48)

# Linha 3: telemetria (Data / Computador / Usuário / IP)
$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Font         = $fontInfo
$lblInfo.ForeColor    = $cMuted
$lblInfo.AutoSize     = $true
$lblInfo.Location     = New-Object System.Drawing.Point(12, 72)

# ==============================================================================
# 5. BARRA DE ABAS (botões flat — controle visual total, sem TabControl padrão)
# ==============================================================================
$pnlAbas = New-Object System.Windows.Forms.Panel
$pnlAbas.Dock        = "Bottom"
$pnlAbas.Height      = 38
$pnlAbas.BackColor   = $cPanel

$btnTabSoft = New-Object System.Windows.Forms.Button
$btnTabDev  = New-Object System.Windows.Forms.Button
$btnTabMant = New-Object System.Windows.Forms.Button

$i = 0
foreach ($b in @($btnTabSoft, $btnTabDev, $btnTabMant)) {
    $b.FlatStyle      = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = $cCard
    $b.FlatAppearance.MouseDownBackColor = $cCard
    $b.BackColor      = $cPanel
    $b.ForeColor      = $cMuted
    $b.Font           = $fontTab
    $b.Height         = 34
    $b.Width          = 220
    $b.Location       = New-Object System.Drawing.Point((12 + $i * 226), 2)
    $b.Cursor         = [System.Windows.Forms.Cursors]::Hand
    $i++
}
$btnTabSoft.Text = "Softwares Essenciais"
$btnTabDev.Text  = "Desenvolvimento"
$btnTabMant.Text = "Manutenção & Perfis"

$pnlAbas.Controls.AddRange(@($btnTabSoft, $btnTabDev, $btnTabMant))

# Montagem do cabeçalho (pnlAbas Dock=Bottom primeiro para o layout fechar)
$pnlHeader.Controls.Add($pnlAbas)
$pnlHeader.Controls.Add($lblTitulo)
$pnlHeader.Controls.Add($badgeW11)
$pnlHeader.Controls.Add($lblTela)
$pnlHeader.Controls.Add($lblInfo)

# ==============================================================================
# 6. CORPO: 3 PAINÉIS DE CONTEÚDO (1 por aba)
# ==============================================================================
$pnlBody = New-Object System.Windows.Forms.Panel
$pnlBody.Dock      = "Fill"
$pnlBody.BackColor = $cCard

# ---- Aba 1: Softwares Essenciais (scroll + seções + checkboxes) ----
$pnlSoft = New-Object System.Windows.Forms.Panel
$pnlSoft.Dock       = "Fill"
$pnlSoft.BackColor  = $cCard
$pnlSoft.AutoScroll = $true

$sections = @(
    @{
        Title = "╭─ COMPACTAÇÃO ────────────────────────────────╮"
        Apps  = @(
            @{ Id = "7zip.7zip"; Nome = "7-Zip" },
            @{ Id = "RARLab.WinRAR"; Nome = "WinRAR" }
        )
    },
    @{
        Title = "╭─ DOCUMENTOS ─────────────────────────────────╮"
        Apps  = @(
            @{ Id = "TheDocumentFoundation.LibreOffice.LTS"; Nome = "LibreOffice LTS" },
            @{ Id = "Adobe.Acrobat.Reader.64-bit"; Nome = "Adobe Acrobat Reader" }
        )
    },
    @{
        Title = "╭─ IMAGEM & VÍDEO ───────────────────────────────╮"
        Apps  = @(
            @{ Id = "GIMP.GIMP"; Nome = "GIMP" },
            @{ Id = "ShareX.ShareX"; Nome = "ShareX" },
            @{ Id = "VideoLAN.VLC"; Nome = "VLC Media Player" }
        )
    },
    @{
        Title = "╭─ RUNTIMES WIN 11 ─────────────────────────────╮"
        Apps  = @(
            @{ Id = "Microsoft.DotNet.DesktopRuntime.8"; Nome = ".NET 8 Desktop Runtime" },
            @{ Id = "Microsoft.VCRedist.2015+.x64"; Nome = "Visual C++ 2015-2022 (x64)" },
            @{ Id = "Microsoft.VCRedist.2015+.x86"; Nome = "Visual C++ 2015-2022 (x86)" },
            @{ Id = "EclipseAdoptium.Temurin.17.JRE"; Nome = "Java Temurin 17 JRE" }
        )
    },
    @{
        Title = "╭─ ACESSO REMOTO & UTILITÁRIOS ──────────────────╮"
        Apps  = @(
            @{ Id = "AnyDeskSoftwareGmbH.AnyDesk"; Nome = "AnyDesk" },
            @{ Id = "RustDesk.RustDesk"; Nome = "RustDesk" },
            @{ Id = "qBittorrent.qBittorrent"; Nome = "qBittorrent" },
            @{ Id = "Rufus.Rufus"; Nome = "Rufus (boot)" }
        )
    }
)

$y = 12
foreach ($sec in $sections) {
    # Título da seção em amarelo bold (header 1;93m do TUI)
    $lblSecao = New-Object System.Windows.Forms.Label
    $lblSecao.Text      = $sec.Title
    $lblSecao.Font      = $fontSec
    $lblSecao.ForeColor = $cYellow
    $lblSecao.AutoSize  = $true
    $lblSecao.Location  = New-Object System.Drawing.Point(18, $y)
    $pnlSoft.Controls.Add($lblSecao)
    $y += 26

    # Checkboxes em linha (quebra quando estoura a largura)
    $x = 18
    foreach ($app in $sec.Apps) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text      = $app.Nome
        $cb.Tag       = "$($app.Id)|$($app.Nome)"
        $cb.Font      = $fontApp
        $cb.ForeColor = $cMuted
        $cb.FlatStyle = "Flat"
        $cb.FlatAppearance.BorderColor        = $cMuted
        $cb.FlatAppearance.CheckedBackColor   = $cGreen
        $cb.FlatAppearance.MouseOverBackColor = $cPanel
        $cb.FlatAppearance.MouseDownBackColor = $cPanel
        $cb.AutoSize  = $true
        $cb.Cursor    = [System.Windows.Forms.Cursors]::Hand
        # [✓] verde quando marcado / [ ] cinza quando não (igual TUI)
        $cb.Add_CheckedChanged({
            if ($this.Checked) {
                $this.ForeColor = $cGreen
                $this.Font      = $fontAppB
            } else {
                $this.ForeColor = $cMuted
                $this.Font      = $fontApp
            }
        })
        $cb.Location = New-Object System.Drawing.Point($x, $y)
        $pnlSoft.Controls.Add($cb)

        $w = $cb.PreferredSize.Width + 34   # checkbox + respiro
        if (($x + $w) -gt 940) {
            $x = 18
            $y += 36
            $cb.Location = New-Object System.Drawing.Point($x, $y)
        }
        $x += $w
        if ($cb.Height -gt 28) { $yUp = $cb.Height }  # safety
    }
    $y += 44
}
$pnlSoft.AutoScrollMinSize = New-Object System.Drawing.Size(0, ($y + 12))

# ---- Aba 2: Desenvolvimento (placeholder Fase 2) ----
$pnlDev = New-Object System.Windows.Forms.Panel
$pnlDev.Dock      = "Fill"
$pnlDev.BackColor = $cCard

$lblDevTitulo = New-Object System.Windows.Forms.Label
$lblDevTitulo.Text      = "FASE 2 — EM DESENVOLVIMENTO"
$lblDevTitulo.Font      = $fontSec
$lblDevTitulo.ForeColor = $cYellow
$lblDevTitulo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblDevTitulo.Dock      = "Top"
$lblDevTitulo.Height    = 40
$lblDevTitulo.Padding   = [System.Windows.Forms.Padding]::new(0, 120, 0, 0)

$lblDevSub = New-Object System.Windows.Forms.Label
$lblDevSub.Text      = "VS Code · Git · Notepad++ · JDKs · XAMPP"
$lblDevSub.Font      = $fontInfo
$lblDevSub.ForeColor = $cDark
$lblDevSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblDevSub.Dock      = "Top"
$lblDevSub.Height    = 30
$lblDevSub.Padding   = [System.Windows.Forms.Padding]::new(0, 10, 0, 0)

$pnlDev.Controls.Add($lblDevSub)
$pnlDev.Controls.Add($lblDevTitulo)

# ---- Aba 3: Manutenção & Perfis (placeholder Fase 2) ----
$pnlMant = New-Object System.Windows.Forms.Panel
$pnlMant.Dock      = "Fill"
$pnlMant.BackColor = $cCard

$lblMantTitulo = New-Object System.Windows.Forms.Label
$lblMantTitulo.Text      = "FASE 2 — EM DESENVOLVIMENTO"
$lblMantTitulo.Font      = $fontSec
$lblMantTitulo.ForeColor = $cYellow
$lblMantTitulo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblMantTitulo.Dock      = "Top"
$lblMantTitulo.Height    = 40
$lblMantTitulo.Padding   = [System.Windows.Forms.Padding]::new(0, 120, 0, 0)

$lblMantSub = New-Object System.Windows.Forms.Label
$lblMantSub.Text      = "DISM/SFC · Rede · OpenSSH · Tweaks · P1/P2"
$lblMantSub.Font      = $fontInfo
$lblMantSub.ForeColor = $cDark
$lblMantSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblMantSub.Dock      = "Top"
$lblMantSub.Height    = 30
$lblMantSub.Padding   = [System.Windows.Forms.Padding]::new(0, 10, 0, 0)

$pnlMant.Controls.Add($lblMantSub)
$pnlMant.Controls.Add($lblMantTitulo)

# Navegação entre abas (estilo: ativa = amarelo; inativa = cinza)
function Set-Aba {
    param([string]$tela, [System.Windows.Forms.Panel]$pnlAtivo)
    $lblTela.Text = "TELA: $tela"
    foreach ($pnl in @($pnlSoft, $pnlDev, $pnlMant)) {
        $pnl.Visible = ($pnl -eq $pnlAtivo)
    }
    foreach ($b in @($btnTabSoft, $btnTabDev, $btnTabMant)) {
        $ativo = ($b.Tag -eq $pnlAtivo.Name)
        if ($ativo) {
            $b.BackColor = $cCard
            $b.ForeColor = $cYellow
        } else {
            $b.BackColor = $cPanel
            $b.ForeColor = $cMuted
        }
    }
}
$btnTabSoft.Tag = "pnlSoft"
$btnTabDev.Tag  = "pnlDev"
$btnTabMant.Tag = "pnlMant"
$pnlSoft.Name = "pnlSoft"
$pnlDev.Name  = "pnlDev"
$pnlMant.Name = "pnlMant"

$btnTabSoft.Add_Click({ Set-Aba "SOFTWARES ESSENCIAIS" $pnlSoft })
$btnTabDev.Add_Click({  Set-Aba "DESENVOLVIMENTO" $pnlDev })
$btnTabMant.Add_Click({ Set-Aba "MANUTENÇÃO & PERFIS" $pnlMant })

$pnlBody.Controls.Add($pnlMant)
$pnlBody.Controls.Add($pnlDev)
$pnlBody.Controls.Add($pnlSoft)

# ==============================================================================
# 7. RODAPÉ: status + botão + barra de progresso custom (Cyan)
# ==============================================================================
$pnlFooter = New-Object System.Windows.Forms.Panel
$pnlFooter.Dock      = "Bottom"
$pnlFooter.Height    = 76
$pnlFooter.BackColor = $cBg
$pnlFooter.Padding   = [System.Windows.Forms.Padding]::new(4, 12, 4, 8)

# Barra de progresso custom: trilho escuro + preenchimento Cyan
$pnlTrack = New-Object System.Windows.Forms.Panel
$pnlTrack.Dock      = "Bottom"
$pnlTrack.Height    = 12
$pnlTrack.BackColor = $cTrack

$pnlFill = New-Object System.Windows.Forms.Panel
$pnlFill.BackColor  = $cCyan
$pnlFill.Size       = New-Object System.Drawing.Size(0, 12)
$pnlFill.Location   = New-Object System.Drawing.Point(0, 0)
$pnlTrack.Controls.Add($pnlFill)

# Linha de comandos: botão verde à direita + status à esquerda
$pnlCmds = New-Object System.Windows.Forms.Panel
$pnlCmds.Dock      = "Fill"
$pnlCmds.BackColor = $cBg

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text      = "Instalar Selecionados"
$btnInstalar.Font      = $fontSec
$btnInstalar.BackColor = $cGreen
$btnInstalar.ForeColor = $cBg
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderSize = 0
$btnInstalar.FlatAppearance.MouseOverBackColor = $cGreen
$btnInstalar.FlatAppearance.MouseDownBackColor = $cGreen
$btnInstalar.Size      = New-Object System.Drawing.Size(230, 38)
$btnInstalar.Dock      = "Right"
$btnInstalar.Cursor    = [System.Windows.Forms.Cursors]::Hand

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Pronto"
$lblStatus.Font      = $fontInfo
$lblStatus.ForeColor = $cMuted
$lblStatus.AutoSize  = $false
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblStatus.Dock      = "Fill"

$pnlCmds.Controls.Add($lblStatus)
$pnlCmds.Controls.Add($btnInstalar)

# Rodapé vazio auxiliar para respiro entre comando e barra
$pnlFooter.Controls.Add($pnlTrack)
$pnlFooter.Controls.Add($pnlCmds)

# ==============================================================================
# 8. LOG (RichTextBox colorido por linha — estilo terminal)
# ==============================================================================
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock      = "Bottom"
$pnlLog.Height    = 175
$pnlLog.BackColor = $cBg
$pnlLog.Padding   = [System.Windows.Forms.Padding]::new(2)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock          = "Fill"
$txtLog.ReadOnly      = $true
$txtLog.BackColor     = $cLogBg
$txtLog.ForeColor     = Hex "#C9D1D9"
$txtLog.Font          = $fontLog
$txtLog.BorderStyle   = "None"
$txtLog.ScrollBars    = "Vertical"
$txtLog.DetectUrls    = $false
$txtLog.BackColor     = $cLogBg
$pnlLog.Controls.Add($txtLog)

# ==============================================================================
# 9. MONTAGEM DA JANELA (ordem de Dock importa)
# ==============================================================================
$form.Controls.Add($pnlBody)
$form.Controls.Add($pnlLog)
$form.Controls.Add($pnlFooter)
$form.Controls.Add($pnlHeader)

# ==============================================================================
# 10. ESTADO COMPARTILHADO + LOG
# ==============================================================================
$sync = @{
    Log       = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    Progresso = 0
    Total     = 0
    Ocupado   = $false
}

function Add-Log {
    param([string]$msg)
    $sync.Log.Enqueue(("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg))
}

function Add-RichLine {
    param([System.Windows.Forms.RichTextBox]$rtb, [string]$text, [string]$hex)
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.SelectionLength = 0
    $rtb.SelectionColor  = (Hex $hex)
    $rtb.AppendText($text + [Environment]::NewLine)
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.ScrollToCaret()
}

# ==============================================================================
# 11. DADOS DO CABEÇALHO (mesma telemetria do Show-Header do TUI)
# ==============================================================================
$data = (Get-Date).ToString("dd/MM/yyyy")
$ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
    $_.IPAddress -ne "127.0.0.1" -and
    $_.IPAddress -notlike "169.254*" -and
    $_.InterfaceAlias -notlike "*Loopback*" -and
    $_.InterfaceAlias -notlike "*vEthernet*"
} | Select-Object -ExpandProperty IPAddress -First 1)
if ([string]::IsNullOrWhiteSpace($ip)) { $ip = "N/A" }
$lblInfo.Text = " Data: $data  |  Computador: $env:computername  |  Usuario: $env:username  |  IP: $ip"

# ==============================================================================
# 12. COLETA RECURSIVA DE CHECKBOXES
# ==============================================================================
function Get-AllCheckBoxes {
    param($parent)
    $result = @()
    foreach ($ctrl in $parent.Controls) {
        if ($ctrl -is [System.Windows.Forms.CheckBox]) {
            $result += $ctrl
        } elseif ($ctrl) {
            $result += Get-AllCheckBoxes $ctrl
        }
    }
    return $result
}

# ==============================================================================
# 13. AÇÃO: INSTALAR SELECIONADOS (background via runspace — UI não congela)
# ==============================================================================
Add-Log "[i] win-toolbox-tui GUI (POC v0.3.0 — Windows Forms) iniciada."
if (-not $isAdmin) {
    Add-Log "[!] Você NÃO está como Administrador — o winget pode falhar nas instalações."
} else {
    Add-Log "[✓] Executando como Administrador."
}

$btnInstalar.Add_Click({
    if ($sync.Ocupado) {
        Add-Log "[!] Já existe uma instalação em andamento. Aguarde."
        return
    }

    $apps = @()
    foreach ($cb in Get-AllCheckBoxes $pnlSoft) {
        if ($cb.Checked -and $cb.Tag) {
            $p = ($cb.Tag -split '\|')
            $apps += [pscustomobject]@{ Id = $p[0]; Nome = $p[1] }
        }
    }

    if ($apps.Count -eq 0) {
        Add-Log "[!] Nenhuma opção selecionada. Marque ao menos uma caixa."
        return
    }

    $sync.Total = $apps.Count
    $sync.Progresso = 0
    $sync.Ocupado = $true
    $btnInstalar.Text = "Instalando…"
    Add-Log "[*] Iniciando instalação de $($apps.Count) aplicativo(s)..."

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($apps, $sync)

        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            $sync.Log.Enqueue("[ERRO] winget não encontrado (App Installer ausente).")
            $sync.Progresso = $sync.Total
            $sync.Ocupado = $false
            return
        }

        foreach ($a in $apps) {
            $sync.Log.Enqueue(("[{0}] [*] Instalando: {1} ({2})..." -f (Get-Date -Format "HH:mm:ss"), $a.Nome, $a.Id))
            $sync.Log.Enqueue(("[{0}] [>] winget install --id {1} --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity" -f (Get-Date -Format "HH:mm:ss"), $a.Id))
            & winget install --id $a.Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
            $status = if ($LASTEXITCODE -eq 0) { "[OK]" } else { "[FALHA]" }
            $sync.Log.Enqueue(("[{0}] {1} {2} — exit {3}" -f (Get-Date -Format "HH:mm:ss"), $status, $a.Nome, $LASTEXITCODE))
            $sync.Progresso++
        }

        $sync.Log.Enqueue(("[{0}] [✓] Lote concluído!" -f (Get-Date -Format "HH:mm:ss")))
        $sync.Ocupado = $false
    }).AddArgument($apps).AddArgument($sync)

    [void]$ps.BeginInvoke()
})

# ==============================================================================
# 14. TIMER: ATUALIZA UI (progresso + log) SEM CONGELAR
# ==============================================================================
$ultimoIndice = 0

function Update-LogViewer {
    $linhas = $sync.Log.ToArray()
    $total  = $linhas.Count

    for ($i = $ultimoIndice; $i -lt $total; $i++) {
        $linha = $linhas[$i]
        $cor = "#C9D1D9"
        if     ($linha -match "\[OK\]|\[✓\]")                 { $cor = "#3FB950" }
        elseif ($linha -match "\[ERRO\]")                      { $cor = "#F85149" }
        elseif ($linha -match "\[!\]|\[FALHA\]|\[WARN\]")     { $cor = "#FFD54A" }
        elseif ($linha -match "\[i\]")                         { $cor = "#8B949E" }
        elseif ($linha -match "\[>\]")                         { $cor = "#6E7681" }
        elseif ($linha -match "\[\*\]")                        { $cor = "#22D3EE" }
        Add-RichLine $txtLog $linha $cor
    }
    $script:ultimoIndice = $total

    # Limita o log em ~400 linhas para não pesar a UI
    if ($txtLog.Lines.Count -gt 400) {
        $remover = $txtLog.Lines.Count - 400
        $txtLog.Select(0, $txtLog.GetFirstCharIndexFromLine($remover))
        $txtLog.SelectedText = ""
    }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 250
$timer.Add_Tick({
    if ($sync.Ocupado) {
        $lblStatus.Text = "Instalando… $($sync.Progresso) / $($sync.Total)"
    } else {
        $lblStatus.Text = "Pronto"
        if ($btnInstalar.Text -ne "Instalar Selecionados") { $btnInstalar.Text = "Instalar Selecionados" }
    }

    # Barra de progresso custom (Cyan)
    $frac = $sync.Progresso / [Math]::Max(1, $sync.Total)
    $pnlFill.Width = [int]($pnlTrack.Width * $frac)

    Update-LogViewer
})
$timer.Start()

# ==============================================================================
# 15. MOSTRAR JANELA
# ==============================================================================
[void]$form.ShowDialog()
Write-Host "[✓] GUI encerrada. Até logo!" -ForegroundColor Green