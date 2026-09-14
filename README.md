# 🪟 win-toolbox-tui — Caixa de Ferramentas & Pós-Instalação para Windows 11

> **Exclusivo para Windows 11 (Build 22000+)**  
> Interface de terminal estilo **BIOS / Setup Utility**: bordas duplas, navegação por setas (↑↓), Espaço marca `[✓]`, Enter executa, Esc volta e Q sai — com detecção de apps já instalados (`[INSTALADO]` verde). Instala softwares e aplica manutenção sem digitar comandos. Inclui também a **interface gráfica desktop (GUI)** com checkboxes e barra de progresso, e perfis automatizados (`P1`/`P2`).

---

## ⚡ Execução Rápida (One-Liner)

Abra o **PowerShell como Administrador** no Windows 11 e execute:

```powershell
irm https://raw.githubusercontent.com/brcesarms/win-toolbox-tui/main/win-toolbox.ps1 | iex
```

Ou execute localmente clonando o repositório:

```powershell
git clone https://github.com/brcesarms/win-toolbox-tui.git
cd win-toolbox-tui
powershell -ExecutionPolicy Bypass -File .\win-toolbox.ps1
```

> 🖥️ **Para a interface gráfica desktop (GUI):** `win-toolbox-gui.ps1`
> ```powershell
> irm https://raw.githubusercontent.com/brcesarms/win-toolbox-tui/main/win-toolbox-gui.ps1 | iex
> ```

---

## 💎 Destaques do TUI estilo BIOS (padrão)

* 🖥️ **Interface estilo BIOS / Setup Utility (120x30):** bordas duplas `╔ ║ ╝`, ocupando perfeitamente a resolução padrão da janela (120 colunas x 30 linhas), abas superiores sempre visíveis e cursor de seleção em bloco verde — fiel ao firmware.
* ⌨️ **Navegação 100% nativa:** `← / →` ou `Tab` alternam entre as 4 abas · `↑ / ↓` movem · Espaço marca `[✓]` · Enter executa · Esc ou Q sai. Usa `[Console]::ReadKey` (zero dependências — nem gum, nem instalação).
* 🟢 **Detecção de instalados:** cada item aparece marcado com `[✓]` e `[INSTALADO]` em verde quando já presente na máquina; itens instalados não são remarcáveis.
* 📑 **Atalhos diretos entre abas:** `1` ou `A` (Apps) · `2` ou `R` (Runtimes) · `3` ou `D` (Dev) · `4` ou `C` (Configurações).
* ⚡ **100% one-liner** — `irm ... | iex` sem instalar nada.

## 🖥️ Destaques da GUI (alternativa)

* ☑️ **Checkboxes múltiplos:** marque os apps desejados (7-Zip, WinRAR, VLC...) e clique em **Instalar Selecionados**.
* 🟢 **Detecção de apps instalados:** checkboxes de apps já presentes aparecem verdes/desabilitados com tooltip "Já instalado".
* 📑 **Abas organizadas:** Apps · Desenvolvimento · Manutenção & Perfis.
* 🌙 **Tema dark:** cards, grid alinhado e checkboxes desenhados sob medida (OwnerDraw).

---

## 🎯 Estrutura Modular dos Menus (Abas estilo BIOS)

A interface apresenta uma barra de menus superior sempre visível com **4 abas dedicadas**:

### 1️⃣ [ Apps ]
* **`0`**: 🚀 **Atualização Geral** — atualizar todos os pacotes instalados via Winget
* **COMPACTAÇÃO (`1A–1B`)**: `1A` 7-Zip · `1B` WinRAR
* **DOCUMENTOS (`2A–2C`)**: `2A` Adobe Acrobat Reader · `2B` Foxit PDF Reader · `2C` LibreOffice LTS
* **IMAGEM & VÍDEO (`3A–4C`)**: `3A` GIMP · `3B` Lightshot · `3C` ShareX · `4A` HandBrake · `4B` K-Lite Codec Full · `4C` VLC Media Player
* **ACESSO REMOTO & UTILITÁRIOS (`5A–6C`)**: `5A` AnyDesk · `5B` RustDesk · `5C` RealVNC Viewer · `6A` qBittorrent · `6B` Transmission · `6C` Rufus (Boot)
* **Navegação**: `← / →` ou `Tab` alternam abas · `1` ou `A` para esta aba · `Q` Sair

