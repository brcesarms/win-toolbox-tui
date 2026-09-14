<#
.SYNOPSIS
    WIN-TOOLBOX-TUI [POC GUI] — Prova de Conceito da interface gráfica estilo Chris Titus WinUtil
.DESCRIPTION
    Janela WPF (Windows Presentation Foundation) com tema dark, abas e checkboxes.
    Fase 1 (POC): 1 aba funcional com instalação de pacotes via winget em background.
    Compatível com o one-liner: irm .../win-toolbox-gui.ps1 | iex
.AUTHOR
    Bruno César Medeiros Siqueira <bruno.cesar@outlook.it>
.VERSION
    0.1.0 — POC GUI WPF (Chris Titus WinUtil style)
#>

[CmdletBinding()]
param()

# ==============================================================================
# 0. VERIFICAÇÃO DE ELEVAÇÃO (informa no log; instalação exige admin)
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

# ==============================================================================
# 1. CARREGAMENTO WPF
# ==============================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ==============================================================================
# 2. DEFINIÇÃO DA INTERFACE (XAML) — Tema dark estilo WinUtil
# ==============================================================================
$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="win-toolbox-tui  ·  POC GUI  ·  Windows 11"
        Height="700" Width="1000"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E1E" FontFamily="Segoe UI">

    <Window.Resources>
        <SolidColorBrush x:Key="Bg" Color="#1E1E1E"/>
        <SolidColorBrush x:Key="Panel" Color="#252526"/>
        <SolidColorBrush x:Key="Card" Color="#2D2D30"/>
        <SolidColorBrush x:Key="Accent" Color="#2D7D9A"/>
        <SolidColorBrush x:Key="Green" Color="#2EA043"/>
        <SolidColorBrush x:Key="Text" Color="#E8E8E8"/>
        <SolidColorBrush x:Key="Muted" Color="#9D9D9D"/>
        <SolidColorBrush x:Key="Border" Color="#3F3F46"/>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="Margin" Value="0,8,20,8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="18,10"/>
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="150"/>
        </Grid.RowDefinitions>

        <!-- ================= CABEÇALHO ================= -->
        <StackPanel Grid.Row="0" Margin="2,0,2,12">
            <TextBlock FontSize="26" FontWeight="Bold" Foreground="{StaticResource Accent}" Text="win-toolbox-tui"/>
            <TextBlock FontSize="13" Foreground="{StaticResource Muted}"
                       Text="GUI · padrão Chris Titus WinUtil · Windows 11 · winget · Fase 1 (POC)"/>
        </StackPanel>

        <!-- ================= ABAS ================= -->
        <TabControl Grid.Row="1" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}">

            <TabItem Header="Softwares Essenciais">
                <ScrollViewer VerticalScrollBarVisibility="Auto"
                              Background="{StaticResource Card}">
                    <WrapPanel x:Name="PnlApps" Margin="18,12" Width="880">
                        <CheckBox Tag="7zip.7zip|7-Zip" Content="7-Zip"/>
                        <CheckBox Tag="RARLab.WinRAR|WinRAR" Content="WinRAR"/>
                        <CheckBox Tag="TheDocumentFoundation.LibreOffice.LTS|LibreOffice LTS" Content="LibreOffice LTS"/>
                        <CheckBox Tag="VideoLAN.VLC|VLC Media Player" Content="VLC Media Player"/>
                        <CheckBox Tag="GIMP.GIMP|GIMP" Content="GIMP"/>
                        <CheckBox Tag="ShareX.ShareX|ShareX" Content="ShareX"/>
                        <CheckBox Tag="Microsoft.DotNet.DesktopRuntime.8|.NET 8 Desktop" Content=".NET 8 Desktop Runtime"/>
                        <CheckBox Tag="Microsoft.VCRedist.2015+.x64|VC++ 2015-2022 x64" Content="Visual C++ 2015-2022 (x64)"/>
                        <CheckBox Tag="Microsoft.VCRedist.2015+.x86|VC++ 2015-2022 x86" Content="Visual C++ 2015-2022 (x86)"/>
                        <CheckBox Tag="EclipseAdoptium.Temurin.17.JRE|Temurin 17 JRE" Content="Java Temurin 17 JRE"/>
                        <CheckBox Tag="AnyDeskSoftwareGmbH.AnyDesk|AnyDesk" Content="AnyDesk"/>
                        <CheckBox Tag="RustDesk.RustDesk|RustDesk" Content="RustDesk"/>
                        <CheckBox Tag="qBittorrent.qBittorrent|qBittorrent" Content="qBittorrent"/>
                        <CheckBox Tag="Rufus.Rufus|Rufus" Content="Rufus (boot)"/>
                    </WrapPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Desenvolvimento">
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                    <TextBlock FontSize="16" Foreground="{StaticResource Muted}" Text="Fase 2 — em desenvolvimento"/>
                    <TextBlock FontSize="13" Foreground="{StaticResource Border}" Text="VS Code · Git · Notepad++ · JDKs · XAMPP"/>
                </StackPanel>
            </TabItem>

            <TabItem Header="Manutenção &amp; Perfis">
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                    <TextBlock FontSize="16" Foreground="{StaticResource Muted}" Text="Fase 2 — em desenvolvimento"/>
                    <TextBlock FontSize="13" Foreground="{StaticResource Border}" Text="DISM/SFC · Rede · OpenSSH · Tweaks · P1/P2"/>
                </StackPanel>
            </TabItem>
        </TabControl>

        <!-- ================= RODAPÉ: STATUS + BOTÃO + PROGRESSO ================= -->
        <StackPanel Grid.Row="2" Margin="2,12,2,8">
            <DockPanel>
                <Button x:Name="BtnInstalar" DockPanel.Dock="Right"
                        Content="Instalar Selecionados"
                        Background="{StaticResource Green}" Foreground="White"
                        FontWeight="Bold" FontSize="15" Padding="22,10" BorderThickness="0"
                        Cursor="Hand"/>
                <TextBlock x:Name="LblStatus" Text="Pronto" Foreground="{StaticResource Muted}"
                           FontSize="14" VerticalAlignment="Center"/>
            </DockPanel>
            <ProgressBar x:Name="BarProgresso" Height="10" Margin="0,12,0,0"
                         Foreground="{StaticResource Accent}" Background="#333333" BorderThickness="0"/>
        </StackPanel>

        <!-- ================= LOG ================= -->
        <Border Grid.Row="3" Background="#0E0E0E" BorderBrush="{StaticResource Border}"
                BorderThickness="1" CornerRadius="4" Margin="2,0,2,2">
            <TextBox x:Name="TxtLog" IsReadOnly="True" Background="Transparent"
                     Foreground="#C8D8C8" FontFamily="Cascadia Mono,Consolas"
                     FontSize="12" BorderThickness="0"
                     VerticalScrollBarVisibility="Auto" TextWrapping="NoWrap">
            </TextBox>
        </Border>
    </Grid>
