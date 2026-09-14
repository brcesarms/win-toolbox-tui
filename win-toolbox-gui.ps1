<#
.SYNOPSIS
    WIN-TOOLBOX-TUI [GUI v0.4.0] — Interface gráfica profissional (Windows Forms nativo)
.DESCRIPTION
    Janela 100% nativa (SEM XAML) com layout profissional:
      - Cards por seção com grid alinhado em colunas (checkboxes desenhados sob medida)
      - Detecção de apps JÁ INSTALADOS via 'winget export' (JSON) em background
      - Instalação via winget em runspace (UI nunca congela)
      - Paleta idêntica ao TUI: Cyan (#22D3EE) · Amarelo (#FFD54A) · Verde (#3FB950)
    Compatível com o one-liner: irm .../win-toolbox-gui.ps1 | iex
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    0.4.0 — GUI profissional: cards, grid, detecção de instalados
#>

[CmdletBinding()]
param()

# ==============================================================================
# 0. VERIFICAÇÃO DE ELEVAÇÃO (informa no log/header; instalação exige admin)
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

# ==============================================================================
# 1. CARREGAMENTO .NET (WINDOWS FORMS — sem XAML, 100% nativo)
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==============================================================================
# 2. PALETA (conversão de ANSI do TUI para System.Drawing.Color)
# ==============================================================================
function Hex { param([string]$h) [System.Drawing.ColorTranslator]::FromHtml($h) }

$cBg      = Hex "#0D1117"
$cPanel   = Hex "#161B22"
$cCard    = Hex "#1C2128"
$cBorder  = Hex "#30363D"
$cTrack   = Hex "#21262D"
$cCyan    = Hex "#22D3EE"
$cYellow  = Hex "#FFD54A"
$cGreen   = Hex "#3FB950"
$cRed     = Hex "#F85149"
$cText    = Hex "#E6EDF3"
$cMuted   = Hex "#8B949E"
$cDark    = Hex "#6E7681"
$cLogBg   = Hex "#010409"

$checkGlyph = [string][char]0x2713

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 21, [System.Drawing.FontStyle]::Bold)
$fontSub   = New-Object System.Drawing.Font("Segoe UI", 9.5)
$fontSec   = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontApp   = New-Object System.Drawing.Font("Segoe UI", 10.5)
$fontAppB  = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$fontInfo  = New-Object System.Drawing.Font("Segoe UI", 9)
$fontBadge = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$fontTab   = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$fontLog   = New-Object System.Drawing.Font("Consolas", 9.5)

