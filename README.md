# Fable 5 -- System Prompt Installer

> A CLI tool that selects, customizes, and deploys optimized system prompts for AI coding assistants.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/language-bash-4EAA25?logo=gnubash)](setup.sh)

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [How It Works](#how-it-works)
  - [Quantization -- What That Means](#quantization--what-that-means)
  - [Variant Files](#variant-files)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
- [Supported Tools](#supported-tools)
- [License](#license)

---

## Why This Exists

We always wondered **how** Anthropic could optimize system prompts for coding assistants. Not so long ago the system prompt was leaked to the public, but too big and detailed for most models, so we optimized it to fit within the model's context window.

### Why use it?

- **Precision**: Anthropic made it so that Fable had a structured and precise system prompt. So adding this to your own system prompt can help ensure consistency and accuracy.
- **Directness**: It removes unnecessary fluff, making responses faster and more focused.
- **Better results**: By providing a structured and optimized system prompt, you can get better results from your AI model.
---

## How It Works

The repository contains multiple **variants** of the Fable 5 system prompt, each with different layers removed. The `setup.sh` script guides you through:

1.  **Naming** your AI model (replaces `<ai>` placeholders throughout)
2.  **Choosing** whether to install into a CLI tool config or just generate a file
3.  **Selecting** a quantization level
4.  **Installing** the final prompt into your tool's configuration file

### Quantization -- What That Means

Analogous to image compression: higher quantization removes more detail to produce a smaller file. The trade-off is between **completeness** (all safety rails, examples, personality) and **directness** (minimal fluff, faster responses).

| Level | Variant | Stripped | Result Size | Best For |
|-------|---------|----------|-------------|----------|
| 1 | No Safety | Safety restrictions | ~87 KB | Power users who want unrestricted output |
| 2 | No Personality | Personality & examples | ~77 KB | Users who want concise, no-fluff responses |
| 3 | No Personality & Examples | Most aggressive strip | ~68 KB | Removes also examples |
| 4 | No Tools or Skills | Tool & skill definitions | ~31 KB | Users who don't use AI CLI tools |
| 5 | Max Quant | Maximum compression | ~16 KB | Around 200 lines, for smaller models |

> **Warning:** Removing Examples is possibly the most aggressive strip, as examples show the model how to behave.

### Variant Files

All variant prompts live in the `version/` directory:

```
version/
  CLAUDE-FABLE-5_NO_SAFETY.md
  CLAUDE-FABLE-5_NO_PERSONALITY_AND_EXAMPLES.md
  CLAUDE-FABLE-5_NO_PERSONALITY_optimization.md
  CLAUDE-FABLE-5_NO_TOOLS_OR_SKILLS.md
  CLAUDE-FABLE-5_MAX_QUANT.md
```

---

## Installation

### Prerequisites

- **Bash 4+** (for associative array support)
- **Python 3** (for placeholder replacement)
- One of the supported AI CLI tools (optional -- you can just generate the file)

Verify with:

```bash
bash --version | head -1
python3 --version
```

### Quick Start

```bash
git clone https://github.com/your-org/optimized_fable_systemprompt.git
cd optimized_fable_systemprompt
chmod +x setup.sh
./setup.sh
```

---

## Supported Tools

The installer can auto-detect config files for these tools:

| # | Tool | Config File(s) |
|---|------|----------------|
| 1 | Claude Code | `.claude/CLAUDE.md` (local or home) |
| 2 | Codex CLI | `.codexclinerules`, `CODEX.md` |
| 3 | Cursor | `.cursorrules`, `.cursor/.cursorrules` |
| 4 | Windsurf | `.windsurfrules` |
| 5 | GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions.md` |
| 6 | Other | Custom path (file or directory) |
| 7 | Skip | No installation |

For Cursor and Windsurf, the script **backs up** the existing config before overwriting:

```bash
cp /path/to/.cursorrules /path/to/.cursorrules.bak.$(date +%s)
```

---

## License

This project is licensed under the MIT License -- see the [LICENSE](LICENSE) file for details.
