# AI-Native Development Framework

A multi-agent system that transforms ideas into production software through specialized AI agents.

## What This Does

Instead of one AI doing everything, this framework uses **specialized agents** that work together:

| Agent | Role |
|-------|------|
| **Product Manager** | Turns your idea into clear requirements |
| **System Architect** | Designs technical architecture |
| **Frontend Engineer** | Builds the UI |
| **Backend Engineer** | Builds APIs and data layer |
| **AI Engineer** | Implements AI/ML features |
| **QA Engineer** | Tests everything |
| **DevOps Engineer** | Deploys to production |

Each agent produces structured artifacts that the next agent consumes. You approve key decisions along the way.

---

## Quick Start

### 1. Install the Framework

**Option A: Clone and install**
```bash
git clone https://github.com/YOUR_USERNAME/ai-agents.git
cd ai-agents
./install.sh
```

**Option B: One-liner install**
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ai-agents/main/install.sh | bash
```

This installs the framework to `~/.claude-agents/`.

### 2. Set Up a New Project

```bash
# Go to your project (or create one)
mkdir my-app && cd my-app

# Initialize the agent framework
~/.claude-agents/setup.sh
```

This creates:
```
my-app/
├── .claude/
│   └── CLAUDE.md          # Framework instructions (auto-loaded)
├── project-config.json    # Your project settings
├── ARTIFACTS/             # Where agent outputs go
└── commands/              # Helper commands
```

Note: Framework instructions go in `.claude/CLAUDE.md` so they don't overwrite any existing root `CLAUDE.md` in your project.

### 2b. Set Up an Existing Project

For existing codebases, the framework auto-detects your tech stack:

```bash
cd my-existing-app
~/.claude-agents/setup.sh --analyze
```

It will detect:
- Frontend framework (React, Vue, Angular, etc.)
- Backend framework (Express, FastAPI, Django, etc.)
- Database (PostgreSQL, MongoDB, etc.)
- Infrastructure (Docker, Vercel, etc.)

And set the execution mode to `fast_feature` for incremental development.

### 2c. Deep Analysis (Optional)

For comprehensive architecture understanding:

```bash
~/.claude-agents/setup.sh --deep-analyze
```

This creates a pending architecture snapshot that Claude Code will complete on first run:
- Directory structure with purposes
- Components and their responsibilities
- Patterns (state management, routing, auth, etc.)
- Entry points and integrations
- Coding conventions

The analysis is saved to `ARTIFACTS/system/architecture-snapshot.json` - your existing files are never modified.

### 3. Start Building

Open Claude Code in your project folder and describe what you want to build:

```
"I want to build a mood tracking app where users can log their daily mood,
see trends over time, and get AI-powered insights about patterns."
```

Claude will:
1. Start the **Product Manager** agent
2. Ask you 1-3 clarifying questions
3. Generate a requirements document
4. Ask for your approval
5. Continue to Architecture, then Implementation, then QA, then Deployment

---

## How It Works

### The Workflow

```
Your Idea
    ↓
┌─────────────────────────────────────────────────────────────┐
│  Product Manager                                            │
│  - Asks clarifying questions                                │
│  - Produces: product-requirements-packet.json               │
│  - YOU APPROVE before continuing                            │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│  System Architect                                           │
│  - Presents 2-3 architecture options                        │
│  - Produces: architecture-handover-packet.json              │
│  - YOU SELECT an option before continuing                   │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│  Engineers (run in parallel)                                │
│  - Frontend, Backend, AI engineers work simultaneously      │
│  - Each produces: *-implementation-report.json              │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│  QA Engineer                                                │
│  - Tests everything                                         │
│  - Produces: qa-test-report.json                            │
│  - Recommends: ready to deploy OR needs fixes               │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│  DevOps Engineer                                            │
│  - Deploys to production                                    │
│  - YOU APPROVE before deploying                             │
│  - Produces: deployment-report.json                         │
└─────────────────────────────────────────────────────────────┘
    ↓
