#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
      echo "  SKIP (real dir, not a symlink): $dest"
      skipped=$((skipped + 1))
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
    --tool=copilot)  TOOL="copilot" ;;
    --tool=all)      TOOL="all" ;;
    /*)              PROJECT_PATH="$arg" ;;
    *)               PROJECT_PATH="$(pwd)/$arg" ;;
  esac
done

echo ""
echo "swe-skills install.sh"
echo "──────────────────────────────────────────────────────"

# ── VALIDATION ────────────────────────────────────────────────────────────────

if [ -z "$SCOPE" ] || [ -z "$TOOL" ]; then
  echo ""
  echo "Usage:"
  echo "  ./install.sh --scope=user    --tool=claude|copilot|all"
  echo "  ./install.sh --scope=project --tool=claude|copilot|all  /path/to/your-project"
  echo ""
  echo "  --tool=claude    Claude Code, OpenCode, Cursor  (~/.claude/skills/ or .claude/skills/)"
  echo "  --tool=copilot   GitHub Copilot                 (~/.copilot/skills/ or .github/skills/)"
  echo "  --tool=all       Both tools"
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
  claude-user)     install_claude_user ;;
  claude-project)  install_claude_project ;;
  copilot-user)    install_copilot_user ;;
  copilot-project) install_copilot_project ;;
  all-user)        install_claude_user; install_copilot_user ;;
  all-project)     install_claude_project; install_copilot_project ;;
esac

echo ""
echo "Done."
