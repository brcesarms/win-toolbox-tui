# 🪟 win-toolbox-tui — Caixa de Ferramentas & Pós-Instalação para Windows 11

> **Exclusivo para Windows 11 (Build 22000+)**  
> Interface interativa de terminal (TUI) com **múltiplos menus organizados** em PowerShell para diagnóstico, manutenção, instalação em lote via Winget, tweaks essenciais de sistema e perfis automatizados de estações de trabalho.

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

---

## 🎯 Estrutura Modular dos Menus

A interface foi redesenhada em **3 telas dedicadas e limpas**, evitando poluição visual:

### 1️⃣ Menu Principal — Softwares Essenciais & Runtimes
Contém as ferramentas do dia a dia e instaladores base:
* **`0`**: Atualizar todos os pacotes via Winget
* **Compactação (`1A–1B`)**: 7-Zip, WinRAR
* **Documentos (`2A–2C`)**: Adobe Acrobat Reader, Foxit Reader, LibreOffice LTS
* **Imagem (`3A–3C`)**: GIMP, Lightshot, ShareX
* **Mídia (`4A–4C`)**: HandBrake, K-Lite Codec Pack Full, VLC Media Player
* **Runtimes Win 11 (`5A–5F`)**: .NET 8 Desktop (LTS), .NET 9 Desktop, VC++ 2015-2022 (x64/x86), VC++ All-in-One, Java Temurin 17 JRE
* **Utilitários (`6A–6F`)**: AnyDesk, qBittorrent, Rufus, RustDesk, Transmission, RealVNC Viewer
* **Atalhos de Navegação**:
  * Digite **`D`** ➔ Abre o Menu Desenvolvimento
  * Digite **`M`** ➔ Abre o Menu Manutenção & Perfis
  * Digite **`Q`** ➔ Encerra a ferramenta

### 2️⃣ Menu Desenvolvimento (`D`)
Focado estritamente em ferramentas para programadores e técnicos avançados:
* **`D0`**: Instalar Pacote Dev Completo (VS Code + Git + Notepad++ + JDK 17)
* **IDEs & Editores (`D1–D4`)**: VS Code, Notepad++, Visual Studio 2022 Community, Android Studio
* **Versionamento & Servidor (`D5–D6`)**: Git SCM, XAMPP (PHP 8.2 & MySQL)
* **Java Development Kits (`D7–D10`)**: Eclipse Temurin JDK 8, 11, 17 (LTS), 21 (LTS)
* **Navegação**: Digite **`V`** para voltar ao Menu Principal ou **`Q`** para sair.

### 3️⃣ Menu Manutenção, Tweaks & Perfis Auto (`M`)
Focado em reparo do Windows 11, configuração corporativa e automações em lote:
* **Diagnóstico & Reparo (`M1–M4`)**:
  * `M1`: Reparo Completo (DISM RestoreHealth primeiro + SFC Scannow)
  * `M2`: Diagnóstico Online do Volume C: (Repair-Volume sem reiniciar)
  * `M3`: Reset de Pilha de Rede (Flush DNS, DHCP Release/Renew, reinício dinâmico de adaptadores)
  * `M4`: Atualização de Diretivas (gpupdate /force)
* **Configurações & Rede (`M5–M7`)**:
  * `M5`: Ativação Universal de Administrador Local (Detecção por SID `*-500`)
  * `M6`: Mapeamento seguro de credenciais de rede no Windows Vault
  * `M7`: Renomear computador com opção de reboot imediato ou posterior
* **Tweaks Essenciais Windows 11 (`M8`)**:
  * Restauração do menu de contexto clássico (sem "Mostrar mais opções")
  * Alinhamento da barra de tarefas à esquerda
  * Exibição de extensões de arquivos e pastas ocultas
  * Desativação de hibernação (`powercfg -h off` liberando 8GB–32GB no SSD/NVMe)
  * Ativação nativa do Tema Escuro
  * Ocultação de Widgets e botão Copilot
* **Perfis Automatizados (`P1–P2`)**:
  * `P1`: 🏛️ **MODO PMA** (Padrão corporativo da Prefeitura: Apps essenciais + Runtimes + Admin + Tweaks Win 11)
  * `P2`: 🚀 **MODO BRNCZZR** (Padrão Dev Workstation completa)
* **Navegação**: Digite **`V`** para voltar ao Menu Principal ou **`Q`** para sair.

---

## 🧩 Seleção Múltipla Inteligente

Em qualquer um dos menus, você pode digitar vários comandos separados por vírgula para execução sequencial silenciosa:
- No Menu Principal: `0, 1A, 2C, 5E, 6D`
- No Menu Dev: `D1, D5, D9`
- No Menu Manutenção: `M1, M8`

---

## 🔒 Segurança

- Nenhuma credencial ou senha corporativa é gravada em texto puro.
- Todos os pacotes são validados pela infraestrutura oficial do Microsoft Winget.

---

## 👤 Autor

Desenvolvido por **Bruno César Medeiros Siqueira**  
*Analista de T.I. Pleno — Ariquemes/RO*  
GitHub: [@brcesarms](https://github.com/brcesarms)

## 📄 Licença

Este projeto é distribuído sob a licença [MIT](LICENSE).
