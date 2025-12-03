# Changelog

All notable changes to the AI-Native Development Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2025-12-03

### Added
- **SessionStart hook** - Automatically shows workflow status when Claude Code starts
- Hooks directory with `session-start.sh` for context injection
- `.claude/settings.json` auto-configuration with hook setup
- More directive CLAUDE.md template with explicit workflow instructions
- **Slash commands** - `/status`, `/next`, `/approve`, `/validate` for quick workflow control

### Changed
- CLAUDE.md template now uses "REQUIRED" language with step-by-step instructions
- Framework instructions include `@` file references for agent specs
- Setup installs hooks to `.claude/hooks/` and configures `settings.json`
- Setup installs slash commands to `.claude/commands/`
- `install.sh` and `update.sh` now handle hooks and slash-commands directories

## [1.2.0] - 2025-12-03

### Added
- Smart change detection in `setup.sh` - only applies necessary changes
- `--dry-run` flag to preview changes without applying them
- `--force` flag to skip confirmations and overwrite all files
- `--yes` flag to auto-confirm prompts while still showing changes
- Change summary display showing what will be created, updated, merged, or skipped
- Workflow-in-progress detection - preserves `workflow-state.json` when workflow has started
- Config merging - `project-config.json` customizations are preserved on re-runs
- Commands update detection - only updates changed command files

### Changed
- `setup.sh` now asks for confirmation before making changes (unless `--yes` or `--force`)
- Re-running setup on an up-to-date project exits early with "Everything is up to date"
- Better user feedback showing exactly what was changed vs preserved

## [1.1.0] - 2025-12-03

### Added
- `--deep-analyze` flag for comprehensive architecture scanning
- Architecture snapshot schema (`architecture-snapshot-schema.json`)
- Deep analysis prompt file for Claude Code to complete architecture analysis
- HTML comment markers for safe framework section updates
- Acknowledgments section crediting Vivian Fu and Claude Code Development Kit

### Changed
- Framework instructions now go to `.claude/CLAUDE.md` instead of root `CLAUDE.md`
- Setup can be run multiple times safely (marker-based updates)
- MCP section simplified - Claude Code handles MCP servers natively
- Validation scripts now include architecture-snapshot.json

### Removed
- `commands/context7.sh` - redundant, Claude Code uses MCP directly
- `commands/gemini-review.sh` - redundant, Claude Code uses MCP directly
- `context-refresh-schema.json` - no longer needed
- `second-opinion-schema.json` - no longer needed

### Fixed
- Setup no longer overwrites existing `.claude/CLAUDE.md` content
- Re-running setup preserves custom content outside framework markers

## [1.0.0] - 2025-12-02

### Added
- Initial release
- Multi-agent workflow system with specialized agents:
  - Product Manager
  - System Architect
  - Frontend Engineer
  - Backend Engineer
  - AI Engineer
  - QA Engineer
  - DevOps Engineer
- Support agents (Safety, Governance, Code Health)
- Checkpoint and rollback system using git tags
- Interactive help command (`help.sh`)
- Dynamic approval gates (reads from workflow-state.json)
- Validation scripts (Python and Bash)
- Install, setup, and update scripts
- Structured artifact output with JSON schemas
- Workflow state management
- Human approval gates at key stages

---

[1.3.0]: https://github.com/yellow1912/agents/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/yellow1912/agents/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/yellow1912/agents/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yellow1912/agents/releases/tag/v1.0.0
