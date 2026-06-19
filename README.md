# swe-skills

Software craft skills for AI coding agents — grounded in books, not vibes.

Works with Claude Code, OpenCode, Cursor, and GitHub Copilot.

## Skills

### Craft (book-grounded)

| Skill | Source | What it does |
|---|---|---|
| `/ddd-expert` | *Domain-Driven Design* — Evans | DDD coaching: bounded contexts, aggregates, ubiquitous language, model integrity |
| `/clean-architecture` | *Clean Architecture* — Martin | SOLID, component design, dependency rules, layer boundaries |
| `/clean-coding` | *Clean Code* — Martin | Naming, functions, comments, formatting, error handling, refactoring heuristics |
| `/design-patterns-expert` | *Design Patterns* — GoF | Pattern selection, trade-offs, implementation guidance for all 23 GoF patterns |
| `/pragmatic-engineer` | *The Pragmatic Programmer* — Hunt & Thomas | Pragmatic philosophy, tooling, decoupling, concurrency, project practices |
| `/system-designing` | *Designing Data-Intensive Applications* — Kleppmann | Replication, sharding, transactions, consistency, streaming, batch processing |

### Writing & Docs

| Skill | What it does |
|---|---|
| `/de-slop` | Strip AI writing patterns from any text — docs, READMEs, posts, emails — and rewrite it to sound human |
| `/generating-design-doc` | Document an existing codebase as a structured architecture document |

## Installation

```bash
git clone git@github.com:mhihasan/swe-skills.git
cd swe-skills

# User scope — available in all projects
./install.sh --scope=user --tool=claude     # → ~/.claude/skills/
./install.sh --scope=user --tool=copilot    # → ~/.copilot/skills/
./install.sh --scope=user --tool=all        # → both

# Project scope — current project only
./install.sh --scope=project --tool=claude /path/to/project
./install.sh --scope=project --tool=copilot /path/to/project
```

Safe to re-run. Existing symlinks are updated, real directories are never overwritten.

## Pair with

**[agentic-sdlc](https://github.com/mhihasan/agentic-sdlc)** — the SDLC pipeline: ticket → plan → tasks → code → review → commits. These craft skills complement it at implementation time.
