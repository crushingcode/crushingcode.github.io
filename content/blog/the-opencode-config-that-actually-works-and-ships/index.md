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
    "permission": "allow",
    "maxContextLimit": "70%",
    "minContextLimit": "35%",
    "protectUserMessages": true,
    "nudgeForce": "strong"
  },
  "turnProtection": {
    "enabled": true,
    "turns": 3
  },
  "strategies": {
    "purgeErrors": { "turns": 3 }
  }
}
```

The fields that matter most:

- **`compress`**
  - **`permission: "allow"`** lets DCP compress silently in the background. Switch to `"ask"` if you want to approve each pass.
  - **`maxContextLimit: "70%"`** starts the nudge while you still have headroom. You won't crawl to 99% and run dry.
  - **`minContextLimit: "35%"`** switches the reminders off once you fall below it. No nagging when you have space.
  - **`protectUserMessages: true`** keeps your prompts intact through compression. Paste a giant log and it stays, never trimmed.
  - **`nudgeForce: "strong"`** tells the model to compress more after you reply.
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

OpenCode [allows most tools by default](https://opencode.ai/docs/permissions/). A few guards like `external_directory` and `doom_loop` ask first instead. For `bash`, you only need a few rules: let the normal commands through and catch the dangerous ones.

```json {filename="opencode.json"}
"permission": {
    "read": {
        "**/.env*": "deny",
        "**/*.key": "deny"
    },
    "edit": {
        "**/.env*": "deny",
        "**/.ssh/**": "deny"
    },
    "bash": {
        "rm *": "deny",
        "sudo *": "deny",
        "git push --force*": "deny",
        "git push*": "ask",
        "curl*": "ask",
        "wget*": "ask"
    },
    "external_directory": {
        "~/.config/opencode/memory/**": "allow"
    }
}
```

- **`read`** and **`edit`** run by default, so you only list what to block. Think secrets and SSH keys.
- **`bash`**
  - **`"rm *": "deny"`** and **`"sudo *": "deny"`** stop destructive commands outright.
  - **`"git push --force*": "deny"`** blocks forced pushes. Put it before **`"git push*": "ask"`** so force stays blocked while normal pushes ask you.
  - **`"curl*": "ask"`** and **`"wget*": "ask"`** ask before any network call.
- **`external_directory`** asks by default, so I allow `~/.config/opencode/memory/**`. That lets the agent use your memory files without pausing to ask.

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
        "read": {
            "**/.env*": "deny",
            "**/local.properties": "deny",
            "**/secrets.local*": "deny",
            "**/*.pem": "deny",
            "**/*.key": "deny",
            "**/*.p12": "deny",
            "**/*.jks": "deny",
            "**/*.p8": "deny",
            "**/*.pgp": "deny",
            "**/*.gpg": "deny",
            "**/*.asc": "deny",
            "**/*.crt": "deny",
            "**/*.cer": "deny",
            "**/*.cert": "deny",
            "**/key.properties": "deny",
            "**/keystore*": "deny",
            "**/credentials*": "deny",
            "**/*credentials*.json": "deny",
            "**/*cred*.json": "deny",
            "**/service-account*": "deny",
            "**/.netrc": "deny",
            "**/.ssh/**": "deny",
            "**/id_*": "deny",
            "**/.aws/**": "deny",
            "**/.gcp/**": "deny",
            "**/.azure/**": "deny",
            "**/.kube/**": "deny",
            "**/.npmrc": "deny",
            "**/.yarnrc*": "deny",
            "**/.gem/credentials": "deny",
            "**/.git-credentials": "deny",
            "**/.docker/config.json": "deny",
            "**/google-services.json": "deny",
            "**/GoogleService-Info.plist": "deny",
            "**/sentry*.properties": "deny",
            "**/secret*": "deny",
            "**/Secret*": "deny",
            "**/*token*": "deny",
            "**/*.token": "deny",
            "**/oauth*": "deny",
            "**/database.yml": "deny",
            "**/*keychain*": "deny",
            "**/.zsh_history": "deny",
            "**/.bash_history": "deny",
            "**/.config/gh/hosts.yml": "deny",
            "**/.gnupg/**": "deny",
            "**/.envrc": "deny",
            "**/.pgpass": "deny",
            "**/*.pfx": "deny"
        },
        "edit": {
            "**/.ssh/**": "deny",
            "**/.aws/**": "deny",
            "**/.gcp/**": "deny",
            "**/.azure/**": "deny",
            "**/.kube/**": "deny",
            "**/.gnupg/**": "deny",
            "**/.env*": "deny",
            "**/id_*": "deny",
            "**/*.pem": "deny",
            "**/*.key": "deny",
            "**/.zshrc": "deny",
            "**/.bashrc": "deny",
            "**/.zprofile": "deny",
            "**/.bash_profile": "deny",
            "**/.profile": "deny",
            "**/.zsh_history": "deny",
            "**/.bash_history": "deny",
            "**/.gitconfig": "deny"
        },
        "external_directory": {
            "~/.config/opencode/memory/**": "allow"
        },
        "bash": {
            "rm *": "deny",
            "rmdir *": "deny",
            "unlink *": "deny",
            "shred *": "deny",
            "mkfs *": "deny",
            "fdisk *": "deny",
            "dd *": "deny",
            "sudo *": "deny",
            "su *": "deny",
            "nc *": "deny",
            "git push --force*": "deny",
            "git push*": "ask",
            "curl*": "ask",
            "wget*": "ask"
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

The `permission` block only lists `deny` and `ask` rules. That is because `read`, `edit`, and most tools already allow by default in OpenCode. `external_directory` is the odd one out: it asks by default, so I allow `~/.config/opencode/memory/**` to let the agent read and write your memory files without a prompt.

{{< callout type="info" >}}
This config was tested against OpenCode 1.18.3. The API surface evolves. Check the [docs](https://opencode.ai/docs/) if a field errors.
{{< /callout >}}

That's it! Use the full config above as your starting point, tweak what doesn't fit, and you're good to go.
