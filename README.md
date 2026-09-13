# 🪟 win-toolbox-tui — Caixa de Ferramentas & Pós-Instalação para Windows 11

> **Exclusivo para Windows 11 (Build 22000+)**  
> Interface interativa de terminal (TUI) em PowerShell para diagnóstico, manutenção, instalação em lote via Winget, tweaks essenciais de sistema e perfis automatizados de estações de trabalho.

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

## 🎯 Destaques e Recursos do Windows 11

- 🛡️ **100% Focado no Windows 11:** Verificação de Build nativa (impede execução em sistemas legados).
- 🧩 **Seleção Múltipla Inteligente:** Digite múltiplos comandos separados por vírgula no menu (ex: `1A, 2F, 6A, 15`).
- 📦 **Instalações Silenciosas via Winget:** Sem janelas ou popups roubando o foco do técnico durante a instalação.
- 🩺 **Reparo de Sistema com Ordem Oficial:** DISM RestoreHealth executado antes do SFC Scannow para garantir consistência.
- 👤 **Ativação Universal de Administrador:** Detecção pelo SID `*-500` (funciona em Windows PT-BR, EN-US ou qualquer idioma).
- 🚀 **Tweaks de Performance e Produtividade:**
  - Restauração do menu de contexto clássico (sem "Mostrar mais opções").
  - Barra de tarefas alinhada à esquerda.
  - Exibição de extensões de arquivos e pastas ocultas.
  - Desativação de hibernação (`powercfg -h off` liberando 8GB–32GB de SSD).
  - Tema escuro ativado por padrão.
  - Ocultação de Widgets e botão Copilot.

---

## 📋 Tabela de Opções do Menu TUI

| Código | Categoria | Descrição / Softwares |
| :---: | :--- | :--- |
| **`0`** | 🔄 **Update All** | Atualiza todos os pacotes do sistema via Winget |
| **`1A–1B`** | 🗜️ **Compactação** | 7-Zip, WinRAR |
| **`2A–2I`** | 💻 **Dev & IDEs** | VS Code, Git, Notepad++, Android Studio, Visual Studio, Java JDK (8, 11, 17, 21) |
| **`3A–3C`** | 📄 **Documentos** | Adobe Acrobat Reader, Foxit Reader, LibreOffice LTS |
| **`4A–4C`** | 🎨 **Imagem** | GIMP, Lightshot, ShareX |
| **`5A–5C`** | 🎬 **Mídia** | VLC Media Player, HandBrake, K-Lite Codec Pack Full |
| **`6A–6F`** | ⚙️ **Runtimes Win 11**| .NET 8 Desktop (LTS), .NET 9 Desktop, VC++ 2015-2022 (x64/x86), VC++ AIO, Java 17 JRE |
| **`7A–7F`** | 🛠️ **Utilitários Remotos**| RustDesk, AnyDesk, Rufus, qBittorrent, Transmission, RealVNC Viewer |
| **`8`** | 🔒 **Credencial de Rede** | Mapeia credenciais no Windows Credential Manager de forma segura |
| **`9`** | 👑 **Admin Local** | Habilita a conta de Administrador nativa pelo SID 500 |
| **`10`** | 🏷️ **Renomear PC** | Altera hostname da estação e agenda reinicialização |
| **`11`** | 💾 **Diagnóstico C:** | Scan online do volume C: sem travar ou forçar reboot imediato |
| **`12`** | 🩺 **Reparo do Sistema** | DISM `/Online /Cleanup-Image /RestoreHealth` + `sfc /scannow` |
| **`13`** | 📜 **Atualizar GPO** | Executa `gpupdate /force` |
| **`14`** | 🌐 **Reset de Rede** | Limpeza de cache DNS, liberação/renovação de IP e reinicialização de placas de rede |
| **`15`** | ⚡ **Tweaks Win 11** | Menu clássico, barra à esquerda, extensões visíveis, tema escuro e SSD boost |
| **`16`** | 🏛️ **MODO PMA** | Perfil automatizado padrão corporativo para Prefeitura Municipal de Ariquemes |
| **`17`** | 🚀 **MODO BRNCZZR** | Perfil automatizado completo para estação de desenvolvedor |

---

## 🔒 Segurança

- Nenhuma credencial ou senha corporativa é gravada em texto puro. A opção `8` solicita a senha em tempo de execução via `SecureString`.
- Todos os pacotes são baixados diretamente dos repositórios oficiais e verificados pela infraestrutura do Microsoft Winget.

---

## 👤 Autor

Desenvolvido por **Bruno César Medeiros Siqueira**  
*Analista de T.I. Pleno — Ariquemes/RO*  
GitHub: [@brcesarms](https://github.com/brcesarms)

## 📄 Licença

Este projeto é distribuído sob a licença [MIT](LICENSE).
