# 🪟 win-toolbox-tui — Caixa de Ferramentas & Pós-Instalação para Windows 11

> **Exclusivo para Windows 11 (Build 22000+)**  
> Interface gráfica desktop (GUI/WPF) estilo **Chris Titus WinUtil** com checkboxes, abas e barra de progresso, instalando softwares e aplicando manutenção sem digitar comandos. Inclui ainda a **interface legada de terminal (TUI)** com indicadores de status em tempo real (`[✔]` Verde / `[ ]` Branco) e perfis automatizados (`P1`/`P2`).

---

## ⚡ Execução Rápida (One-Liner)

Abra o **PowerShell como Administrador** no Windows 11 e execute:

```powershell
irm https://raw.githubusercontent.com/brcesarms/win-toolbox-tui/main/win-toolbox-gui.ps1 | iex
```

Ou execute localmente clonando o repositório:

```powershell
git clone https://github.com/brcesarms/win-toolbox-tui.git
cd win-toolbox-tui
powershell -ExecutionPolicy Bypass -File .\win-toolbox-gui.ps1
```

> 🖥️ **Para a interface legada de terminal (TUI):** `win-toolbox.ps1`
> ```powershell
> irm https://raw.githubusercontent.com/brcesarms/win-toolbox-tui/main/win-toolbox.ps1 | iex
> ```

---

## 💎 Destaques da GUI (padrão)

* ☑️ **Checkboxes múltiplos:** marque os apps desejados (7-Zip, WinRAR, VLC...) e clique em **Instalar Selecionados**.
* 📑 **Abas organizadas:** Softwares Essenciais · Desenvolvimento · Manutenção & Perfis.
* 📊 **Barra de progresso + log em tempo real:** instalação via winget em background sem congelar a janela.
* 🌙 **Tema dark estilo WinUtil:** interface moderna e de alto contraste.
* ⚡ **100% one-liner** — sem instalar nada, só PowerShell.

---

## 🖥️ Destaques Visuais & Experiência TUI (legado)

* 🟢 **Status Dinâmico em Tempo Real:** Cada aplicativo e tarefa exibe `[✔]` em Verde se já estiver instalado/concluído no Windows 11, ou `[ ]` em Branco se pendente.
* 🟡 **Títulos em Negrito e Alto Contraste:** Seções e categorias formatadas em negrito ANSI de alto contraste, facilitando a leitura imediata sem poluição visual.
* 📐 **Alinhamento Perfeito de 90 Colunas:** Grid milimetricamente calibrado com bordas Unicode arredondadas (`╭─`, `│`, `╰─`).
* 🔡 **Tipografia Personalizável:** Compatível 100% com fontes modernas do Windows Terminal (como JetBrains Mono, Nerd Fonts e Cascadia Code).
* 📊 **Barra de Progresso Dinâmica:** Feedback visual em tempo real para instalações em lote (`0, 1A, 2C...`) e perfis automatizados.

---

## 🎯 Estrutura Modular dos Menus

A interface é dividida em **3 telas dedicadas e organizadas**:

### 1️⃣ Menu Principal — Softwares Essenciais & Runtimes
* **`0`**: Atualizar todos os pacotes instalados via Winget
* **COMPACTAÇÃO (`1A–1B`)**: `1A` 7-Zip · `1B` WinRAR
* **DOCUMENTOS (`2A–2C`)**: `2A` Adobe Acrobat Reader · `2B` Foxit PDF Reader · `2C` LibreOffice LTS
* **IMAGEM & VÍDEO (`3A–4C`)**: `3A` GIMP · `3B` Lightshot · `3C` ShareX · `4A` HandBrake · `4B` K-Lite Codec Full · `4C` VLC Media Player
* **RUNTIMES WIN 11 (`5A–5F`)**: `5A` .NET 8 Desktop LTS · `5B` .NET 9 Desktop · `5C` VC++ 2015-2022 x64 · `5D` VC++ 2015-2022 x86 · `5E` VC++ All-in-One · `5F` Java Temurin 17 JRE
* **ACESSO REMOTO & UTILITÁRIOS (`6A–6F`)**: `6A` AnyDesk · `6B` qBittorrent · `6C` Rufus (Boot) · `6D` RustDesk · `6E` Transmission · `6F` RealVNC Viewer
* **Navegação**: `D` Menu Dev · `M` Menu Manutenção & Perfis · `Q` Sair

### 2️⃣ Menu Desenvolvimento (`D`)
* **`D0`**: 🚀 **Pacote Dev Completo** (VS Code + Git + Notepad++ + JDK 17)
* **IDEs & EDITORES (`D1–D4`)**: `D1` VS Code · `D2` Notepad++ · `D3` VS 2022 Community · `D4` Android Studio
* **VERSIONAMENTO & CONTROLE (`D5`)**: `D5` Git SCM
* **SERVIDORES & AMBIENTES (`D6`)**: `D6` XAMPP (PHP 8.2 & MySQL)
* **JAVA DEVELOPMENT KIT (`D7–D10`)**: `D7` JDK 8 · `D8` JDK 11 · `D9` JDK 17 (LTS) · `D10` JDK 21 (LTS)
* **Navegação**: `V` Menu Principal · `M` Menu Manutenção & Perfis · `Q` Sair

### 3️⃣ Menu Manutenção, Tweaks & Perfis Auto (`M`)
* **DIAGNÓSTICO & REPARO (`M1–M4`)**:
  * `M1`: Reparo Completo (DISM RestoreHealth primeiro + SFC Scannow)
  * `M2`: Diagnóstico Online Volume C: (Repair-Volume sem reiniciar)
  * `M3`: Reset Pilha de Rede (Flush DNS, DHCP Release/Renew, reinício dinâmico de adaptadores)
  * `M4`: Atualização de Diretivas GPO (`gpupdate /force`)
* **CONFIGURAÇÕES, REDE & ACESSO (`M5–M8`)**:
  * `M5`: Ativação de Administrador Local nativo (Detecção por SID `*-500`)
  * `M6`: Mapeamento seguro de credenciais de rede no Windows Credential Manager
  * `M7`: Renomear computador com opção de reiniciar
  * `M8`: 🚀 **Habilitar Servidor OpenSSH** (Porta 22 TCP, serviço sshd/ssh-agent automático, regra de firewall em todos os perfis e exibição de comando de conexão)
* **TWEAKS DE SISTEMA E PERFORMANCE DO WINDOWS 11 (`M9`)**:
  * Restauração do Menu de Contexto Clássico completo
  * Barra de tarefas alinhada à esquerda
  * Exibição de extensões de arquivos e itens ocultos
  * Desativação de hibernação (`powercfg -h off` liberando espaço no SSD)
  * Tema Escuro do sistema e aplicativos
  * Ocultação de Widgets e botão Copilot
* **PERFIS AUTOMATIZADOS (`P1–P2`)**:
  * `P1`: 🏛️ **MODO PMA** (Padrão corporativo Prefeitura: Apps + Runtimes + Admin + Tweaks Win 11)
  * `P2`: 🚀 **MODO BRNCZZR** (Padrão Dev Workstation + Produtividade + Runtimes + Tweaks)
* **Navegação**: `V` Menu Principal · `D` Menu Dev · `Q` Sair

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