# ==============================================================================
# 3. AUXILIARES GRÁFICOS
# ==============================================================================
function New-RoundRectPath {
    param([float]$X, [float]$Y, [float]$W, [float]$H, [float]$R)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $R * 2
    $p.AddArc($X, $Y, $d, $d, 180, 90)
    $p.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $p.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $p.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-Brush { param($color) New-Object System.Drawing.SolidBrush($color) }
function New-Pen   { param($color) New-Object System.Drawing.Pen($color) }

# ==============================================================================
# 4. CHECKBOX DESENHADO SOB MEDIDA (OwnerDraw — visual profissional)
# ==============================================================================
$script:cbHover = $null

function New-ToolCheckBox {
    param([string]$Text, [string]$TagId)

    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text       = $Text
    $cb.Tag        = $TagId
    $cb.Font       = $fontApp
    $cb.AutoSize   = $false
    $cb.Size       = New-Object System.Drawing.Size(320, 30)
    $cb.BackColor  = $cCard
    $cb.OwnerDraw  = $true
    $cb.Cursor     = [System.Windows.Forms.Cursors]::Hand

    # Hover (invalida para redesenhar)
    $cb.Add_MouseEnter({ $script:cbHover = $this; $this.Invalidate() })
    $cb.Add_MouseLeave({ if ($script:cbHover -eq $this) { $script:cbHover = $null }; $this.Invalidate() })

    $cb.Add_DrawItem({
        param($sender, $e)
        $chk = $sender
        $isInst = $script:instaladosMap.ContainsKey($chk.Tag)
        $g   = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $r   = $chk.ClientRectangle

        # Fundo (card padrão / painel quando hover / levemente escuro se instalado)
        $bg = if ($isInst) { $cPanel } elseif ($script:cbHover -eq $chk -and $chk.Enabled) { $cTrack } else { $cCard }
        $g.FillRectangle((New-Brush $bg), $r)

        # Quadradinho (rounded)
        $bs = 17
        $bx = New-Object System.Drawing.Rectangle(0, [int](($r.Height - $bs) / 2), $bs, $bs)
        $path = New-RoundRectPath $bx.X $bx.Y $bx.Width $bx.Height 4
        $corBox = if ($chk.Checked) { $cGreen } else { $cPanel }
        $g.FillPath((New-Brush $corBox), $path)
        if (-not $chk.Checked) {
            $g.DrawPath((New-Pen $cMuted), $path)
        } else {
            $g.DrawString($checkGlyph, $chk.Font, (New-Brush $cBg), ($bx.X + 2.5), ($bx.Y - 1))
        }

        # Texto (verde quando marcado/instalado; claro quando disponível; cinza se inativo)
        $corTexto = if ($isInst) { $cGreen }
                    elseif ($chk.Checked) { $cGreen }
                    elseif ($chk.Enabled) { $cText }
                    else { $cMuted }
        $g.DrawString($chk.Text, $chk.Font, (New-Brush $corTexto),
            (New-Object System.Drawing.PointF(27, (($r.Height - $chk.Font.Height) / 2) + 0.5)))
    })
    return $cb
}

# ==============================================================================
# 5. CARD DE SEÇÃO (título + separador + grid de 3 colunas alinhado)
# ==============================================================================
$cardWidth = 1050
$colWidth  = 320
$colGap    = 14

function Add-SectionCard {
    param(
        [System.Windows.Forms.Panel]$Parent,
        [string]$Title,
        [object[]]$Apps,
        [int]$Y
    )

    $card = New-Object System.Windows.Forms.Panel
    $card.BackColor     = $cCard
    $card.BorderStyle   = [System.Windows.Forms.BorderStyle]::FixedSingle
    $card.Size          = New-Object System.Drawing.Size($cardWidth, 60)
    $card.Location      = New-Object System.Drawing.Point(12, $Y)
    $card.Anchor        = "Top|Left|Right"

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Title.ToUpper()
    $lbl.Font      = $fontSec
    $lbl.ForeColor = $cCyan
    $lbl.AutoSize  = $true
    $lbl.Location  = New-Object System.Drawing.Point(16, 10)
    $card.Controls.Add($lbl)

    $sep = New-Object System.Windows.Forms.Panel
    $sep.BackColor = $cBorder
    $sep.Size      = New-Object System.Drawing.Size(($cardWidth - 32), 1)
    $sep.Location  = New-Object System.Drawing.Point(16, 38)
    $card.Controls.Add($sep)

    # Grid 3 colunas
    $x = 18; $y = 50; $idx = 0
    foreach ($app in $Apps) {
        $cb = New-ToolCheckBox -Text $app.Nome -TagId $app.Id
        $cb.Location = New-Object System.Drawing.Point(($x + ($idx % 3) * ($colWidth + $colGap)), $y)
        $cb.Size     = New-Object System.Drawing.Size($colWidth, 30)
        $card.Controls.Add($cb)

        if (($idx % 3) -eq 2) { $y += 34 }
        $idx++
    }
    if (($idx % 3) -ne 0) { $y += 34 }
    $card.Height = $y + 6
    $Parent.Controls.Add($card)
    return $card
}

# ==============================================================================
# 6. CARD INFORMATIVO (aba Manutenção — itens executáveis no TUI/Fase 2)
# ==============================================================================
function Add-InfoCard {
    param(
        [System.Windows.Forms.Panel]$Parent,
        [string]$Title,
        [string[]]$Items,
        [int]$Y
    )

    $card = New-Object System.Windows.Forms.Panel
    $card.BackColor     = $cCard
    $card.BorderStyle   = [System.Windows.Forms.BorderStyle]::FixedSingle
    $card.Size          = New-Object System.Drawing.Size($cardWidth, 60)
    $card.Location      = New-Object System.Drawing.Point(12, $Y)
    $card.Anchor        = "Top|Left|Right"

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Title.ToUpper()
    $lbl.Font      = $fontSec
    $lbl.ForeColor = $cYellow
    $lbl.AutoSize  = $true
    $lbl.Location  = New-Object System.Drawing.Point(16, 10)
    $card.Controls.Add($lbl)

    $sep = New-Object System.Windows.Forms.Panel
    $sep.BackColor = $cBorder
    $sep.Size      = New-Object System.Drawing.Size(($cardWidth - 32), 1)
    $sep.Location  = New-Object System.Drawing.Point(16, 38)
    $card.Controls.Add($sep)

    $y = 50
    $x = 18; $idx = 0
    foreach ($item in $Items) {
        $itemLabel = New-Object System.Windows.Forms.Label
        $itemLabel.Text      = "•  $item"
        $itemLabel.Font      = $fontApp
        $itemLabel.ForeColor = $cText
        $itemLabel.AutoSize  = $true
        $itemLabel.Location  = New-Object System.Drawing.Point(($x + ($idx % 2) * 380), $y)
        $card.Controls.Add($itemLabel)
        if (($idx % 2) -eq 1) { $y += 30 }
        $idx++
    }
    if (($idx % 2) -ne 0) { $y += 30 }
    $card.Height = $y + 10
    $Parent.Controls.Add($card)
    return $card
}

# ==============================================================================
# 7. JANELA PRINCIPAL
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "WIN-TOOLBOX-TUI · GUI · Windows 11"
$form.Size            = New-Object System.Drawing.Size(1100, 800)
$form.MinimumSize     = New-Object System.Drawing.Size(960, 680)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = $fontInfo
$form.Padding         = [System.Windows.Forms.Padding]::new(0)
$form.AutoScaleMode   = "Font"

# ==============================================================================
# 8. CABEÇALHO (título + badges + telemetria + separador)
# ==============================================================================
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock      = "Top"
$pnlHeader.Height    = 100
$pnlHeader.BackColor = $cBg

# Título + sub
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text       = "WIN-TOOLBOX-TUI"
$lblTitulo.Font       = $fontTitle
$lblTitulo.ForeColor  = $cCyan
$lblTitulo.AutoSize   = $true
$lblTitulo.Location   = New-Object System.Drawing.Point(16, 8)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text       = "Interface profissional · Preparação de Windows 11 pós-formatação"
$lblSub.Font       = $fontSub
$lblSub.ForeColor  = $cMuted
$lblSub.AutoSize   = $true
$lblSub.Location   = New-Object System.Drawing.Point(18, 52)

# Badge Admin (direita)
$badgeAdmin = New-Object System.Windows.Forms.Label
$badgeAdmin.Font      = $fontBadge
$badgeAdmin.AutoSize  = $true
$badgeAdmin.Padding   = [System.Windows.Forms.Padding]::new(8, 3, 8, 3)
$badgeAdmin.Anchor    = "Top|Right"
$badgeAdmin.Location  = New-Object System.Drawing.Point(940, 12)
if ($isAdmin) {
    $badgeAdmin.Text      = " ADMINISTRADOR "
    $badgeAdmin.ForeColor = $cBg
    $badgeAdmin.BackColor = $cGreen
} else {
    $badgeAdmin.Text      = " SEM ADMIN "
    $badgeAdmin.ForeColor = $cBg
    $badgeAdmin.BackColor = $cYellow
}

# Contador de instalados (direita, linha 2)
$lblContador = New-Object System.Windows.Forms.Label
$lblContador.Text      = "verificando instalados…"
$lblContador.Font      = $fontAppB
$lblContador.ForeColor = $cGreen
$lblContador.AutoSize  = $true
$lblContador.Anchor    = "Top|Right"
$lblContador.Location  = New-Object System.Drawing.Point(860, 56)

# Telemetria (esquerda, linha 2)
$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Font      = $fontInfo
$lblInfo.ForeColor = $cMuted
$lblInfo.AutoSize  = $true
$lblInfo.Location  = New-Object System.Drawing.Point(18, 74)

# Separador inferior
$pnlHeaderSep = New-Object System.Windows.Forms.Panel
$pnlHeaderSep.Dock      = "Bottom"
$pnlHeaderSep.Height    = 2
$pnlHeaderSep.BackColor = $cBorder

$pnlHeader.Controls.Add($pnlHeaderSep)
$pnlHeader.Controls.Add($lblContador)
$pnlHeader.Controls.Add($badgeAdmin)
$pnlHeader.Controls.Add($lblInfo)
$pnlHeader.Controls.Add($lblSub)
$pnlHeader.Controls.Add($lblTitulo)

# ==============================================================================
# 9. BARRA DE ABAS (flat + indicador ativo em amarelo)
# ==============================================================================
$pnlAbas = New-Object System.Windows.Forms.Panel
$pnlAbas.Dock        = "Top"
$pnlAbas.Height      = 44
$pnlAbas.BackColor   = $cPanel
$pnlAbas.Padding     = [System.Windows.Forms.Padding]::new(8, 5, 8, 5)

$btnTabSoft = New-Object System.Windows.Forms.Button
$btnTabDev  = New-Object System.Windows.Forms.Button
$btnTabMant = New-Object System.Windows.Forms.Button

$i = 0
foreach ($b in @($btnTabSoft, $btnTabDev, $btnTabMant)) {
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = $cCard
    $b.FlatAppearance.MouseDownBackColor = $cCard
    $b.BackColor = $cPanel
    $b.ForeColor = $cMuted
    $b.Font      = $fontTab
    $b.Height    = 32
    $b.Width     = 250
    $b.Location  = New-Object System.Drawing.Point((10 + $i * 260), 5)
    $b.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $i++
}
$btnTabSoft.Text = "Apps"
$btnTabDev.Text  = "Desenvolvimento"
$btnTabMant.Text = "Manutenção & Perfis"

$pnlAbas.Controls.AddRange(@($btnTabSoft, $btnTabDev, $btnTabMant))

# ==============================================================================
# 10. CORPO: PAINÉIS POR ABA
# ==============================================================================
$pnlBody = New-Object System.Windows.Forms.Panel
$pnlBody.Dock      = "Fill"
$pnlBody.BackColor = $cBg

# ---- Aba 1: Softwares Essenciais ----
$pnlSoft = New-Object System.Windows.Forms.Panel
$pnlSoft.Dock       = "Fill"
$pnlSoft.BackColor  = $cBg
$pnlSoft.AutoScroll = $true

$sectionsSoft = @(
    @{
        Title = "Compactação"
        Apps  = @(
            @{ Id = "7zip.7zip";                     Nome = "7-Zip" },
            @{ Id = "RARLab.WinRAR";                  Nome = "WinRAR" }
        )
    },
    @{
        Title = "Navegadores"
        Apps  = @(
            @{ Id = "Brave.Brave";                   Nome = "Brave Browser" },
            @{ Id = "Google.Chrome";                 Nome = "Google Chrome" }
        )
    },
    @{
        Title = "Documentos"
        Apps  = @(
            @{ Id = "Adobe.Acrobat.Reader.64-bit";    Nome = "Adobe Acrobat Reader" },
            @{ Id = "TheDocumentFoundation.LibreOffice.LTS"; Nome = "LibreOffice LTS" }
        )
    },
    @{
        Title = "Imagem & Vídeo"
        Apps  = @(
            @{ Id = "GIMP.GIMP";                      Nome = "GIMP" },
            @{ Id = "ShareX.ShareX";                  Nome = "ShareX" },
            @{ Id = "VideoLAN.VLC";                   Nome = "VLC Media Player" }
        )
    },
    @{
        Title = "Runtimes Windows 11"
        Apps  = @(
            @{ Id = "Microsoft.DotNet.DesktopRuntime.8";  Nome = ".NET 8 Desktop Runtime" },
            @{ Id = "Microsoft.VCRedist.2015+.x64";    Nome = "Visual C++ x64" },
            @{ Id = "Microsoft.VCRedist.2015+.x86";    Nome = "Visual C++ x86" },
            @{ Id = "EclipseAdoptium.Temurin.17.JRE";  Nome = "Java Temurin 17 JRE" }
        )
    },
    @{
        Title = "Acesso Remoto & Utilitários"
        Apps  = @(
            @{ Id = "AnyDeskSoftwareGmbH.AnyDesk";    Nome = "AnyDesk" },
            @{ Id = "RustDesk.RustDesk";              Nome = "RustDesk" },
            @{ Id = "qBittorrent.qBittorrent";        Nome = "qBittorrent" },
            @{ Id = "Rufus.Rufus";                    Nome = "Rufus (boot)" }
        )
    }
)

$ySoft = 12
foreach ($sec in $sectionsSoft) {
    $card = Add-SectionCard -Parent $pnlSoft -Title $sec.Title -Apps $sec.Apps -Y $ySoft
    $ySoft += $card.Height + 12
}
$pnlSoft.AutoScrollMinSize = New-Object System.Drawing.Size(0, ($ySoft + 12))

# ---- Aba 2: Desenvolvimento ----
$pnlDev = New-Object System.Windows.Forms.Panel
$pnlDev.Dock       = "Fill"
$pnlDev.BackColor  = $cBg
$pnlDev.AutoScroll = $true

$sectionsDev = @(
    @{
        Title = "Editores & IDE"
        Apps  = @(
            @{ Id = "Microsoft.VisualStudioCode";     Nome = "Visual Studio Code" },
            @{ Id = "Notepad++.Notepad++";            Nome = "Notepad++" },
            @{ Id = "Microsoft.VisualStudio.2022.Community"; Nome = "Visual Studio 2022 Community" }
        )
    },
    @{
        Title = "Versionamento & Backend"
        Apps  = @(
            @{ Id = "Git.Git";                        Nome = "Git SCM" },
            @{ Id = "ApacheFriends.Xampp.8.2";        Nome = "XAMPP (PHP 8.2)" },
            @{ Id = "Google.AndroidStudio";           Nome = "Android Studio" }
        )
    },
    @{
        Title = "Java (Eclipse Temurin JDK)"
        Apps  = @(
            @{ Id = "EclipseAdoptium.Temurin.8.JDK";  Nome = "Temurin 8 JDK" },
            @{ Id = "EclipseAdoptium.Temurin.11.JDK"; Nome = "Temurin 11 JDK" },
            @{ Id = "EclipseAdoptium.Temurin.17.JDK"; Nome = "Temurin 17 JDK (LTS)" },
            @{ Id = "EclipseAdoptium.Temurin.21.JDK"; Nome = "Temurin 21 JDK (LTS)" }
        )
    }
)

$yDev = 12
foreach ($sec in $sectionsDev) {
    $card = Add-SectionCard -Parent $pnlDev -Title $sec.Title -Apps $sec.Apps -Y $yDev
    $yDev += $card.Height + 12
}
$pnlDev.AutoScrollMinSize = New-Object System.Drawing.Size(0, ($yDev + 12))

# ---- Aba 3: Manutenção & Perfis (itens informativos — execução na Fase 2) ----
$pnlMant = New-Object System.Windows.Forms.Panel
$pnlMant.Dock       = "Fill"
$pnlMant.BackColor  = $cBg
$pnlMant.AutoScroll = $true

$yMant = 12
$cardM1 = Add-InfoCard -Parent $pnlMant -Title "Tarefas de Manutenção" -Y $yMant -Items @(
    "Reparo Completo (DISM + SFC)",
    "Diagnóstico Volume C: (Scan)",
    "Reset Pilha de Rede (DHCP)",
    "Forçar Atualização GPO",
    "Habilitar Admin (SID 500)",
    "Mapear Credencial de Rede",
    "Renomear Computador",
    "Habilitar Servidor OpenSSH (22)",
    "Tweaks Win 11 (Menu Clássico, Dark, Sem Widgets/Copilot)"
)
$yMant += $cardM1.Height + 12

$cardM2 = Add-InfoCard -Parent $pnlMant -Title "Perfis Automatizados" -Y $yMant -Items @(
    "P1 · Modo PMA — Prefeitura Win 11 (Apps + Runtimes + Admin + Tweaks)",
    "P2 · Modo BRNCZZR — Dev Workstation (Apps Dev + Runtimes + Tweaks)"
)
$yMant += $cardM2.Height + 12

$lblMantObs = New-Object System.Windows.Forms.Label
$lblMantObs.Text      = "ℹ  Essas tarefas de manutenção rodam pelo TUI legado (win-toolbox.ps1). A execução gráfica chega na Fase 2."
$lblMantObs.Font      = $fontInfo
$lblMantObs.ForeColor = $cDark
$lblMantObs.AutoSize  = $true
$lblMantObs.Location  = New-Object System.Drawing.Point(20, ($yMant + 6))
$pnlMant.Controls.Add($lblMantObs)
$pnlMant.AutoScrollMinSize = New-Object System.Drawing.Size(0, ($yMant + 40))

# Navegação entre abas
function Set-Aba {
    param([string]$tela, [System.Windows.Forms.Panel]$pnlAtivo)
    $lblTitulo.Text = "WIN-TOOLBOX-TUI · $tela"
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

$btnTabSoft.Add_Click({ Set-Aba "SOFTWARES" $pnlSoft })
$btnTabDev.Add_Click({  Set-Aba "DESENVOLVIMENTO" $pnlDev })
$btnTabMant.Add_Click({ Set-Aba "MANUTENÇÃO & PERFIS" $pnlMant })

$pnlBody.Controls.Add($pnlMant)
$pnlBody.Controls.Add($pnlDev)
$pnlBody.Controls.Add($pnlSoft)

# ==============================================================================
# 11. RODAPÉ (status + botão + barra de progresso Cyan)
# ==============================================================================
$pnlFooter = New-Object System.Windows.Forms.Panel
$pnlFooter.Dock      = "Bottom"
$pnlFooter.Height    = 74
$pnlFooter.BackColor = $cBg
$pnlFooter.Padding   = [System.Windows.Forms.Padding]::new(8, 10, 8, 6)

$pnlTrack = New-Object System.Windows.Forms.Panel
$pnlTrack.Dock      = "Bottom"
$pnlTrack.Height    = 12
$pnlTrack.BackColor = $cTrack

$pnlFill = New-Object System.Windows.Forms.Panel
$pnlFill.BackColor  = $cCyan
$pnlFill.Size       = New-Object System.Drawing.Size(0, 12)
$pnlFill.Location   = New-Object System.Drawing.Point(0, 0)
$pnlTrack.Controls.Add($pnlFill)

$pnlCmds = New-Object System.Windows.Forms.Panel
$pnlCmds.Dock      = "Fill"
$pnlCmds.BackColor = $cBg

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text      = "Instalar Selecionados"
$btnInstalar.Font      = $fontAppB
$btnInstalar.BackColor = $cGreen
$btnInstalar.ForeColor = $cBg
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderSize = 0
$btnInstalar.FlatAppearance.MouseOverBackColor = (Hex "#4AC95E")
$btnInstalar.FlatAppearance.MouseDownBackColor = $cGreen
$btnInstalar.Size      = New-Object System.Drawing.Size(240, 40)
$btnInstalar.Dock      = "Right"
$btnInstalar.Cursor    = [System.Windows.Forms.Cursors]::Hand

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Pronto"
$lblStatus.Font      = $fontInfo
$lblStatus.ForeColor = $cMuted
$lblStatus.AutoSize  = $false
$lblStatus.TextAlign = [System.Windows.Forms.ContentAlignment]::MiddleLeft
$lblStatus.Dock      = "Fill"

$pnlCmds.Controls.Add($lblStatus)
$pnlCmds.Controls.Add($btnInstalar)

$pnlFooter.Controls.Add($pnlTrack)
$pnlFooter.Controls.Add($pnlCmds)

# ==============================================================================
# 12. LOG (RichTextBox colorido por linha — estilo terminal)
# ==============================================================================
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock      = "Bottom"
$pnlLog.Height    = 150
$pnlLog.BackColor = $cBg
$pnlLog.Padding   = [System.Windows.Forms.Padding]::new(6, 2, 6, 2)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock        = "Fill"
$txtLog.ReadOnly    = $true
$txtLog.BackColor   = $cLogBg
$txtLog.ForeColor   = Hex "#C9D1D9"
$txtLog.Font        = $fontLog
$txtLog.BorderStyle = "None"
$txtLog.ScrollBars  = "Vertical"
$txtLog.DetectUrls  = $false
$pnlLog.Controls.Add($txtLog)

# ==============================================================================
# 13. MONTAGEM DA JANELA (ordem de Dock importa)
# ==============================================================================
$form.Controls.Add($pnlBody)
$form.Controls.Add($pnlLog)
$form.Controls.Add($pnlFooter)
$form.Controls.Add($pnlAbas)
$form.Controls.Add($pnlHeader)

# ==============================================================================
# 14. ESTADO COMPARTILHADO
# ==============================================================================
$sync = @{
    Log             = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    Progresso       = 0
    Total           = 0
    Ocupado         = $false
    Instalados      = @{}
    InstaladosPronto = $false
    Sucesso         = @()
}

# Estado de UI: mapa global de app instalado (robusto a wrappers PS) + flags
$script:instaladosMap   = @{}
$script:StatusAplicado  = $false
$script:LoteAplicado    = $false

$tip = New-Object System.Windows.Forms.ToolTip
$tip.AutoPopDelay         = 6000
$tip.InitialDelay         = 400
$tip.ReshowDelay          = 200
$tip.ShowAlways           = $true

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

function Update-InstaladosUI {
    # Aplica o estado "instalado" nos checkboxes (uma única vez por atualização)
    $tot = 0; $cnt = 0
    foreach ($pnl in @($pnlSoft, $pnlDev)) {
        foreach ($cb in Get-AllCheckBoxes $pnl) {
            if (-not $cb.Tag) { continue }
            $tot++
            if ($sync.Instalados.ContainsKey($cb.Tag) -or $script:instaladosMap.ContainsKey($cb.Tag)) {
                $script:instaladosMap[$cb.Tag] = $true
                $cb.Checked   = $true
                $cb.Enabled   = $false
                $cb.Cursor    = [System.Windows.Forms.Cursors]::Default
                $tip.SetToolTip($cb, "Já instalado neste computador.")
                $cb.Invalidate()
                $cnt++
            }
        }
    }
    $lblContador.Text = "[✓] Instalados: $cnt de $tot"
    Add-Log "[i] Verificação concluída: $cnt de $tot já instalados (verdes/desabilitados)."
}

# ==============================================================================
# 15. TELEMETRIA DO CABEÇALHO
# ==============================================================================
$data = (Get-Date).ToString("dd/MM/yyyy")
$ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
    $_.IPAddress -ne "127.0.0.1" -and
    $_.IPAddress -notlike "169.254*" -and
    $_.InterfaceAlias -notlike "*Loopback*" -and
    $_.InterfaceAlias -notlike "*vEthernet*"
} | Select-Object -ExpandProperty IPAddress -First 1)
if ([string]::IsNullOrWhiteSpace($ip)) { $ip = "N/A" }
$lblInfo.Text = " Data: $data  |  Computador: $env:computername  |  Usuário: $env:username  |  IP: $ip"