### 2️⃣ [ Runtimes ]
* **`R0`**: ⚡ **Pacote Runtimes Completo** (.NET 8/9 + VC++ All-in-One + Java 17)
* **RUNTIMES (`R1–R6`)**:
  * `R1`: .NET 8 Desktop Runtime (LTS)
  * `R2`: .NET 9 Desktop Runtime
  * `R3`: Visual C++ 2015-2022 (x64)
  * `R4`: Visual C++ 2015-2022 (x86)
  * `R5`: Visual C++ All-in-One (abbodi1406)
  * `R6`: Java Temurin 17 JRE
* **Navegação**: `← / →` ou `Tab` alternam abas · `2` ou `R` para esta aba · `Q` Sair

### 3️⃣ [ Dev ]
* **`D0`**: 🚀 **Pacote Dev Completo** (VS Code + Git + Notepad++ + JDK 17)
* **IDEs & EDITORES (`D1–D4`)**: `D1` VS Code · `D2` Notepad++ · `D3` VS 2022 Community · `D4` Android Studio
* **VERSIONAMENTO & CONTROLE (`D5`)**: `D5` Git SCM
* **SERVIDORES & AMBIENTES (`D6`)**: `D6` XAMPP (PHP 8.2 & MySQL)
* **JAVA DEVELOPMENT KIT (`D7–D10`)**: `D7` JDK 8 · `D8` JDK 11 · `D9` JDK 17 (LTS) · `D10` JDK 21 (LTS)
* **Navegação**: `← / →` ou `Tab` alternam abas · `3` ou `D` para esta aba · `Q` Sair

### 4️⃣ [ Configurações ]
* **SISTEMA, ACESSO & REDE (`C1–C7`)**:
  * `C1`: Tweaks Win 11 (Menu Clássico, Dark, Barra Esquerda, Sem Widgets/Copilot)
  * `C2`: Habilitar Admin Local nativo (Detecção por SID `*-500`)
  * `C3`: 🚀 **Habilitar Servidor OpenSSH** (Porta 22 TCP, serviço sshd/ssh-agent automático e firewall)
  * `C4`: Renomear Computador
  * `C5`: Mapear Credencial de Rede no Windows Credential Manager
  * `C6`: Reset Pilha de Rede (Flush DNS, DHCP Release/Renew, reinício dinâmico de adaptadores)
  * `C7`: Forçar Atualização de Diretivas GPO (`gpupdate /force`)
* **DIAGNÓSTICO & REPARO (`C8–C9`)**:
  * `C8`: Diagnóstico Online Volume C: (Repair-Volume sem reiniciar)
  * `C9`: Reparo Completo do Sistema (DISM RestoreHealth primeiro + SFC Scannow)
* **PERFIS AUTOMATIZADOS (`P1–P2`)**:
  * `P1`: 🏛️ **MODO PMA** (Padrão corporativo Prefeitura: Apps + Runtimes + Admin + Tweaks Win 11)
  * `P2`: 🚀 **MODO BRNCZZR** (Padrão Dev Workstation + Produtividade + Runtimes + Tweaks)
* **Navegação**: `← / →` ou `Tab` alternam abas · `4` ou `C` para esta aba · `Q` Sair

---

## 🔒 Boas Práticas & Segurança

- Validação estrita de arquitetura e compatibilidade exclusiva com Windows 11.
- Nenhuma credencial trafega ou é registrada em log em texto plano.
- Ordem canônica Microsoft de diagnóstico (`DISM` antes de `SFC`).
- Cache de verificação de arquivos e serviços para renderização instantânea do menu sem congelamentos.

---

## 👤 Autor

Desenvolvido por **Bruno César Medeiros Siqueira**  
*Analista de T.I. Pleno — Ariquemes/RO*  
GitHub: [@brcesarms](https://github.com/brcesarms)

## 📄 Licença

Distribuído sob licença [MIT](LICENSE).
