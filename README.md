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
* 💡 **Painel Lateral "Item Help" Dinâmico:** ao navegar com `↑` e `↓` pela lista de itens à esquerda, o painel à direita é atualizado instantaneamente com o nome, categoria, descrição do que o software faz, ID do pacote Winget e status de instalação.
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

A interface apresenta uma barra de menus superior sempre visível com **4 abas dedicadas** organizadas em **ordem alfabética**:

### 1️⃣ [ Apps ]
* **`0`**: 🚀 **Atualização Geral** — atualizar todos os pacotes instalados via Winget
* **SOFTWARES EM ORDEM ALFABÉTICA (`1–19`)**:
  * `1` 7-Zip · `2` Adobe Acrobat Reader · `3` AnyDesk · `4` **Brave Browser** · `5` Foxit PDF Reader
  * `6` GIMP · `7` **Google Chrome** · `8` HandBrake · `9` K-Lite Codec Pack Full · `10` LibreOffice LTS
  * `11` Lightshot · `12` qBittorrent · `13` RealVNC Viewer · `14` Rufus (Boot) · `15` RustDesk
  * `16` ShareX · `17` Transmission · `18` VLC Media Player · `19` WinRAR
* **Navegação**: `← / →` ou `Tab` alternam abas · `1` ou `A` para esta aba · `Q` Sair

### 2️⃣ [ Runtimes ]
* **`R0`**: ⚡ **Pacote Runtimes Completo** (.NET 8/9 + VC++ All-in-One + Java 17)
* **RUNTIMES EM ORDEM ALFABÉTICA (`R1–R6`)**:
  * `R1`: .NET 8 Desktop Runtime (LTS)
  * `R2`: .NET 9 Desktop Runtime
  * `R3`: Java Temurin 17 JRE
  * `R4`: Visual C++ 2015-2022 (x64)
  * `R5`: Visual C++ 2015-2022 (x86)
  * `R6`: Visual C++ All-in-One (abbodi1406)
* **Navegação**: `← / →` ou `Tab` alternam abas · `2` ou `R` para esta aba · `Q` Sair

### 3️⃣ [ Dev ]
* **`D0`**: 🚀 **Pacote Dev Completo** (VS Code + Git + Notepad++ + JDK 17)
* **FERRAMENTAS DEV EM ORDEM ALFABÉTICA (`D1–D10`)**:
  * `D1`: Android Studio
  * `D2`: Git SCM
  * `D3`: Java Temurin 8 JDK
  * `D4`: Java Temurin 11 JDK
  * `D5`: Java Temurin 17 JDK (LTS)
  * `D6`: Java Temurin 21 JDK (LTS)
  * `D7`: Notepad++
  * `D8`: Visual Studio 2022 Community
  * `D9`: Visual Studio Code
  * `D10`: XAMPP (PHP 8.2 & MySQL)
* **Navegação**: `← / →` ou `Tab` alternam abas · `3` ou `D` para esta aba · `Q` Sair

### 4️⃣ [ Configurações ]
* **FERRAMENTAS EM ORDEM ALFABÉTICA (`C1–C9`)**:
  * `C1`: Diagnóstico Volume C: (Repair-Volume sem reiniciar)
  * `C2`: Forçar Atualização de Diretivas GPO (`gpupdate /force`)
  * `C3`: Habilitar Admin Local nativo (Detecção por SID `*-500`)
  * `C4`: 🚀 **Habilitar Servidor OpenSSH** (Porta 22 TCP, serviço sshd/ssh-agent, firewall e chaves públicas autorizadas `authorized_keys`)
  * `C5`: Mapear Credencial de Rede no Windows Credential Manager
  * `C6`: Renomear Computador
  * `C7`: Reparo Completo do Sistema (DISM RestoreHealth primeiro + SFC Scannow)
  * `C8`: Reset Pilha de Rede (Flush DNS, DHCP Release/Renew, reinício dinâmico de adaptadores)
  * `C9`: Tweaks Win 11 (Menu Clássico, Dark, Barra Esquerda, Sem Widgets/Copilot)
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