Add-Log "win-toolbox-tui GUI (v0.4.0 — Windows Forms) iniciada."
if ($isAdmin) {
    Add-Log "[✓] Executando como Administrador."
} else {
    Add-Log "[!] Você NÃO está como Administrador — o winget pode falhar nas instalações."
}

# ==============================================================================
# 16. DETECÇÃO DE APPS INSTALADOS (background — não trava a UI)
# ==============================================================================
$runspaceDet = [runspacefactory]::CreateRunspace()
$runspaceDet.Open()
$psDet = [powershell]::Create()
$psDet.Runspace = $runspaceDet
[void]$psDet.AddScript({
    param($sync)

    $inst = $sync.Instalados
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "wintb-instalados.json"
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        $sync.InstaladosPronto = $true
        return
    }

    # Caminho principal: winget export gera JSON estruturado (parse confiável)
    try {
        & $winget export -o $tmp --accept-source-agreements --disable-interactivity 2>$null | Out-Null
        if (Test-Path $tmp) {
            $j = Get-Content $tmp -Raw | ConvertFrom-Json
            foreach ($s in $j.Sources) {
                foreach ($p in $s.Packages) {
                    $inst[$p.PackageIdentifier] = $true
                }
            }
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            $sync.InstaladosPronto = $true
            return
        }
    } catch {
        # FileNotFound/não suportado → segue para o fallback
    }

    # Fallback: parse do winget list (coluna 2 = ID)
    try {
        $linhas = @(& $winget list --accept-source-agreements --disable-interactivity 2>$null)
        foreach ($l in $linhas) {
            $parts = (@($l.Trim()) -split "\s{2,}")
            if ($parts.Count -ge 2 -and $parts[0] -ne "Nome" -and $parts[0] -notmatch "^-" -and $parts[1] -match "\.") {
                $inst[$parts[1]] = $true
            }
        }
    } catch {
        # Sem winget operacional: nada é marcado como instalado
    }

    $sync.InstaladosPronto = $true
}).AddArgument($sync)
[void]$psDet.BeginInvoke()

