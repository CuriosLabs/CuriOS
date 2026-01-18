# AI Tools on CuriOS

Curi*OS* provides a range of tools to help you work with Artificial Intelligence,
whether on your own computer or using online services. This guide covers both
easy-to-use desktop applications and more advanced tools for developers.

A quick note on terms: **LLMs** (Large Language Models) are the powerful AI
models behind services like ChatGPT.

---

## Easy-to-Use Desktop AI

These applications are graphical, work with a mouse and keyboard, and are the
best place to start.

### LM Studio

If your computer has a powerful graphics card (like a recent Nvidia or AMD model),
Curi*OS* automatically installs the necessary software to run AI models locally.

**LM Studio** is a desktop application that provides an interactive chat, an interface
to search and download different LLMs, and the ability to run them on your machine.

You can launch it from its desktop shortcut or by typing `lm-studio` in a terminal.

![LM Studio desktop application](https://github.com/CuriosLabs/CuriOS/blob/testing/img/ai_lm-studio.png?raw=true "LM Studio and nvtop.")

> [!TIP]
> You can monitor your graphics card's usage with the command `nvtop` or through
> the `curios-manager` application in the menu
> `System > Process Management (GPU)`.

> [!IMPORTANT]
> **Pro Tip**: In **LM Studio**, the default context length is set to 4096 and
> it is to low. The context length is the maximum of tokens the model can attempt
> in one prompt. The bigger, the better but the bigger is the context length the
> more VRAM your model will use on your GPU. A context length of at least 30000 is
> recommended. Open **LM Studio**, in the "Developer" or the "My Models" window load
> a model, in the right panel on the "Load" tab change the "Context length" value.
> Monitor your GPU memory usage with `nvtop` in a terminal. Try to reach around
> 85% usage of GPU memory.
> See [LM Studio documentation](https://lmstudio.ai/docs/app/advanced/per-model).

LM Studio can also power the AI features in other programs on your computer. It
does this by running an AI engine in the background that other apps can connect
to. Learn more on the [LM Studio documentation](https://lmstudio.ai/docs/app).

### Web Application Shortcuts

Curi*OS* comes with pre-installed desktop shortcuts for popular AI chat web applications:

- ChatGPT
- Claude
- Grok
- Mistral LeChat

---

## For Advanced Users & Developers

The following tools are primarily designed for developers or users comfortable
with the command line. They often run in the terminal in a **TUI** (Text-based
User Interface).

### Ollama

**Ollama** is a command-line tool to download and run LLMs locally. It also includes
**open-webui**, which provides a chat interface in your web browser.

To install it, open the `curios-manager` TUI, go to the `Settings (manual edit)`
menu, and set `services.ai.enable = true;`. After you save the file (`Ctrl+O`
then `Ctrl+X`), `curios-manager` will handle the installation.

- **Download a model** (e.g., gemma): `ollama pull gemma`
- **List installed models**: `ollama ls`

The web chat is available at [http://localhost:11434](http://localhost:11434) in
your browser. Find more models on the [Ollama website](https://ollama.com/).

### AI-Powered Code Editors

These applications are advanced code editors (**IDEs**) with built-in AI assistance.

- **Zed**: Installed by default. You can connect it to LM Studio. See the [Zed documentation](https://zed.dev/docs/ai/llm-providers).
- **Cursor**: An AI-first code editor. Launch the graphical app with `cursor` or
the terminal version with `cursor-agent`. See the [Cursor documentation](https://cursor.com/docs).
- **Windsurf**: Another AI-assisted editor. To install, set
`ai.windsurf.enable = true;` in your settings via `curios-manager`. Launch with
`windsurf`. See the [Windsurf documentation](https://docs.windsurf.com/windsurf/getting-started).

### Terminal (CLI) Tools

These tools require **Node.js** and its package manager, **npm**, which come
pre-installed on Curi*OS*. You can install them with the `npm install -g` command.

- **Claude Code**: Run with `claude`. Install with `npm install -g @anthropic-ai/claude-code`.
- **Gemini CLI**: Run with `gemini`. Install with `npm install -g @google/gemini-cli`.
- **opencode**: A terminal-based coding assistant. Install with
`nix profile add nixpkgs#opencode` and run with `opencode`. You can connect it
to your LM Studio server by editing its configuration file. For example, open
it with a basic text editor:

```bash
nano ~/.config/opencode/opencode.json
```

Then, add your provider and model details, for example:

```json
{
  "$schema": "https://opencode.ai/config.json",
  // Settings
  "permission": {
    "edit": "ask",
    "bash": "ask",
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "webfetch": "allow"
  },
  // Theme configuration
  "theme": "opencode",
  "autoupdate": false,
  // LLMs Providers - Adjust to your LM Studio configuration
  "provider": {
    "lmstudio": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio (local)",
      "options": {
        "baseURL": "http://127.0.0.1:1234/v1"
      },
      "models": {
        "qwen/qwen3-4b-2507": {
          "name": "Qwen3 4b 2507"
        },
        "mistralai/ministral-3-3b": {
          "name": "Ministral3"
        }
      }
    }
  }
}
```

Learn more on the [opencode documentation](https://opencode.ai/docs/).

---

**Previous**: [Backup your Computer](backups.md)

**Back**: [index](index.md)
