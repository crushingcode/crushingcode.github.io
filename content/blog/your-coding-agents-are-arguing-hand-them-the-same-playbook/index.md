---
title: "Your Coding Agents Are Arguing. Hand Them the Same Playbook"
date: "2026-07-01"
authors:
  - name: Nishant Srivastava
    link: /about/
tags: ["coding-agent", "skills"]
---

![Banner](header.jpg)

<!--Short abstract goes here-->

Your coding agents are not on the same page. Claude Code got one version of the rules. Codex got another. Someone dropped a copy into `.opencode/` that is three months stale. Now one agent insists on the `v2` API and another keeps generating `v1` code. They are not arguing because they disagree. They are arguing because you handed them different playbooks.

<!--more-->

The fix is one directory and one install command. Put everything under `.agents/skills/` and every agent reads from the same sheet.

## The Problem: Skills Drift

Every agent tool has its own skill directory. Claude Code uses `.claude/`. Codex uses `.codex/`. OpenCode uses `.opencode/`. Support more than one agent and you either duplicate skills across those directories or find a way to share them.

Duplication is the naive approach. Write the skill once for Claude, copy it into Codex, and soon the two diverge. One team updates `.claude/` but forgets `.codex/`. Now Claude runs one version of the instructions and Codex runs another. Multiple copies, different behavior.

### The Workaround: A Skill Bridge

Some teams try something smarter. Instead of copying, they create a symlink bridge. The real instructions live in one agent's directory and the other agent's skill points back to it through a symlink.

```text {hl_lines=[4,9,11]}
.claude/
  skills/
    add-compose-preview/
      SKILL.md                    # real instructions live here

.codex/
  skills/
    add-compose-preview/
      SKILL.md                    # thin wrapper: "read references/source.md"
      references/
        source.md -> ../../../../.claude/skills/add-compose-preview/SKILL.md   # symlink
```

Here `.claude/skills/add-compose-preview/SKILL.md` holds the real content:

```markdown
# Add Compose Preview

Add Jetpack Compose `@Preview` functions and
`PreviewParameterProvider` classes. Use whenever the user
wants to add previews to a `@Composable`.

Create a `private` wrapper per variant that calls the target
composable with sample data. Annotate the wrapper, not the original:

- `@Preview(showBackground = true)` — baseline
- `@PreviewLightDark` — light + dark mode
- `@PreviewFontScale` — default + large font
- `@PreviewScreenSizes` — phone + foldable + tablet
- `@PreviewDynamicColors` — dynamic color on/off

For custom configs pass `uiMode`, `fontScale`, `locale`,
`device = Devices.*`, `showSystemUi`. Use `PreviewParameterProvider<T>`
when the composable takes non-trivial inputs. Name each wrapper
descriptively and keep it in the same file as the composable.
```

The `.codex/skills/add-compose-preview/SKILL.md` wrapper stays thin. It just tells Codex where to look:

```markdown
---
name: add-compose-preview
description: Add Jetpack Compose @Preview and PreviewParameterProvider code.
---

# Add Compose Preview

1. Read `references/source.md` and follow it.
2. Keep existing annotation conventions.
3. Report which functions were updated.
```

Codex discovers the wrapper, reads the reference, and follows the same instructions Claude uses.

### Why the Bridge Breaks Down

On paper this is clever. In practice it is fragile.

The symlink uses a relative path like `../../../../.claude/skills/add-compose-preview/SKILL.md`. Rename or move the Claude file and the symlink snaps silently. No error, no warning. Codex just stops finding the instructions.

New contributors open the Codex wrapper expecting instructions and find a redirect instead. They have to trace the symlink to figure out what the skill actually does. That adds friction every time someone reads the file.

You still end up maintaining two locations. The repo says "Claude files here, Codex files there" instead of pointing to one place. Add a third agent and you build another bridge.

### The Core Problem

Whether you duplicate files or bridge them with symlinks, the root issue is the same: your skill instructions are scattered across agent-specific directories. Every directory is a potential drift point and every bridge is a path that can break.

That is not an agent bug. It is a layout problem.

## The Solution: Centralize

Skill files are documentation that agents read, not per tool config. Documentation belongs in one place.

```text
.agents/
  README.md
  skills/
    add-compose-preview/
      SKILL.md
```

Point every agent at `.agents/skills/`. No mirrors, no duplicates to manage.

Keep the structure flat. One skill per directory. One `SKILL.md` per skill. Keep the name stable and the instructions short. If a skill needs examples or scripts, put them next to the `SKILL.md`.

One directory means one update reaches every agent at the same time. PRs touch one place instead of three. New team members install once. Reviews show one diff. No one has to guess which copy is current.

### Where Does It Live

`.agents/` works in two places.

**Inside the project repo.** This is more straightforward. Drop `.agents/skills/` at the root alongside `.gitignore`, `build.gradle.kts`, everything else. Every contributor clones, runs one install command, and every agent reads the same skills. Team-wide rules (coding conventions, testing patterns, Compose guidelines) go here.