# ==============================================================================
# 17. AÇÃO: INSTALAR SELECIONADOS (background via runspace — UI não congela)
# ==============================================================================
$btnInstalar.Add_Click({
    if ($sync.Ocupado) {
        Add-Log "[!] Já existe uma instalação em andamento. Aguarde."
        return
    }

    $apps = @()
    foreach ($pnl in @($pnlSoft, $pnlDev)) {
        foreach ($cb in Get-AllCheckBoxes $pnl) {
            if ($cb.Enabled -and $cb.Checked -and $cb.Tag) {
                $apps += [pscustomobject]@{ Id = $cb.Tag; Nome = $cb.Text }
            }
        }
    }

    if ($apps.Count -eq 0) {
        Add-Log "[!] Nenhuma opção disponível selecionada. Os instalados já vêm marcados — desabilite-os para reinstalar."
        return
    }

    $sync.Total = $apps.Count
    $sync.Progresso = 0
    $sync.Sucesso = @()
    $script:LoteAplicado = $false
    $sync.Ocupado = $true
    $btnInstalar.Text = "Instalando…"
    $btnInstalar.Enabled = $false
    Add-Log "[*] Iniciando instalação de $($apps.Count) aplicativo(s)..."

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($apps, $sync)

        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            $sync.Log.Enqueue(("[{0}] [ERRO] winget não encontrado (App Installer ausente)." -f (Get-Date -Format "HH:mm:ss")))
            $sync.Ocupado = $false
            return
        }

        foreach ($a in $apps) {
            $sync.Log.Enqueue(("[{0}] [*] Instalando: {1} ({2})..." -f (Get-Date -Format "HH:mm:ss"), $a.Nome, $a.Id))
            $sync.Log.Enqueue(("[{0}] [>] winget install --id {1} --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity" -f (Get-Date -Format "HH:mm:ss"), $a.Id))
            & winget install --id $a.Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
            $status = if ($LASTEXITCODE -eq 0) { "[OK]" } else { "[FALHA]" }
            if ($LASTEXITCODE -eq 0) { $sync.Sucesso = $sync.Sucesso + @($a.Id) }
            $sync.Log.Enqueue(("[{0}] {1} {2} — exit {3}" -f (Get-Date -Format "HH:mm:ss"), $status, $a.Nome, $LASTEXITCODE))
            $sync.Progresso++
        }

        $sync.Log.Enqueue(("[{0}] [✓] Lote concluído!" -f (Get-Date -Format "HH:mm:ss")))
        $sync.Ocupado = $false
    }).AddArgument($apps).AddArgument($sync)

    [void]$ps.BeginInvoke()
})

