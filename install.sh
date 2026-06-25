#!/usr/bin/env bash
set -euo pipefail

# ── MODE DETECTION ────────────────────────────────────────────────────────────
# BASH_SOURCE is unset when piped from curl — use that to detect remote mode.
here=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || here=""
fi
IS_LOCAL=false
[ -n "$here" ] && [ -d "$here/skills" ] && IS_LOCAL=true

if [ "${AGENTIC_SDLC_REMOTE:-}" = "1" ] && [ "$IS_LOCAL" = false ]; then
  echo "swe-agent-skills: install failed — cloned repo at $HOME/.swe-agent-skills is missing the skills/ directory." >&2
  echo "  Fix: rm -rf $HOME/.swe-agent-skills and retry." >&2
  exit 1
fi

if [ "$IS_LOCAL" = false ]; then
  # ── REMOTE MODE: clone/pull, then re-exec local copy ──────────────────────
  if ! command -v git >/dev/null 2>&1; then
    echo "swe-agent-skills: git required. Install git and retry." >&2
    exit 1
  fi

  CLONE_DIR="$HOME/.swe-agent-skills"

  if [ -d "$CLONE_DIR" ] && [ ! -d "$CLONE_DIR/.git" ]; then
    echo "swe-agent-skills: $CLONE_DIR exists but is not a git repo (partial clone?)." >&2
    echo "  Fix: rm -rf $CLONE_DIR and retry." >&2
    exit 1
  elif [ -d "$CLONE_DIR/.git" ]; then
    echo "Updating swe-agent-skills in $CLONE_DIR ..."
    if ! git -C "$CLONE_DIR" pull --ff-only; then
      echo "swe-agent-skills: update failed — local clone may have diverged." >&2
      echo "  Fix: rm -rf $CLONE_DIR and retry." >&2
      exit 1
    fi
  else
    echo "Cloning swe-agent-skills to $CLONE_DIR ..."
    git clone https://github.com/mhihasan/swe-agent-skills "$CLONE_DIR" || { rm -rf "$CLONE_DIR"; exit 1; }
  fi

  # Apply default args if none given
  if [ "$#" -eq 0 ]; then
    set -- --scope=user --tool=all
  fi

  export AGENTIC_SDLC_REMOTE=1
  exec bash "$CLONE_DIR/install.sh" "$@"
fi

# ── LOCAL MODE ────────────────────────────────────────────────────────────────
REPO_DIR="$here"

# ── HELPERS ───────────────────────────────────────────────────────────────────

link_skills() {
  local src_dir="$1"
  local target_dir="$2"
  local linked=0 skipped=0

  mkdir -p "$target_dir"

  for skill in "$src_dir"/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    dest="$target_dir/$name"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      if [ -f "$dest/SKILL.md" ]; then
        rm -rf "$dest"
        ln -sfn "$skill" "$dest"
        echo "  UPDATED (replaced real dir with symlink): $dest"
        linked=$((linked + 1))
      else
        echo "  SKIP (real dir, no SKILL.md — not a managed install): $dest"
        skipped=$((skipped + 1))
      fi
    else
      ln -sfn "$skill" "$dest"
      echo "  LINKED: $dest"
      linked=$((linked + 1))
    fi
  done

  echo "  → $linked linked, $skipped skipped"
}

# ── ARGUMENT PARSING ──────────────────────────────────────────────────────────

SCOPE=""
TOOL=""
PROJECT_PATH=""

