# Development Guide

This guide covers the technical setup and workflow for contributing to CuriOS.

## Getting the Code

First, clone the repository and enter the directory:

```bash
git clone https://github.com/CuriosLabs/CuriOS.git
cd CuriOS
```

CuriOS development primarily happens on the `testing` branch. Switch to it
before starting your work:

```bash
git checkout testing
```

## Setting Up the Environment

CuriOS uses Nix to provide a reproducible development environment. You can enter
this environment using the provided `shell.nix` file:

```bash
nix-shell shell.nix
```

This shell includes all the necessary tools for building, linting, and testing
the project, such as `just`, `statix`, `shellcheck`, and `nix-build`.

## Command Runner (Just)

We use `just` to automate common development tasks. Once you are inside the
`nix-shell`, you can use the following commands:

- `just`: List all available recipes.
- `just build`: Build the CuriOS ISO image for the current branch.
- `just lint`: Run linters on all Nix and Bash files.
- `just test-all`: Run all integration tests sequentially.
- `just test-unit <target>`: Run a specific integration test (e.g.,
`just test-unit office`).
- `just clean`: Remove build artifacts and perform Nix garbage collection.

## AI Assistant Users

If you are using an AI assistant (such as Gemini CLI, Claude Code, or others)
to contribute to this project, please refer to the [AGENTS.md](../AGENTS.md) file
in the root of the repository. It contains essential context and instructions
tailored for AI agents to ensure that their contributions align with our
architectural standards and coding conventions.

---

**Back**: [index](index.md)