Done! 🎉
```

### Your Approval Points

You stay in control. The system pauses and asks for your approval at:

1. **Requirements** - "Is this what you want to build?"
2. **Architecture** - "Which technical approach do you prefer?"
3. **Deployment** - "Ready to go live?"

You can also pause anytime and resume later.

---

## Commands

Run these from your project directory:

| Command | What it does |
|---------|--------------|
| `./commands/help.sh` | **Interactive guide - start here!** |
| `./commands/status.sh` | Show current workflow status |
| `./commands/next.sh` | Show what to do next |
| `./commands/approve.sh <stage>` | Approve a stage to continue |
| `./commands/validate.sh --all` | Validate all artifacts |
| `./commands/checkpoint.sh "msg"` | Save checkpoint for rollback |
| `./commands/rollback.sh` | Rollback to a checkpoint |
| `./commands/export-handoff.sh` | Export status for pausing work |
| `./commands/reset.sh --confirm` | Start over |

---

## Project Configuration

Edit `project-config.json` to customize:

```json
{
  "project_name": "my-app",
  "project_type": "full_stack_web_app",
  "tech_stack": {
    "frontend": "React",
    "backend": "Node.js",
    "database": "PostgreSQL"
  },
  "execution_mode_default": "full_system"
}
```

### Project Types

| Type | Use for |
|------|---------|
| `full_stack_web_app` | Web apps with frontend + backend |
| `api_only_backend` | APIs, microservices |
| `static_website` | Marketing sites, docs |
| `cli_tool` | Command-line applications |
| `mobile_app` | iOS/Android apps |
| `library` | Reusable packages, SDKs |

### Execution Modes

| Mode | Use when |
|------|----------|
| `full_system` | New projects, major redesigns |
| `fast_feature` | Adding features to existing code |

---

## Example Session

```
You: I want to build a habit tracker app

PM Agent: I have a few questions to clarify:
  1. Should habits be daily, weekly, or customizable frequency?
  2. Do you want social features (sharing, accountability partners)?
  3. Any specific integrations (calendar, health apps)?

You: Daily and weekly habits, no social features for MVP,
     calendar integration would be nice for v2

PM Agent: Here's the requirements packet I've created:
  - Core features: habit CRUD, daily check-ins, streak tracking
  - Success metrics: 70% daily active users complete at least one check-in
  - MVP scope: web app, email auth, basic analytics

  Ready to proceed to architecture? (yes/no)

You: yes

Architect Agent: I've analyzed the requirements. Here are 3 options:

  Option A: Simple monolith (Next.js + SQLite)
  - Fastest to build, easiest to deploy
  - Good for: MVP, validating idea

  Option B: Serverless (Vercel + Supabase)
  - Scales automatically, low ops overhead
  - Good for: growth without DevOps investment

  Option C: Traditional stack (React + Node + PostgreSQL)
  - Most flexible, team-friendly
  - Good for: long-term product, hiring developers

  Which option do you prefer?

You: Option B

[...continues through implementation, QA, deployment...]
```

---

## Artifacts

All agent outputs are saved in `ARTIFACTS/`:

```
ARTIFACTS/
├── product-manager/
│   └── product-requirements-packet.json
├── system-architect/
│   └── architecture-handover-packet.json
├── frontend-engineer/
│   └── frontend-implementation-report.json
├── backend-engineer/
│   └── backend-implementation-report.json
├── ai-engineer/
│   └── ai-implementation-report.json
├── qa-engineer/
│   └── qa-test-report.json
├── devops-engineer/
│   └── deployment-report.json
└── system/
    └── workflow-state.json
```

These are structured JSON files that:
- Document decisions made
- Enable handoff between agents
- Provide audit trail
- Can be version controlled

---

## Pausing and Resuming

Need to stop? Your progress is saved automatically.

```bash
# Export a handoff document
./commands/export-handoff.sh

