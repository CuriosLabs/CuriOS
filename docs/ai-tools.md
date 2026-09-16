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

### OpenCode Desktop App

OpenCode is an open source agent that helps you write and run code with any AI
model. It's available by default on Curi*OS* as a terminal-based interface (TUI)
and a desktop app. With OpenCode you can use any LLM provider by configuring
their API keys. On the desktop app, go to `File > Settings > Providers`. On the
TUI (`opencode`), launch the `/connect` command.

> [!TIP]
>
> Use the `@` key to fuzzy search for files in the project.
> Use the `/` key to list all commands and skills available.

See [OpenCode Zen](https://opencode.ai/docs/zen) for models available on the paid
plan or how to bring your own keys from Anthropic or OpenAI.
See below for how to configure `opencode.json` for local AI from LM Studio or Ollama.

![OpenCode desktop application](https://github.com/CuriosLabs/CuriOS/blob/release/26.05.8/img/OpenCode-desktop.png?raw=true "OpenCode desktop.")

### LM Studio Bionic

**LM Studio Bionic** is a desktop application that provides an interactive chat,
an interface to search and download different LLMs, and the ability to run them
on your machine.

If your computer has a powerful graphics card (like a recent Nvidia or AMD model),
**LM Studio Bionic** can run AI models locally. Download the latest local LLMs
directly within the app and use them for simple chats or advanced agentic tasks.
It is powered by the LM Studio runtime, with MLX and llama.cpp under the hood.

For your most demanding tasks, run Bionic with the latest frontier open models
such as GLM 5.2, Kimi K3, and DeepSeek V4 Pro from the **LM Studio** paid plan.

To install it, open the `curios-manager` TUI, go to the `Applications` menu, then
`Install/uninstall CuriOS Apps` menu. Search for
`(curios.desktop.ai.lmstudio) bionic` and enable it (Space bar to toggle).
Press Enter to submit it and `curios-manager` will handle the installation.
Or, from a terminal, launch:

```bash
sudo curios-update --update-module curios.desktop.ai.lmstudio.bionic true && \
sudo curios-update --update
```

You can launch it from its desktop shortcut or by typing `lm-studio-bionic` in a
terminal.

> [!TIP]
>
> You can monitor your graphics card's usage with the command `nvtop` or through
> the `curios-manager` application in the menu `System -> Process Management (GPU)`
> as seen below:

![LM Studio desktop application](https://github.com/CuriosLabs/CuriOS/blob/master/img/ai_lm-studio.png?raw=true "LM Studio and nvtop.")

> [!IMPORTANT]
>
> **Pro Tip**: In **LM Studio**, the default context length is set to 4096, which
> is too low. The context length is the maximum number of tokens the model can
> process in one prompt. The bigger, the better, but the bigger the context length,
> the more VRAM your model will use on your GPU. A context length of at least 30000
> is recommended. Open **LM Studio**, load a model in the "Developer" or "My Models"
> window, then in the right panel on the "Load" tab change the "Context length"
> value.
> Monitor your GPU memory usage with `nvtop` in a terminal. Try to reach around
> 85% usage of GPU memory.
> See [LM Studio documentation](https://lmstudio.ai/docs/app/advanced/per-model).

LM Studio can also power the AI features in other programs on your computer. It
does this by running an AI engine in the background that other apps can connect
to. Learn more in the [LM Studio documentation](https://lmstudio.ai/docs/app).

### Voxtype - local AI for Speech-to-Text

Curi*OS* comes pre-installed with [Voxtype](https://voxtype.io/), a local Voice-to-Text
app. The Voxtype service and default base model are set during the user's first login.
Press Super+V to toggle it, speak, and toggle it again to start transcription where
your cursor is.

By default it runs on the "base" model because it is the best balance for most
users. If you need more accuracy and have a GPU with enough VRAM, you can try the
"medium" or "large-v3" models with the commands (from a terminal):

```bash
sudo curios-update --update-module curios.desktop.utility.voxtype.model medium && \
sudo curios-update --update && systemctl --user restart voxtype
```

### Web Application Shortcuts

Curi*OS* comes with pre-installed desktop shortcuts for popular AI chat web applications:

- ChatGPT
- Claude
- Gemini
- Grok
- Mistral Vibe (formerly LeChat)

### In-browser LLMs (WebGPU)

Some sites run LLMs entirely in the browser (no local server), for example
[WebLLM](https://webllm.mlc.ai/). They need **WebGPU**.

On Linux, Brave may require an extra flag:

1. Open [brave://flags/#force-enable-webgpu-interop](brave://flags/#force-enable-webgpu-interop)
2. Set **Force enable WebGPU interop** to **Enabled**
3. Relaunch Brave

Check the status at [brave://gpu](brave://gpu) (WebGPU should be available) or
at [webgpureport.org](https://webgpureport.org/).

---

## For Advanced Users & Developers

The following tools are primarily designed for developers or users comfortable
with the command line. They often run in the terminal in a **TUI** (Text-based
User Interface).

### Ollama

**Ollama** is a command-line tool to download and run LLMs locally. It also includes
**open-webui**, which provides a chat interface in your web browser.

To install it, open the `curios-manager` TUI, go to the `Applications` menu, then
`Install/uninstall CuriOS Apps` menu. Search for
`(curios.services) ai - Ollama (local AI)` and enable it (X key to toggle).
Press Enter to submit it and `curios-manager` will handle the installation.

- **Download a model** (e.g., Qwen2.5 Coder): `ollama pull qwen2.5-coder:3b`
- **Run a model**: `ollama run qwen2.5-coder:3b`
- **List installed models**: `ollama ls`
- **List running models**: `ollama ps`

The web chat (open-webui) is available at [http://localhost:8080](http://localhost:8080)
in your browser. Find more models on the [Ollama website](https://ollama.com/).

> [!NOTE]
> AMD GPU users should take a look at [NixOS wiki](https://wiki.nixos.org/wiki/Ollama#AMD_GPU_with_open_source_driver).
> The fix should be written in `/etc/nixos/settings.nix` (See `curios-manager` >
> `Settings (manual edit)`, search for `services.ollama`).

### AI-Powered Code Editors

These applications are advanced code editors (**IDEs**) with built-in AI assistance.

- **OpenCode Desktop**: Installed by default. The open source AI coding agent.
  Free models are included, or connect any model from any provider, including locally
  with LM Studio. See [OpenCode website](https://opencode.ai/).
- **Zed**: Installed by default. You can connect it to LM Studio. See the [Zed documentation](https://zed.dev/docs/ai/llm-providers).
- **Cursor**: An AI-first code editor. Launch the graphical app with `cursor` or
  the terminal version with `cursor-agent`. See the [Cursor documentation](https://cursor.com/docs).

### Terminal (CLI) Tools

Some of these tools require **Node.js** and its package manager, **npm**, which come
pre-installed on Curi*OS*. You can install them with the `npm install -g` command.

- **Claude Code**: Run with `claude`. Install it with `npm install -g @anthropic-ai/claude-code`.
- **Grok Build**: Run with `grok`. Install it with:
  `curl -fsSL https://x.ai/cli/install.sh | bash`
  Some skills may require Python3, install it with:

  ```bash
  sudo curios-update --update-module curios.system.languages.python3.enable true && \
  sudo curios-update --update
  ```

- **OpenAI/ChatGPT Codex**: Run with `codex`. Install it with `npm install -g @openai/codex`.
- **OpenCode**: The *recommended* open source terminal-based coding assistant.
  Installed by default. Run it with `opencode`. Use the `/connect` command to
  bring your OpenCode Zen, Anthropic or OpenAI API key.

![OpenCode TUI](https://github.com/CuriosLabs/CuriOS/blob/testing/img/OpenCode.png?raw=true "OpenCode")

You can connect it to your LM Studio server by editing its configuration file.
For example, open it with a basic text editor:

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
  "autoupdate": false,
  // LLM Providers - Adjust to your LM Studio configuration
  "provider": {
    "lmstudio": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio (local)",
      "options": {
        "baseURL": "http://127.0.0.1:1234/v1"
      },
      "models": {
        "qwen/qwen3.5-9b": {
          "name": "Qwen3.5 9b (local)"
        }
      }
    },
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "qwen2.5-coder:3b": {
          "name": "Qwen2.5 Coder 3b"
        }
      }
    }
  }
}
```

Learn more in the [opencode documentation](https://opencode.ai/docs/).

---
**Next**: [Security and hardware keys](security.md).

**Previous**: [Backup your Computer](backups.md).

**Back**: [index](index.md)
