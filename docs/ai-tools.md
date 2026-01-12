# AI tools

Curi*OS* will help you working with AI, both locally or remotely, in the terminal
or with desktop applications.

## Local AI

If you have a Nvidia or AMD GPU, Curi*OS* should have installed the corresponding
driver during the OS installation. Therefore you can run AI locally with the help
of LM studio or Ollama.

### LM Studio

**LM Studio** is a desktop applications providing an interactive chat, an interface
to search, download and run LLMs on your machine, launch it from its desktop
shortcut or from a terminal with the command:

```bash
lm-studio
```

![LM Studio desktop application](https://github.com/CuriosLabs/CuriOS/blob/testing/img/ai_lm-studio.png?raw=true "LM Studio and nvtop.")

You can monitor your GPU usage as in the picture above with the command:

```bash
nvtop
```

Or from the `curios-manager` TUI in the menu `System > Process Management (GPU)`.

**LM Studio** can also run a local server and act as a local LLM provider for
third-party applications like **Zed** editor, **opencode** TUI, etc...
Learn more on [LM Studio documentation](https://lmstudio.ai/docs/app).

### Ollama

**Ollama** is a CLI to get and run LLMs locally. It also come with the **open-webui**
server to chat with your LLM from your browser. To install it, edit the file
`/etc/nixos/settings.nix` or from the `curios-manager` TUI go to the `Settings
(manual edit)` menu and set `services.ai.enable = true;`, save the file (Ctrl+O
then Ctrl+X) and `curios-manager` will do the install.

To download a model:

```bash
ollama pull gemma3
```

Search for models on [Ollama website](https://ollama.com/).

To list installed models:

```bash
ollama ls
```

The **open-webui** chat is reachable at [http://localhost:11434](http://localhost:11434).

Learn more at [Ollama documentation](https://docs.ollama.com/).

## Web applications

Curi*OS* come installed with desktop shortcuts for the following AI chat web
applications:

- ChatGPT
- Claude
- Grok
- Mistral LeChat

## Terminal applications

If you are a developer you will probably prefer a TUI application able to interact
with your code directly on your machine. Most of the following TUI can be
installed with `npm`, **Node.js** and `npm` come pre-installed with Curi*OS* (if 
not check if `devops.javascript.enable` is set to true in `/etc/nixos/settings.nix`).

## Claude code

To always get the latest up-to-date version, install it with:

```bash
npm install -g @anthropic-ai/claude-code
```

And then run it with:

```bash
claude
```

## Gemini CLI

To always get the latest up-to-date version, install it with:

```bash
npm install -g @google/gemini-cli
```

And then run it with:

```bash
gemini
```

## opencode

## AI-assisted desktop applications

### Zed

**Zed.dev** editor is installed by default with Curi*OS*. It is a powerful code
editor.

### Cursor

### Windsurf

**Next**: .

**Previous**: [Backup your Computer](backups.md).

**Back**: [index](index.md)