# Later, check where you left off
./commands/status.sh
./commands/next.sh
```

---

## Checkpoints and Rollback

The framework automatically creates **checkpoints** (git tags) at key moments:
- After each stage completes successfully
- After you approve a gate (requirements, architecture, deployment)

This lets you easily roll back if something goes wrong.

### View Checkpoints

```bash
./commands/checkpoint.sh --list
```

### Manual Checkpoint

Create a checkpoint before trying something risky:

```bash
./commands/checkpoint.sh "Before refactoring auth"
```

### Rollback

```bash
# Interactive - shows all checkpoints, pick one
./commands/rollback.sh

# Rollback to most recent checkpoint
./commands/rollback.sh --last

# Rollback to specific checkpoint
./commands/rollback.sh 3-architecture-20241201

# Preview what would change first
./commands/rollback.sh --preview --last
```

Rollback creates a new commit (it doesn't rewrite history), so it's safe to use even after pushing.

---

## Safety and Governance

The framework includes safety checks:

- **Safety Agent** - Reviews for security vulnerabilities, privacy risks, AI safety
- **Governance Agent** - Checks compliance (GDPR, HIPAA, etc.)
- **Code Health Agent** - Monitors code quality and technical debt

These run automatically based on your project's risk level.

---

## Updating

### Check for Updates

```bash
~/.claude-agents/update.sh --check
```

### Update the Framework

```bash
~/.claude-agents/update.sh
```

### Update a Project's Commands

After updating the framework, update each project:

```bash
cd my-project
~/.claude-agents/update.sh --project
```

The framework will also notify you of available updates when you run `setup.sh`.

---

## Troubleshooting

### "No workflow state found"
Run `~/.claude-agents/setup.sh` to initialize your project.

### Validation errors
Run `./commands/validate.sh --all` to see what's wrong. Agents must produce valid JSON matching the schemas.

### Stuck at a stage
Check `./commands/status.sh` for blocking issues. You may need to approve a gate or fix an issue.

---

## Advanced Usage

### Adding a Feature to Existing Project

Set execution mode to `fast_feature` in your config:

```json
{
  "execution_mode_default": "fast_feature"
}
```

This streamlines the workflow - lighter requirements, architecture assessment instead of full design.

### Customizing Agents

Agent specifications are in `~/.claude-agents/L1 - Specialist Agents/`. You can read these to understand how each agent works, but typically you don't need to modify them.

### Skipping Agents

If your project doesn't need certain agents (e.g., no AI features), configure in `project-config.json`:

```json
{
  "agents": {
    "excluded": ["ai_engineer"]
  }
}
```

---

## Optional MCP Servers

Claude Code supports MCP (Model Context Protocol) servers. If configured, Claude Code will use them automatically when helpful - no special commands needed.

### Context7 - Live Documentation

Fetches up-to-date library documentation, preventing hallucinated or outdated APIs.

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

### Gemini - Secondary Review

Provides "four eyes" validation - a second AI perspective on architecture decisions.

```json
{
  "mcpServers": {
    "gemini-coding": {
      "command": "uvx",
      "args": ["gemini-code-mcp"],
      "env": {
        "GEMINI_API_KEY": "your-api-key"
      }
    }
  }
}
```

Add to `~/.claude/settings.json` or your project's `.claude/settings.json`.

---

## Requirements

- [Claude Code](https://claude.ai/code) installed and configured
- Python 3.x (for validation scripts)
- Bash shell
- Git (for checkpoints)

---

## Acknowledgments

This project was inspired by:
- [Vivian Fu](https://www.linkedin.com/in/vfu/) - AI-native development concepts and multi-agent orchestration patterns
- [Claude Code Development Kit](https://github.com/peterkrueck/Claude-Code-Development-Kit) by peterkrueck - MCP integration patterns and hook-based extensibility

---

## License

MIT

---

## Contributing

Issues and PRs welcome. See the `L0 - Meta Layer/` docs for system architecture.
