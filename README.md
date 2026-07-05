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
  - [Detailed Walkthrough](#detailed-walkthrough)
- [Supported Tools](#supported-tools)
- [Project Structure](#project-structure)
- [How It's Done](#how-its-done)
  - [Placeholder Replacement](#placeholder-replacement)
  - [File Cleanup](#file-cleanup)
  - [Config File Detection](#config-file-detection)
- [License](#license)

---

## Why This Exists

Default system prompts shipped with AI coding tools are **verbose** -- they include safety rails, personality fluff, tool definitions, and multi-shot examples that:

- **Consume context window** that could hold your actual code and instructions
- **Slow down responses** with unnecessary deliberation patterns
- **Enforce safety constraints** you may have already decided against

This project provides **quantized (compressed) system prompts** that strip away specific layers so you keep only what matters for your workflow. The result is a leaner, faster, more direct AI that spends less token budget on boilerplate and more on solving your problem.

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
| 1 | No Safety | Safety restrictions | ~17 KB | Power users who want unrestricted output |
| 2 | No Personality | Personality & examples | ~69 KB | Users who want concise, no-fluff responses |
| 3 | No Personality & Examples | Most aggressive strip | ~78 KB | Maximum optimization -- prompt as lean as possible |
| 4 | No Tools or Skills | Tool & skill definitions | ~32 KB | Users who don't use AI CLI tools |
| 5 | Max Quant | Maximum compression | ~17 KB | Smallest possible prompt |

> **Warning:** Levels 1 and 3 remove safety restrictions and/or examples that guide the model toward helpful behavior. Use at your own discretion.

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

### Detailed Walkthrough

When you run `setup.sh`, the interactive menu proceeds in six steps.

<details>
<summary><strong>Step 1 -- Model Name</strong></summary>

Enter the name of your AI model (e.g., `Claude`, `Opus`, `Sonnet`, `Gemini`, `GPT`, `DeepSeek`). This replaces the `<ai>` placeholder throughout the prompt.

If left blank, defaults to `Claude`.

</details>

<details>
<summary><strong>Step 2 -- CLI Tool Injection</strong></summary>

Choose whether to install the finished prompt into an AI CLI tool's config file:

- **Option 1** -- Install to a tool. All quantization levels available.
- **Option 2** -- Just generate the file. Simplified choices (No Tools or Skills / Max Quant).

</details>

<details>
<summary><strong>Step 3 -- Quantization Level</strong></summary>

Pick how stripped-down you want the prompt. See the [table above](#quantization--what-that-means) for what each level removes.

</details>

<details>
<summary><strong>Step 4 -- Placeholder Replacement</strong></summary>

The script finds all `<ai>` tokens in the selected prompt and replaces them with the model name you entered.

```bash
# What happens under the hood:
MODEL_NAME="Opus" python3 -c "
import os, sys
content = sys.stdin.read()
print(content.replace('<ai>', os.environ['MODEL_NAME']), end='')
" < version/CLAUDE-FABLE-5_NO_SAFETY.md > /tmp/replaced_tmp
mv /tmp/replaced_tmp version/CLAUDE-FABLE-5_NO_SAFETY.md
```

</details>

<details>
<summary><strong>Step 5 -- Cleanup</strong></summary>

All other variant files are removed, leaving only your selected prompt in `version/`.

</details>

<details>
<summary><strong>Step 6 -- Installation</strong></summary>

The finalized prompt is copied or created at the target tool's config file path. Supported tools listed below.

</details>

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
# Auto-backup example:
cp /path/to/.cursorrules /path/to/.cursorrules.bak.$(date +%s)
```

---

## Project Structure

```
optimized_fable_systemprompt/
  README.md            # This file
  setup.sh             # Interactive installer script
  version/             # Prompt variant files
    CLAUDE-FABLE-5_NO_SAFETY.md
    CLAUDE-FABLE-5_NO_PERSONALITY_AND_EXAMPLES.md
    CLAUDE-FABLE-5_NO_PERSONALITY_optimization.md
    CLAUDE-FABLE-5_NO_TOOLS_OR_SKILLS.md
    CLAUDE-FABLE-5_MAX_QUANT.md
```

---

## How It's Done

### Placeholder Replacement

All prompt variants contain `<ai>` tokens where the model name should go. The script uses **Python 3** to perform a single pass replacement via stdin/stdout -- no temporary files leak and no sed-based edge cases.

```bash
# Core replacement logic (from setup.sh)
MODEL_NAME="$MODEL_NAME" python3 -c "
import os, sys
content = sys.stdin.read()
print(content.replace('<ai>', os.environ['MODEL_NAME']), end='')
" < "$SELECTED_FILE" > "$TMPFILE"
mv "$TMPFILE" "$SELECTED_FILE"
```

### File Cleanup

After selection, unused variants are deleted from the `version/` directory so the user is left with only the file they chose:

```bash
for i in 1 2 3; do
  f="${FILES[$i]}"
  if [[ "$f" != "$SELECTED_FILE" && -f "$f" ]]; then
    rm "$f"
  fi
done
```

### Config File Detection

The `find_tool_config()` function searches for existing tool configuration files in a priority order -- project-local first, then home directory:

```bash
find_tool_config() {
  local tool="$1"
  local root="${2:-$PWD}"
  case "$tool" in
    1)  # Claude Code
      [[ -f "$root/.claude/CLAUDE.md" ]] && echo "$root/.claude/CLAUDE.md" \
      || [[ -f "$HOME/.claude/CLAUDE.md" ]] && echo "$HOME/.claude/CLAUDE.md" \
      || echo ""
      ;;
    # ... other tools follow the same pattern
  esac
}
```

---

## License

This project is licensed under the MIT License -- see the [LICENSE](LICENSE) file for details.
