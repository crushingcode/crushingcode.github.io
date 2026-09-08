---
title: "Ding! Ding! Your Agent Needs You (Or Just Finished)"
date: "2026-09-08"
tags: ["codex", "claude", "opencode"]
authors:
  - name: Nishant Srivastava
    link: /about/
---

![Banner](header.jpg)

<!--Short abstract goes here-->

You prompt an agent and switch tabs. When you check back, it either finished minutes ago or sits stuck on a permission prompt. Sound notifications fix that in two minutes.

<!--more-->

I tried [herdr](https://github.com/herdrdev/herdr) and [cmux](https://github.com/manaflow-ai/cmux) to solve this. Both felt like overkill for something so simple. Then I checked what OpenCode offers. It has a plugin that does exactly that.

## OpenCode

There is already a plugin for this: [`@mohak34/opencode-notifier`](https://github.com/mohak34/opencode-notifier).

Add it to `opencode.json`:

```json {filename="~/.config/opencode/opencode.json"}
{
  "plugin": ["@mohak34/opencode-notifier@latest"]
}
```

Restart OpenCode. Done. You get sounds and desktop notifications for permission requests, session completion, errors, and question prompts.

### Optional config

Create `~/.config/opencode/opencode-notifier.json` to customize:

```json {filename="~/.config/opencode/opencode-notifier.json"}
{
  "sound": true,
  "notification": true,
  "suppressWhenFocused": true,
  "sounds": {
    "complete": "/System/Library/Sounds/Glass.aiff",
    "permission": "/System/Library/Sounds/Funk.aiff",
    "error": "/System/Library/Sounds/Funk.aiff"
  }
}
```

{{< callout type="info" >}}
The plugin uses bundled sounds by default. The paths above show how to override them with macOS system sounds. You can use any audio file you want.
{{< /callout >}}

- `suppressWhenFocused: true` (default): skips alerts when your terminal is active. Set to `false` to always hear it.
- **Platform notes:**
  - **macOS** works out of the box.
  - **Linux** needs `libnotify-bin` + one of `paplay`/`aplay`/`mpv`/`ffplay`.
  

## Codex and Claude Code (same idea, manual hooks)

If you use Codex or Claude Code, the pattern is simpler: paste a hook config that plays a sound on two lifecycle events. See [Codex hooks docs](https://developers.openai.com/codex/hooks) and [Claude Code hooks docs](https://code.claude.com/docs/en/hooks-guide) for the full reference.

### Codex

Paste into `~/.codex/hooks.json`:

```json {filename="~/.codex/hooks.json"}
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff &" } ] }
    ],
    "PermissionRequest": [
      { "hooks": [ { "type": "command", "command": "afplay /System/Library/Sounds/Funk.aiff &" } ] }
    ]
  }
}
```

- `Stop`: agent finished its turn (task done)
- `PermissionRequest`: agent needs your input or approval
- Needs v0.122+ (`codex --version`)
- Will ask you to trust the new hook on next launch, approve it once

### Claude Code

Paste into `~/.claude/settings.json`:

```json {filename="~/.claude/settings.json"}
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff &" } ] }
    ],
    "Notification": [
      { "hooks": [ { "type": "command", "command": "afplay /System/Library/Sounds/Funk.aiff &" } ] }
    ]
  }
}
```

- `Stop`: agent finished its turn (task done)
- `Notification`: agent needs your input or approval

### Shared details

- `&` backgrounds the command so it does not block the agent
- `Glass.aiff` = done, `Funk.aiff` = needs you (pick any two you can tell apart: `ls /System/Library/Sounds/`)
- Restart the agent after editing. Hooks load at session start
- **macOS**: `afplay` ships with macOS, nothing to install
- **Linux**: swap `afplay` for `paplay` or `aplay`

Pick the method that matches your agent. Two minutes of setup. Your agent will tell you when it needs you. That is more like it 🤘🏼