# ==============================================================================
# 18. TIMER: ATUALIZA UI (progresso + log + detecção) SEM CONGELAR
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

    if ($txtLog.Lines.Count -gt 400) {
        $remover = $txtLog.Lines.Count - 400
        $txtLog.Select(0, $txtLog.GetFirstCharIndexFromLine($remover))
        $txtLog.SelectedText = ""
    }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 250
$timer.Add_Tick({
    # 1) Detecção de instalados (aplica quando o runspace termina)
    if ($sync.InstaladosPronto -and -not $script:StatusAplicado) {
        $script:StatusAplicado = $true
        Update-InstaladosUI
    }

    # 2) Após lote concluído: marca os recém-instalados
    if (-not $sync.Ocupado -and $sync.Sucesso.Count -gt 0 -and -not $script:LoteAplicado) {
        $script:LoteAplicado = $true
        foreach ($pnl in @($pnlSoft, $pnlDev)) {
            foreach ($cb in Get-AllCheckBoxes $pnl) {
                if ($cb.Tag -and ($sync.Sucesso -contains $cb.Tag)) {
                    $script:instaladosMap[$cb.Tag] = $true
                    $cb.Checked   = $true
                    $cb.Enabled   = $false
                    $cb.Cursor    = [System.Windows.Forms.Cursors]::Default
                    $tip.SetToolTip($cb, "Já instalado neste computador.")
                    $cb.Invalidate()
                }
            }
        }
        Update-InstaladosUI
        Add-Log "[✓] $($sync.Sucesso.Count) aplicativo(s) marcados como instalados."
    }

    # 3) Status + botão
    if ($sync.Ocupado) {
        $lblStatus.Text = "Instalando… $($sync.Progresso) / $($sync.Total)"
    } else {
        $lblStatus.Text = "Pronto"
        if ($btnInstalar.Text -ne "Instalar Selecionados") {
            $btnInstalar.Text = "Instalar Selecionados"
            $btnInstalar.Enabled = $true
        }
    }

    # 4) Barra de progresso custom (Cyan)
    $frac = $sync.Progresso / [Math]::Max(1, $sync.Total)
    $pnlFill.Width = [int]($pnlTrack.Width * $frac)

    Update-LogViewer
})
$timer.Start()

# ==============================================================================
# 19. MOSTRAR JANELA
# ==============================================================================
[void]$form.ShowDialog()
Write-Host "[✓] GUI encerrada. Até logo!" -ForegroundColor Green