**As its own standalone repo.** Some teams prefer a separate skills repo that spans all their projects. That works too. Publish it on GitHub (public or internal), install with `npx skills add your-org/your-skills-repo`. Update one place, every project pulls the same refresh. Cross-project standards (style guides, API conventions, review checklists) belong here.

Both commit `.agents/` to git. The difference is scope.

### Why You Only Commit This One

`.agents/` holds portable skill instructions. Every agent reads `SKILL.md` the same way. The content is project knowledge, not user preference. It belongs in git.

Every agent-specific directory (`.claude/`, `.codex/`, `.opencode/`, `.copilot/`, etc.) is user config. Local state, model preferences, agent metadata. All per developer, per machine, per agent version. Commit them and the repo carries every team member's personal settings. Noise, not signal.

One directory to commit. Seven to ignore.

## How to Install Skills

[Skills](https://www.skills.sh/docs) is a CLI from Vercel. Run `npx skills` and it places skill files into the right directory for whatever agent you are using.

### Install a single skill

```bash
# Install from a GitHub repo
npx skills add your-org/your-repo --skill <skill> --agent codex
npx skills add your-org/your-repo --skill <skill> --agent claude-code
```

### Install from a local path

```bash
# Install from your local .agents/skills directory
npx skills add ./.agents/skills --skill <skill> --agent codex
```

### Install all skills at once

```bash
# Install every skill in the repo to the codex agent
npx skills add your-org/your-repo --skill '*' --agent codex --yes

# Install every local skill to the claude-code agent
npx skills add ./.agents/skills --skill '*' --agent claude-code --yes
```

### Agent names

| Agent                                                         | `--agent` value  |
| ------------------------------------------------------------- | ---------------- |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `claude-code`    |
| [Codex](https://github.com/openai/codex)                      | `codex`          |
| [GitHub Copilot](https://github.com/features/copilot)         | `github-copilot` |
| [Cursor](https://cursor.sh)                                   | `cursor`         |
| [OpenCode](https://opencode.ai)                               | `opencode`       |
| [Cline](https://github.com/cline/cline)                       | `cline`          |
| [Gemini CLI](https://cloud.google.com/gemini-cli)             | `gemini-cli`     |
| [Windsurf](https://codeium.com/windsurf)                      | `windsurf`       |

### CLI reference

| Command             | What it does                   |
| ------------------- | ------------------------------ |
| `npx skills add`    | Install a skill                |
| `npx skills use`    | Activate a skill temporarily   |
| `npx skills list`   | Show installed skills          |
| `npx skills find`   | Search for skills              |
| `npx skills update` | Update installed skills        |
| `npx skills remove` | Uninstall a skill              |
| `npx skills init`   | Create a new SKILL.md template |

Update scopes:

```bash
# Update only global skills (available across all projects)
npx skills update -g

# Update only project skills (committed with the current repo)
npx skills update -p

# Update both global and project skills
npx skills update -g -p
```

## The `.gitignore` Rule

Agent directories are user config, not project config. Just add them to `.gitignore`:

```gitignore
# Agent user config, developer specific
.claude/
.codex/
.opencode/
.copilot/
.cursor/
.windsurf/
.gemini/
.cline/
```

Only `.agents/` stays tracked. Keeps things clean. New contributors clone and install without inheriting someone else's editor config or model preferences.

Migrating an existing repo? Check for stray agent dirs:

```bash
# What is tracked?
git ls-files | grep -E '^\.(claude|codex|opencode|copilot|cursor|windsurf|gemini|cline)/'

# Remove from tracking (keep on disk)
git rm -r --cached .claude/ .codex/ .opencode/
```

Then update `.gitignore`, commit. Done ✅

## Telemetry

The `npx skills` CLI sends anonymous telemetry by default (skill name, files, timestamp). No personal or device info. To opt out, add this to your `~/.zshrc` or `~/.bashrc`:

```bash
export DISABLE_TELEMETRY=1
```

## How to Migrate

Hand this prompt to your coding agent:

> Scan the repo for any agent-specific skill directories outside `.agents/skills/`. Look for `.claude/skills/`, `.codex/skills/`, `.opencode/skills/`, `.copilot/skills/`, and any other `.agentname/skills/` patterns. For each one, move the entire skill directory into `.agents/skills/<skill-name>/`, preserving all files (SKILL.md, scripts, examples, configs). Keep the content as is. Do not merge or edit. Then delete the old directories. After that, update `.gitignore` to block all agent-specific directories (`git rm --cached` any that are already tracked). Finally, create or update `.agents/README.md` with `npx skills add` install instructions. Moves first, deletions second, .gitignore third, docs last.

## That's It

Agent tooling changes every few weeks. The skills those agents read do not have to. Put them in one place, install from that place, and your agents stop arguing. One directory, one command, done.