</Window>
'@

# ==============================================================================
# 3. ESTADO COMPARTILHADO ENTRE UI E RUNSPACE DE INSTALAÇÃO
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

# ==============================================================================
# 4. CARREGAR XAML E OBTER CONTROLES
# ==============================================================================
try {
    $xml = [xml]$XAML
    $reader = New-Object System.Xml.XmlNodeReader $xml
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "[ERRO] Falha ao carregar o XAML: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[ERRO] $($_.ErrorDetails.Message)" -ForegroundColor Red
    Read-Host "Pressione ENTER para sair"
    Exit 1
}

$btnInstalar = $window.FindName('BtnInstalar')
$barProgresso = $window.FindName('BarProgresso')
$txtLog = $window.FindName('TxtLog')
$lblStatus = $window.FindName('LblStatus')

Add-Log "[i] win-toolbox-tui GUI (POC) iniciada."
if (-not $isAdmin) {
    Add-Log "[!] Você NÃO está como Administrador — o winget pode falhar nas instalações."
} else {
    Add-Log "[✓] Executando como Administrador."
}

# ==============================================================================
# 5. AÇÃO: INSTALAR SELECIONADOS (background via runspace — UI não congela)
# ==============================================================================
$btnInstalar.Add_Click({
    if ($sync.Ocupado) {
        Add-Log "[i] Já existe uma instalação em andamento. Aguarde."
        return
    }

    $apps = @()
    $pnl = $window.FindName('PnlApps')
    foreach ($child in $pnl.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true -and $child.Tag) {
            $p = ($child.Tag -split '\|')
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
    $barProgresso.Maximum = $sync.Total
    $barProgresso.Value = 0
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
            $sync.Log.Enqueue("[*] Instalando: $($a.Nome) ($($a.Id))...")
            & winget install --id $a.Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
            $sync.Log.Enqueue(("[{0}] {1} — exit {2}" -f $(if ($LASTEXITCODE -eq 0) { "OK" } else { "FALHA" }), $a.Nome, $LASTEXITCODE))
            $sync.Progresso++
        }

        $sync.Log.Enqueue("[✓] Lote concluído!")
        $sync.Ocupado = $false
    }).AddArgument($apps).AddArgument($sync)

    [void]$ps.BeginInvoke()
})

# ==============================================================================
# 6. TIMER: ATUALIZA UI (progresso + log) SEM CONGELAR
# ==============================================================================
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(250)
$timer.Add_Tick({
    if ($sync.Ocupado) {
        $lblStatus.Content = "Instalando… $($sync.Progresso) / $($sync.Total)"
    } else {
        $lblStatus.Content = "Pronto"
    }

    $barProgresso.Maximum = [Math]::Max(1, $sync.Total)
    $barProgresso.Value   = $sync.Progresso

    $linhas = $sync.Log.ToArray()
    if ($linhas.Count -gt 0) {
        $inicio = [Math]::Max(0, $linhas.Count - 150)
        $txtLog.Text = ($linhas[$inicio..($linhas.Count - 1)]) -join "`r`n"
        $txtLog.ScrollToEnd()
    }
})
$timer.Start()

# ==============================================================================
# 7. MOSTRAR JANELA
# ==============================================================================
$window.ShowDialog() | Out-Null

Write-Host "[✓] GUI encerrada. Até logo!" -ForegroundColor Green