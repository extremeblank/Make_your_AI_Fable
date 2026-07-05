#!/usr/bin/env bash
set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

info()  { echo -e "${CYAN}  ⓘ  ${NC}$*"; }
ok()    { echo -e "${GREEN}  ✔  ${NC}$*"; }
warn()  { echo -e "${YELLOW}  ⚠  ${NC}$*"; }
fail()  { echo -e "${RED}  ✘  ${NC}$*"; }
step()  { echo -e "\n${MAGENTA}${BOLD}━━━ $* ━━━${NC}"; }
header(){ echo -e "${BOLD}$*${NC}"; }
prompt(){ echo -ne "${CYAN}  → ${NC}$*"; }

declare -A FILES
FILES[1]="CLAUDE-FABLE-5_NO-SAFETY.md"
FILES[2]="CLAUDE-FABLE-5_NO_PERSONALITY_AND_EXAMPLES.md"
FILES[3]="CLAUDE-FABLE-5_NO_PERSONALITY_optimization.md"
FILES[4]="CLAUDE-FABLE-5_NO_TOOLS_OR_SKILLS.md"
FILES[5]="CLAUDE-FABLE-5_MAX_QUANT.md"

declare -A LABELS
LABELS[1]="No Safety     (safety restrictions stripped)"
LABELS[2]="No Personality (personality & examples stripped)"
LABELS[3]="No Personality & Examples (most stripped down / optimized)"
LABELS[4]="No Tools or Skills (tools & skills stripped)"
LABELS[5]="Max Quant (max quantization applied)"

declare -A TOOL_NAME
TOOL_NAME[1]="Claude Code"
TOOL_NAME[2]="Codex CLI"
TOOL_NAME[3]="Cursor"
TOOL_NAME[4]="Windsurf"
TOOL_NAME[5]="GitHub Copilot"
TOOL_NAME[6]="Other (custom path)"
TOOL_NAME[7]="Skip — don't install to any tool"

find_tool_config() {
  local tool="$1"
  local root="${2:-$PWD}"
  case "$tool" in
    1)
      if [[ -f "$root/.claude/CLAUDE.md" ]]; then
        echo "$root/.claude/CLAUDE.md"
      elif [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
        echo "$HOME/.claude/CLAUDE.md"
      else
        echo ""
      fi
      ;;
    2)
      if [[ -f "$root/.codexclinerules" ]]; then
        echo "$root/.codexclinerules"
      elif [[ -f "$root/CODEX.md" ]]; then
        echo "$root/CODEX.md"
      else
        echo ""
      fi
      ;;
    3)
      if [[ -f "$root/.cursorrules" ]]; then
        echo "$root/.cursorrules"
      elif [[ -f "$root/.cursor/.cursorrules" ]]; then
        echo "$root/.cursor/.cursorrules"
      else
        echo ""
      fi
      ;;
    4)
      if [[ -f "$root/.windsurfrules" ]]; then
        echo "$root/.windsurfrules"
      else
        echo ""
      fi
      ;;
    5)
      if [[ -f "$root/.github/copilot-instructions.md" ]]; then
        echo "$root/.github/copilot-instructions.md"
      elif [[ -f "$root/.github/instructions.md" ]]; then
        echo "$root/.github/instructions.md"
      else
        echo ""
      fi
      ;;
    *) echo "" ;;
  esac
}

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║              Fable 5 — System Prompt Installer              ║
║         Configure & deploy your AI system prompt            ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo ""
step "STEP 1 — Model Name"
info "What is the name of your AI model?"
info "(e.g. Claude, Opus, Sonnet, Gemini, GPT, DeepSeek, ...)"
echo ""
prompt "Model name: "
read -r MODEL_NAME
MODEL_NAME="${MODEL_NAME%% }"
if [[ -z "$MODEL_NAME" ]]; then
  warn "No name entered — defaulting to 'Claude'"
  MODEL_NAME="Claude"
fi
ok "Model name set to: ${BOLD}$MODEL_NAME${NC}"

step "STEP 2 — Inject Into a CLI Tool?"

echo -e "${DIM}Do you want to install this system prompt into an AI CLI tool?${NC}"
echo -e "${DIM}This will copy the prompt into the tool's config file (e.g. .claude/CLAUDE.md).${NC}"
echo ""
echo -e "  ${BOLD}1${NC}  Yes, install to a CLI tool  —  I'll pick which tool & quantization"
echo -e "  ${BOLD}2${NC}  No (or just generate the file) —  only Full or Max Quantized options"
echo ""

while :; do
  prompt "Choice [1-2]: "
  read -r CLI_CHOICE
  CLI_CHOICE="${CLI_CHOICE:-}"
  if [[ "$CLI_CHOICE" =~ ^[12]$ ]]; then
    break
  fi
  fail "Please enter 1 (yes, with tools) or 2 (no / just the file)."
done

