---
title: "I hate writing commit messages. So I built Commit Pilot."
date: "2026-06-18"
authors:
  - name: Nishant Srivastava
    link: /about/
tags: ["local-ai", "git"]
---

![Banner](header.webp)

<!--Short abstract goes here-->

You know how it goes. "fix stuff" in the git log. Again. Commit Pilot runs locally, reads your diff, and writes conventional commits. Pick your LLM provider. No data leaves your machine.

<!--more-->

I hate writing git commit messages. Always have.

"fix stuff", "wip", "changes". That's what my git log looks like. I tell myself I'll clean it up later. I never do.

This got me thinking. Local LLMs have gotten really good over the last few months. Gemma, Qwen, all of them. They can read code, understand context, and write coherent text. What if they could write my commits for me?

So I built [Commit Pilot](https://nisrulz.com/commit-pilot/).

It reads your unstaged changes, groups related files, and writes conventional commit messages. LMStudio by default. Works with Ollama and any OpenAI-compatible API too.

Local first. Your code never leaves your machine. Zero telemetry. No tracking, no callbacks, no data collection.

## Install

One command:

```bash
curl -sfL https://github.com/nisrulz/commit-pilot/releases/latest/download/install.sh | sh
```

> Restart your terminal or open a new terminal tab right after to load everything in path.

## Get up to speed

You need an LLM provider running. The defaults point to LMStudio at `http://localhost:1234/v1` with the `gemma-4-e2b-it-qat` model. Just download the model in LMStudio and run:

```bash
commit-pilot
```

Using Ollama or OpenAI instead? Set these env vars:

```bash
OPENAI_PROVIDER=ollama OPENAI_MODEL=gemma4:e2b-it-qat commit-pilot
OPENAI_PROVIDER=openai OPENAI_API_KEY=sk-... commit-pilot
```

That's it. One command. Clean commits that actually say what they changed.

For details, check the docs on [GitHub](https://github.com/nisrulz/commit-pilot/blob/main/README.md#quick-start).

That's all for this time. Your git log deserves better 🤝.
