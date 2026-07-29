---
title: "The OpenCode Config That Actually Works (and Ships)"
date: "2026-07-28"
tags: ["opencode", "coding-agent"]
authors:
  - name: Nishant Srivastava
    link: /about/
---

![Banner](header.jpg)

<!--Short abstract goes here-->

I've been using OpenCode a lot lately. New projects, side experiments, untangling a codebase I haven't touched in months. Tried different providers, swapped plugins, reset my `opencode.json` more times than I care to admit.

I finally settled on something that stuck. This is the config I actually ship with every session. Compaction, rules, providers, plugins. The real `opencode.json`, based on what I actually run.

<!--more-->

{{< callout type="info" >}}
Your global config lives at `~/.config/opencode/opencode.json`. Every new session starts from it.
{{< /callout >}}

## Compaction

Think of [compaction](https://opencode.ai/docs/config/#compaction) like a garbage collector for your conversation. Instead of letting every past exchange pile up, it periodically compresses earlier exchanges into dense summaries.

```json {filename="opencode.json"}
"compaction": {
  "auto": true,
  "prune": true,
  "reserved": 6400
}
```

This got me thinking about how much context I waste otherwise. Here is what each setting does:

- **`auto: true`** runs compaction automatically. You'd forget to trigger it yourself anyway. Set it to `true` and move on.

- **`prune: true`** drops old tool outputs after summarization. The summary captures what was changed, decided, and fixed. Without pruning, you carry the full weight of every old message.

- **`reserved: 6400`** is the safety net. I arrived at this number after some experimentation. It leaves enough room for the last few exchanges to survive compaction without making compaction itself ineffective.

## DCP: aggressive context pruning

Compaction works, but it plays it safe. The [DCP plugin](https://opencode.ai/docs/plugins/) (`@tarquinen/opencode-dcp`) runs a more aggressive pass. It strips redundant outputs, compresses older ranges, and nudges you when context gets full.

add it to the `plugin` array

```json {filename="opencode.json"}
"plugin": ["@tarquinen/opencode-dcp@latest"]
```

or Install it via the CLI

```bash {filename="terminal"}
opencode plugin @tarquinen/opencode-dcp@latest --global
```

{{< callout type="info" >}}
OpenCode caches packages across sessions. Next startup is instant.
{{< /callout >}}

DCP creates its own config at `~/.config/opencode/dcp.jsonc`. Here are the settings I use:

```json {filename="dcp.jsonc"}
{
  "compress": {
    "mode": "range",
    "permission": "allow",
    "maxContextLimit": "70%",
    "minContextLimit": "35%",
    "nudgeFrequency": 5
  },
  "turnProtection": {
    "enabled": true,
    "turns": 3
  },
  "strategies": {
    "deduplication": { "enabled": true },
    "purgeErrors": { "enabled": true, "turns": 3 }
  }
}
```

The fields that matter most:

- **`compress`**
  - **`permission: "allow"`** lets DCP compress silently in the background. Switch to `"ask"` if you want to approve each pass.
  - **`maxContextLimit: "70%"`** kicks in early. You don't wait until you're at 99% and gasping for space.
  - **`minContextLimit: "35%"`** is the off switch for nudge reminders. Each cycle buys you more runway.
  - **`nudgeFrequency: 5`** controls how often DCP injects a reminder. Every 5th request, not every turn.
- **`turnProtection`**
  - **`turns: 3`** keeps the last 3 exchanges fully visible. No compression surprises on something you just discussed. You also need `enabled: true` to make this stick.
- **`strategies`**
  - **`purgeErrors`**
    - **`turns: 3`** drops the verbose inputs from errored tool calls after 3 turns. Error messages stay, the noise around them gets trimmed. That stack trace from 10 messages ago? It served its purpose when you fixed the bug. Pure dead weight after that.

{{< callout type="info" >}}
DCP runs automatic strategies (deduplication, purgeErrors) in the background. Compression itself is model-driven. You can also trigger a pass manually with the `/dcp-compress` command in the TUI.
{{< /callout >}}

## Inject rules with `instructions`

[Rule files](https://opencode.ai/docs/rules/) are just markdown. Point a directory of them via `instructions` in your config and OpenCode injects them into the system prompt at the start of every session. This is where I drop conventions and preferred instructions so they don't repeat every time. Drop `android_project_conventions.md` at `~/.config/opencode/rules/`:

```markdown {filename="android_project_conventions.md"}
# Android project conventions

- Use Kotlin coroutines and Flow for async, not RxJava
- Name all database tables in snake_case, columns in camelCase
- All ViewModel state should be a single `sealed interface` per screen
- Use Moshi for JSON, not Gson
- Keep Gradle dependency versions in `libs.versions.toml`, not build.gradle.kts
```

Wire the directory in your `opencode.json`. The model picks up every file in it automatically when a session starts:

```json {filename="opencode.json"}
"instructions": [
    "~/.config/opencode/rules/*.md"
]
```

{{< callout type="info" >}}
Drop more `.md` files in `~/.config/opencode/rules/`. They're all injected into context, so keep it lean.
{{< /callout >}}

That's it. No more repeating yourself every session. Your AGENTS.md stays clean for project-specific instructions.

## Add safety rails

Most tools are [allow by default](https://opencode.ai/docs/permissions/) in OpenCode. A couple of safety guards like `external_directory` and `doom_loop` default to `"ask"`. You can layer targeted `bash` rules on top to keep daily work smooth while catching the dangerous stuff:

```json {filename="opencode.json"}
"permission": {
    "*": "allow",
    "bash": {
        "*": "ask",
        "git *": "allow",
        "grep *": "allow",
        "ls *": "allow",
        "./gradlew *": "allow"
    },
    "external_directory": {
        "~/.config/opencode/**": "allow"
    }
}
```

- **`"*": "allow"`** at the top level lets the model use most tools without approval prompts.
- **`bash`**
  - **`"*": "ask"`** catches anything not explicitly listed. Unknown or risky commands trigger a prompt. The last matching rule wins, so specific rules below override this default.
  - **`"git *": "allow"`** passes normal git operations through. Want to block destructive operations? Add explicit rules after it, like `"git push -f*": "ask"`.
  - **`"grep *": "allow"`** and **`"ls *": "allow"`** stop search and listing from getting annoying.
  - **`"./gradlew *": "allow"`** lets Android builds run without interruption.
- **`external_directory`** gives the model access to your OpenCode config directory without asking. Otherwise it would prompt for every read of your rules or templates.

I wrote in detail about hardening agents against destructive commands in [Hardening Your AI Agent Before It Breaks Everything](/blog/hardening-ai-agents/).

## Wire a local provider for cheap tasks

Got local models running in LM Studio or Ollama? Hook them up as a [provider](https://opencode.ai/docs/providers/). Then point [`small_model`](https://opencode.ai/docs/models/) at one for lightweight tasks like title generation. Saves API credits and cuts latency too:

```json {filename="opencode.json"}
"small_model": "lmstudio/google/gemma-3n-e4b",
"model": "openai/gpt-5.6-sol",
"provider": {
    "lmstudio": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "LM Studio (local)",
        "options": {
            "baseURL": "http://localhost:1234/v1"
        },
        "models": {
            "google/gemma-3n-e4b": {}
        }
    }
}
```

The format is always `provider_id/model_id`. `model` is your daily driver. `small_model` handles the quick stuff like title generation and summaries.

{{< callout type="info" >}}
The local provider setup is optional. If you don't run LM Studio or Ollama, skip `small_model` and the `lmstudio` provider block entirely. Only keep the provider you actually use.
{{< /callout >}}

For OpenAI, `gpt-5.6-sol` is the flagship model. `gpt-5.6-terra` sits in the middle, and `gpt-5.6-luna` is the budget pick. You could use luna for `small_model` and sol for `model`:

```json {filename="opencode.json"}
"model": "openai/gpt-5.6-sol",
"small_model": "openai/gpt-5.6-luna"
```

You can also configure [variants](https://opencode.ai/docs/models/#variants) per model to control reasoning effort:

```json {filename="opencode.json"}
"provider": {
    "openai": {
        "models": {
            "gpt-5.6-sol": {
                "variants": {
                    "high": { "reasoningEffort": "high" },
                    "low": { "reasoningEffort": "low" }
                }
            }
        }
    }
}
```

Common OpenAI variants are `none`, `low`, `medium`, `high`, and `xhigh`. Anthropic ships with `high` and `max`. Without a variant override, the model uses its default.

## Polish the experience

A few extras that polish the developer experience. Add these to your `opencode.json`:

- **[Formatter](https://opencode.ai/docs/formatters/)** auto-formats code blocks in the AI's response. Removes the copy-paste-format cycle:

    ```json {filename="opencode.json"}
    "formatter": true
    ```

- **[LSP](https://opencode.ai/docs/lsp/#configure)** enables language servers for the project. The model gets real-time diagnostics as feedback, catching issues without you having to run lint manually. On large monorepos, startup latency increases. Toggle it off if the delay bothers you:

    ```json {filename="opencode.json"}
    "lsp": true
    ```

- **[Watcher](https://opencode.ai/docs/config/#watcher)** monitors file changes for auto-context refresh. Ignore the noisy directories so builds and dependency installs don't trigger re-analysis:

    ```json {filename="opencode.json"}
    "watcher": {
        "ignore": ["node_modules/**", ".git/**", "dist/**", "build/**", ".gradle/**"]
    }
    ```

- **[Command shortcuts](https://opencode.ai/docs/commands/)** save you from typing the same prompts every day. Each one has a name, a description, and a template. Type `/<name>` in the TUI and it runs, just like the built-in `/init`, `/undo`, or `/help`:

    ```json {filename="opencode.json"}
    "command": {
        "build": {
            "template": "Run ./gradlew assembleDebug and fix any compilation errors.",
            "description": "Build debug APK"
        },
        "test": {
            "template": "Run ./gradlew testDebug and show me which tests failed and why.",
            "description": "Run unit tests"
        },
        "lint": {
            "template": "Run ./gradlew lintDebug and fix all auto-fixable issues. Explain the rest.",
            "description": "Lint and fix"
        }
    }
    ```

    Type `/build` in the TUI and OpenCode runs that template.

## Final config file

Here is the full `~/.config/opencode/opencode.json`:

```json {filename="opencode.json"}
{
    "$schema": "https://opencode.ai/config.json",
    "compaction": {
        "auto": true,
        "prune": true,
        "reserved": 6400
    },
    "plugin": ["@tarquinen/opencode-dcp@latest"],
    "instructions": [
        "~/.config/opencode/rules/*.md"
    ],
    "permission": {
        "*": "allow",
        "bash": {
            "*": "ask",
            "git *": "allow",
            "grep *": "allow",
            "ls *": "allow",
            "./gradlew *": "allow"
        },
        "external_directory": {
            "~/.config/opencode/**": "allow"
        }
    },
    "model": "openai/gpt-5.6-sol",
    "small_model": "lmstudio/google/gemma-3n-e4b",
    "provider": {
        "lmstudio": {
            "npm": "@ai-sdk/openai-compatible",
            "name": "LM Studio (local)",
            "options": {
                "baseURL": "http://localhost:1234/v1"
            },
            "models": {
                "google/gemma-3n-e4b": {}
            }
        }
    },
    "formatter": true,
    "lsp": true,
    "command": {
        "build": {
            "template": "Run ./gradlew assembleDebug and fix any compilation errors.",
            "description": "Build debug APK"
        },
        "test": {
            "template": "Run ./gradlew testDebug and show me which tests failed and why.",
            "description": "Run unit tests"
        },
        "lint": {
            "template": "Run ./gradlew lintDebug and fix all auto-fixable issues. Explain the rest.",
            "description": "Lint and fix"
        }
    },
    "watcher": {
        "ignore": ["node_modules/**", ".git/**", "dist/**", "build/**", ".gradle/**"]
    }
}
```

{{< callout type="info" >}}
This config was tested against OpenCode 1.18.3. The API surface evolves. Check the [docs](https://opencode.ai/docs/) if a field errors.
{{< /callout >}}

That's it! Use the full config above as your starting point, tweak what doesn't fit, and you're good to go.