if [[ "$CLI_CHOICE" == "1" ]]; then
  WITH_TOOLS=true
  ok "CLI tool installation enabled — all 3 quantization levels available."
else
  WITH_TOOLS=false
  ok "No CLI installation — simplified quantization (no tools or Max Quantized)."
fi

step "STEP 3 — Choose Quantization Level"
echo -e "${DIM}Quantization = how much of the original prompt to keep.${NC}"
echo -e "${DIM}Higher = more stripped down (smaller, less verbose).${NC}"
echo ""

if [[ "$WITH_TOOLS" == true ]]; then
  for i in 1 2 3; do
    echo -e "  ${BOLD}$i${NC}  ${LABELS[$i]}"
  done
  echo ""
  while :; do
    prompt "Pick quantization level [1-3]: "
    read -r LEVEL
    LEVEL="${LEVEL:-}"
    if [[ "$LEVEL" =~ ^[1-3]$ ]]; then
      break
    fi
    fail "Please enter 1, 2, or 3."
  done
else
  echo -e "  ${BOLD}1${NC}  No tools or skills         (least quantized — No Safety)"
  echo -e "  ${BOLD}2${NC}  Max quantized  (most stripped down / optimized)"
  echo ""
  while :; do
    prompt "Pick quantization level [1-2]: "
    read -r LEVEL
    LEVEL="${LEVEL:-}"
    if [[ "$LEVEL" == "1" ]]; then
      LEVEL=4
      break
    elif [[ "$LEVEL" == "2" ]]; then
      LEVEL=5
      break
    fi
    fail "Please enter 1 (NO_TOOLS) or 2 (MAX_QUANTIZATION)."
  done
fi

SELECTED_FILE="${FILES[$LEVEL]}"
ok "Selected: ${BOLD}${LABELS[$LEVEL]}${NC} → ${SELECTED_FILE}"

step "STEP 4 — Replace Placeholders"

BEFORE=$(grep -Fo '<ai>' "$SELECTED_FILE" 2>/dev/null | wc -l || echo 0)

if [[ "$BEFORE" -eq 0 ]]; then
  warn "No '<ai>' placeholders found in ${SELECTED_FILE} — nothing to replace."
else
  info "Found ${BOLD}$BEFORE${NC} occurrences of '<ai>' in '${SELECTED_FILE}'"
fi

TMPFILE=$(mktemp)
MODEL_NAME="$MODEL_NAME" python3 -c "
import os, sys
content = sys.stdin.read()
print(content.replace('<ai>', os.environ['MODEL_NAME']), end='')
" < "$SELECTED_FILE" > "$TMPFILE"
mv "$TMPFILE" "$SELECTED_FILE"

AFTER=$(grep -Fo "$MODEL_NAME" "$SELECTED_FILE" | wc -l || echo 0)
ok "Replaced all '<ai>' → '${MODEL_NAME}' (${AFTER} occurrences)"

step "STEP 5 — Clean Up Variant Files"

info "Removing the other quantization files (keeping only '${SELECTED_FILE}')"
DELETED=0
for i in 1 2 3; do
  f="${FILES[$i]}"
  if [[ "$f" != "$SELECTED_FILE" && -f "$f" ]]; then
    rm "$f"
    ok "Deleted: $f"
    ((DELETED++))
  fi
done

if [[ "$DELETED" -eq 0 ]]; then
  info "No other variant files to clean up."
else
  ok "Removed ${BOLD}$DELETED${NC} variant file(s)."
fi

INSTALL_DEST=""