for arg in "$@"; do
  case "$arg" in
    --scope=user)    SCOPE="user" ;;
    --scope=project) SCOPE="project" ;;
    --tool=claude)   TOOL="claude" ;;
    --tool=opencode) TOOL="opencode" ;;
    --tool=copilot)  TOOL="copilot" ;;
    --tool=all)      TOOL="all" ;;
    --*)             echo "Unknown option: $arg" >&2; exit 1 ;;
    /*)              PROJECT_PATH="$arg" ;;
    *)               PROJECT_PATH="$(pwd)/$arg" ;;
  esac
done

echo ""
echo "swe-agent-skills install.sh"
echo "──────────────────────────────────────────────────────"

# ── VALIDATION ────────────────────────────────────────────────────────────────

if [ -z "$SCOPE" ] || [ -z "$TOOL" ]; then
  echo ""
  echo "Usage:"
  echo "  ./install.sh --scope=user    --tool=claude|copilot|all"
  echo "  ./install.sh --scope=project --tool=claude|copilot|all  /path/to/your-project"
  echo ""
  echo "  --tool=claude    Claude Code, Cursor          (~/.claude/skills/ or .claude/skills/)"
  echo "  --tool=opencode  OpenCode                    (~/.config/opencode/skills/ or .opencode/skills/)"
  echo "  --tool=copilot   GitHub Copilot              (~/.copilot/skills/ or .github/skills/)"
  echo "  --tool=all       All tools"
  echo ""
  echo "  --scope=user     Install globally, available in all projects"
  echo "  --scope=project  Install into the given project directory only"
  echo ""
  exit 1
fi

if [ "$SCOPE" = "project" ] && [ -z "$PROJECT_PATH" ]; then
  echo ""
  echo "Error: --scope=project requires a project path."
  echo "Usage: ./install.sh --scope=project --tool=<tool> /path/to/your-project"
  echo ""
  exit 1
fi

if [ "$SCOPE" = "project" ] && [ ! -d "$PROJECT_PATH" ]; then
  echo ""
  echo "Error: project path does not exist: $PROJECT_PATH"
  echo ""
  exit 1
fi

# ── INSTALL ───────────────────────────────────────────────────────────────────

install_claude_user() {
  echo ""
  echo "[claude / user scope] $HOME/.claude/skills/"
  link_skills "$REPO_DIR/skills" "$HOME/.claude/skills"
  link_skills "$REPO_DIR/book-skills" "$HOME/.claude/skills"
}

install_claude_project() {
  echo ""
  echo "[claude / project scope] $PROJECT_PATH/.claude/skills/"
  link_skills "$REPO_DIR/skills" "$PROJECT_PATH/.claude/skills"
  link_skills "$REPO_DIR/book-skills" "$PROJECT_PATH/.claude/skills"
}

install_opencode_user() {
  echo ""
  echo "[opencode / user scope] $HOME/.config/opencode/skills/"
  link_skills "$REPO_DIR/skills" "$HOME/.config/opencode/skills"
  link_skills "$REPO_DIR/book-skills" "$HOME/.config/opencode/skills"
}

install_opencode_project() {
  echo ""
  echo "[opencode / project scope] $PROJECT_PATH/.opencode/skills/"
  link_skills "$REPO_DIR/skills" "$PROJECT_PATH/.opencode/skills"
  link_skills "$REPO_DIR/book-skills" "$PROJECT_PATH/.opencode/skills"
}

install_copilot_user() {
  echo ""
  echo "[copilot / user scope] $HOME/.copilot/skills/"
  link_skills "$REPO_DIR/skills" "$HOME/.copilot/skills"
  link_skills "$REPO_DIR/book-skills" "$HOME/.copilot/skills"
}

install_copilot_project() {
  echo ""
  echo "[copilot / project scope] $PROJECT_PATH/.github/skills/"
  link_skills "$REPO_DIR/skills" "$PROJECT_PATH/.github/skills"
  link_skills "$REPO_DIR/book-skills" "$PROJECT_PATH/.github/skills"
}

case "$TOOL-$SCOPE" in
  claude-user)      install_claude_user ;;
  claude-project)   install_claude_project ;;
  opencode-user)    install_opencode_user ;;
  opencode-project) install_opencode_project ;;
  copilot-user)     install_copilot_user ;;
  copilot-project)  install_copilot_project ;;
  all-user)         install_claude_user; install_opencode_user; install_copilot_user ;;
  all-project)      install_claude_project; install_opencode_project; install_copilot_project ;;
esac

echo ""
echo "Done."