if [[ "$WITH_TOOLS" == true ]]; then
  step "STEP 6 — Install to AI CLI Tool"

  echo -e "${DIM}Choose which AI CLI tool to copy this system prompt into.${NC}"
  echo -e "${DIM}The script will find or create the appropriate config file.${NC}"
  echo ""

  for i in 1 2 3 4 5 6 7; do
    echo -e "  ${BOLD}$i${NC}  ${TOOL_NAME[$i]}"
  done
  echo ""

  while :; do
    prompt "Pick a tool [1-7]: "
    read -r TOOL_CHOICE
    TOOL_CHOICE="${TOOL_CHOICE:-}"
    if [[ "$TOOL_CHOICE" =~ ^[1-7]$ ]]; then
      break
    fi
    fail "Please enter a number between 1 and 7."
  done

  if [[ "$TOOL_CHOICE" == "7" ]]; then
    echo ""
    warn "Skipped CLI tool installation (selected 'Skip')."
  elif [[ "$TOOL_CHOICE" == "6" ]]; then
    echo ""
    prompt "Enter the full path to the config file (or directory): "
    read -r CUSTOM_PATH
    CUSTOM_PATH="${CUSTOM_PATH%% }"
    if [[ -z "$CUSTOM_PATH" ]]; then
      warn "No path given — skipping install."
    elif [[ -f "$CUSTOM_PATH" ]]; then
      INSTALL_DEST="$CUSTOM_PATH"
    elif [[ -d "$CUSTOM_PATH" ]]; then
      INSTALL_DEST="$CUSTOM_PATH/CLAUDE.md"
      info "Directory given — will create ${INSTALL_DEST}"
    else
      INSTALL_DEST="$CUSTOM_PATH"
      info "Will create new file at ${INSTALL_DEST}"
    fi
  else
    echo ""
    info "Searching for ${TOOL_NAME[$TOOL_CHOICE]} config..."

    INSTALL_DEST="$(find_tool_config "$TOOL_CHOICE" "$SCRIPT_DIR")"
    if [[ -z "$INSTALL_DEST" ]]; then
      INSTALL_DEST="$(find_tool_config "$TOOL_CHOICE" "$HOME")"
    fi

    if [[ -n "$INSTALL_DEST" ]]; then
      ok "Found existing config: ${BOLD}$INSTALL_DEST${NC}"
    else
      warn "No existing config found for ${TOOL_NAME[$TOOL_CHOICE]}."
      echo ""
      case "$TOOL_CHOICE" in
        1) DEFAULT_PATH="$SCRIPT_DIR/.claude/CLAUDE.md" ;;
        2) DEFAULT_PATH="$SCRIPT_DIR/.codexclinerules" ;;
        3) DEFAULT_PATH="$SCRIPT_DIR/.cursorrules" ;;
        4) DEFAULT_PATH="$SCRIPT_DIR/.windsurfrules" ;;
        5) DEFAULT_PATH="$SCRIPT_DIR/.github/copilot-instructions.md" ;;
      esac
      info "Default location would be: ${BOLD}$DEFAULT_PATH${NC}"
      prompt "Create config at this path? [Y/n]: "
      read -r CREATE_CONFIRM
      CREATE_CONFIRM="${CREATE_CONFIRM:-Y}"
      if [[ "${CREATE_CONFIRM,}" == "y" ]]; then
        INSTALL_DEST="$DEFAULT_PATH"
        mkdir -p "$(dirname "$INSTALL_DEST")"
        ok "Will create new config at: ${BOLD}$INSTALL_DEST${NC}"
      else
        prompt "Enter a custom path (or leave empty to skip): "
        read -r CUSTOM_PATH
        if [[ -n "$CUSTOM_PATH" ]]; then
          INSTALL_DEST="$CUSTOM_PATH"
          mkdir -p "$(dirname "$INSTALL_DEST")"
          ok "Will create new config at: ${BOLD}$INSTALL_DEST${NC}"
        else
          info "Skipping CLI tool installation."
        fi
      fi
    fi
  fi

  if [[ -n "$INSTALL_DEST" ]]; then
    echo ""
    info "Installing system prompt to: ${BOLD}$INSTALL_DEST${NC}"

    case "$TOOL_CHOICE" in
      1|2|6)
        cp "$SELECTED_FILE" "$INSTALL_DEST"
        ;;
      3|4)
        if [[ -f "$INSTALL_DEST" && -s "$INSTALL_DEST" ]]; then
          cp "$INSTALL_DEST" "${INSTALL_DEST}.bak.$(date +%s)"
          warn "Existing config backed up to ${INSTALL_DEST}.bak.*"
        fi
        cp "$SELECTED_FILE" "$INSTALL_DEST"
        ;;
      5)
        mkdir -p "$(dirname "$INSTALL_DEST")"
        {
          echo "---"
          echo "description: System prompt for ${MODEL_NAME} — Fable 5 configuration"
          echo "---"
          echo ""
          cat "$SELECTED_FILE"
        } > "$INSTALL_DEST"
        ;;
    esac

    ok "System prompt installed at: ${BOLD}$INSTALL_DEST${NC}"
  fi

else
  step "STEP 6 — CLI Tool Installation (skipped)"
  info "You chose not to install to a CLI tool."
  info "The finalized file is ready at: ${BOLD}${SELECTED_FILE}${NC}"
fi

echo ""
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                    INSTALLATION COMPLETE                     ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}${NC}"
echo ""
echo -e "  ${BOLD}Model Name:${NC}       ${MODEL_NAME}"
echo -e "  ${BOLD}CLI Install:${NC}      $([[ "$WITH_TOOLS" == true ]] && echo "Yes" || echo "No")"
echo -e "  ${BOLD}Quantization:${NC}     Level ${LEVEL} — ${LABELS[$LEVEL]}"
echo -e "  ${BOLD}Chosen File:${NC}      ${SELECTED_FILE}"
if [[ -n "${INSTALL_DEST:-}" ]]; then
  echo -e "  ${BOLD}Installed To:${NC}     ${INSTALL_DEST}"
else
  echo -e "  ${BOLD}Installed To:${NC}     (not installed to any CLI tool)"
fi
echo ""
echo -e "  ${DIM}You can now use this system prompt file with your AI tool.${NC}"
echo -e "  ${DIM}The other variant files have been cleaned up.${NC}"
echo ""
