---
title: "Complexity-Based Routing: Because Not Every Prompt Needs a Flagship"
date: "2026-09-06"
tags: ["llm", "litellm", "opencode", "cost-optimization"]
authors:
  - name: Nishant Srivastava
    link: /about/
---

![Banner](header.jpg)

<!--Short abstract goes here-->

I caught my coding agent paying flagship prices for a typo fix. LiteLLM's Auto Router v2 routes cheap prompts to cheap models and keeps the hard ones on the big guns. Here is how I set it up with OpenCode.

<!--more-->

## The Problem

Your coding agent sends every request to the same model. "Rename this variable" and "debug this race condition" cost the same. They shouldn't.

[LiteLLM's Auto Router v2](https://docs.litellm.ai/docs/proxy/auto_routing) classifies each prompt by complexity and routes it to a matching tier. Cheap requests go to cheap models. Hard requests go to the flagship.

![LiteLLM](sc_3.png)

{{< callout type="info" >}}
Auto Router v2 is in beta, and config keys can change between releases. I verified this setup on LiteLLM 1.101.0 and OpenCode 1.18.31.
{{< /callout >}}

LiteLLM shared [numbers from a live production deployment](https://docs.litellm.ai/blog/auto-router-production-savings): 450+ users, 272,876 requests, 7B tokens over four months.

- 51% saved. $12,249 on $23,985 of would-be flagship spend
- 95% of requests never needed the flagship tier

And on [8,619 graded benchmark prompts](https://docs.litellm.ai/blog/auto-router-cost-quality-benchmark):

- 97% of flagship quality at 40% lower cost
- 87% quality at 75% lower cost on general queries

That is more like it 🤘🏼

## The Router Config

Four tiers and one router entry, all served by [OpenCode Go](https://opencode.ai/docs/go). LiteLLM has no dedicated `opencode-go` provider yet, so each model uses the generic `openai/` prefix pointed at the OpenCode Go endpoint. Prices come from the [OpenCode Go pricing table](https://opencode.ai/docs/go#usage-limits):

```yaml
model_list:
  - model_name: cheap/mimo-v2.5
    litellm_params:
      model: openai/mimo-v2.5                          # OpenCode Go serves it on /chat/completions
      api_base: https://opencode.ai/zen/go/v1
      api_key: os.environ/OPENCODE_GO_API_KEY          # $0.14/$0.28 per 1M tokens

  - model_name: mid/longcat-2.0
    litellm_params:
      model: openai/longcat-2.0
      api_base: https://opencode.ai/zen/go/v1
      api_key: os.environ/OPENCODE_GO_API_KEY          # $0.30/$1.20 per 1M tokens

  - model_name: strong/kimi-k2.7-code
    litellm_params:
      model: openai/kimi-k2.7-code
      api_base: https://opencode.ai/zen/go/v1
      api_key: os.environ/OPENCODE_GO_API_KEY          # $0.95/$4.00 per 1M tokens

  - model_name: smart-router
    litellm_params:
      model: auto_router/complexity_router
      drop_params: true          # strip params the target model does not support
      complexity_router_config:
        tiers:
          SIMPLE:    cheap/mimo-v2.5
          MEDIUM:    mid/longcat-2.0
          COMPLEX:   strong/kimi-k2.7-code
          REASONING: strong/kimi-k2.7-code
        classifier_type: heuristic_first
        heuristic_first_max_tier: SIMPLE
        classifier_llm_config:
          model: cheap/mimo-v2.5          # fast first token, smallest bill; the classifier prompt is tiny
          timeout_ms: 5000
        classifier_fallback: heuristic    # if the LLM classifier fails, fall back to the free scorer
        complexity_router_default_model: mid/longcat-2.0
        keyword_tier_rules:
          - keywords: ["rename", "format", "comment", "typo", "whitespace", "lint"]
            tier: SIMPLE
          - keywords: ["refactor", "architecture", "race condition", "deadlock", "memory leak", "concurrency", "thread safety", "migration"]
            tier: REASONING
        session_affinity: false          # set true to pin a session to its first-turn model (preserves prompt cache)
        return_raw_model_name: true      # return the actual model name in the response body, not the alias

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  # Forward client x-* headers to the provider. The OpenCode plugin below
  # adds x-opencode-session; without this line the proxy strips it:
  # https://opencode.ai/docs/go/#where-can-i-use-it
  forward_client_headers_to_llm_api: true
```

Save this as `~/.config/litellm/config.yaml`. The LiteLLM Proxy picks it up in the next step.

## Run the Proxy

One command installs the [`lite` CLI](https://docs.litellm.ai/docs/proxy/management_cli) and the proxy runtime, proxy extras included:

```bash
uv tool install 'litellm[proxy]'
```

Export two keys:

```bash
export OPENCODE_GO_API_KEY=sk-your-opencode-go-key   # from opencode.ai/go
export LITELLM_MASTER_KEY=sk-your-master-key          # the key your clients use
```

The master key is a shared secret you invent. Any non-empty string works, the `sk-` prefix is just convention. This command prints a ready-to-paste export line:

```bash
# Output: 
#   export LITELLM_MASTER_KEY="sk-c14e1940069c5e689173ff5b2a7148d6edc83e338f3cbf85"

echo "export LITELLM_MASTER_KEY=\"sk-$(openssl rand -hex 24)\""
```

The command generates a new key every run, so pick one output and save it. The config reads it from the env var at startup, so the proxy refuses to start without it.

Start the proxy with the saved config:

```bash
litellm --config ~/.config/litellm/config.yaml
```

{{< details title="Click to expand: proxy startup output" closed="true" >}}

```sh
INFO:     Started server process [46797]
INFO:     Waiting for application startup.

   ██╗     ██╗████████╗███████╗██╗     ██╗     ███╗   ███╗
   ██║     ██║╚══██╔══╝██╔════╝██║     ██║     ████╗ ████║
   ██║     ██║   ██║   █████╗  ██║     ██║     ██╔████╔██║
   ██║     ██║   ██║   ██╔══╝  ██║     ██║     ██║╚██╔╝██║
   ███████╗██║   ██║   ███████╗███████╗███████╗██║ ╚═╝ ██║
   ╚══════╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝


#------------------------------------------------------------#
#                                                            #
#            'This product would be better if...'            #
#        https://github.com/BerriAI/litellm/issues/new       #
#                                                            #
#------------------------------------------------------------#

 Thank you for using LiteLLM! - Krrish & Ishaan



Give Feedback / Get Help: https://github.com/BerriAI/litellm/issues/new


LiteLLM: Proxy initialized with Config, Set models:
    cheap/mimo-v2.5
    mid/longcat-2.0
    strong/kimi-k2.7-code
    smart-router
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:4000 (Press CTRL+C to quit)
```

{{< /details >}}

The proxy listens on `http://localhost:4000`.

Quick check that the router works, piped through [jq](https://jqlang.github.io/jq/) so the response reads well in the terminal. Install jq first if you do not have it:

```bash
brew install jq
```

```bash
BODY='{
  "model": "smart-router",
  "messages": [
    {"role": "user", "content": "What does the -v flag do in grep?"}
  ]
}'

curl -s http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  | jq '{model, answer: .choices[0].message.content}'
```

On my run the router picked `mimo-v2.5`, the SIMPLE tier. Exactly what a grep question deserves. Every response also carries the `x-litellm-model-name` header, so you can see which tier served the request.

{{< details title="Click to expand: sample output" closed="true" >}}

```text
{
  "model": "mimo-v2.5",
  "answer": "In `grep`, the `-v` flag stands for \"invert match\" — it
             reverses the normal behavior of the command.

             Normally, `grep` prints lines that match the given
             pattern. With `-v`, `grep` prints lines that do NOT match
             the pattern.

             Example: suppose file.txt contains apple, banana, cherry,
             apricot. Running `grep -v \"apple\" file.txt` would output
             banana, cherry, apricot, because it skips any line
             containing \"apple\".

             Note: the longer option `--invert-match` does the same
             thing as `-v`."
}
```

{{< /details >}}

## Connect OpenCode

The `lite` CLI wraps coding agents and routes their traffic through your proxy. Point it at your key and launch OpenCode:

```bash
export LITELLM_PROXY_API_KEY="$LITELLM_MASTER_KEY"
lite opencode
```

The wrapper exports `OPENAI_BASE_URL` and `OPENAI_API_KEY` for you, checks the key against the proxy, then launches OpenCode.

{{< callout type="info" >}}
The defaults above assume your proxy runs at `http://localhost:4000`.

To change that:

```sh
export LITELLM_PROXY_URL="http://your-proxy:4000"
```

{{< /callout >}}

{{< callout type="warning" >}}
One catch: OpenCode reads its model list from config, not from the proxy. Add the router to `~/.config/opencode/opencode.json` so it shows up in `/models`:

```json opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "litellm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LiteLLM",
      "options": {
        "baseURL": "http://localhost:4000/v1",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "smart-router": { "name": "Smart Router" }
      }
    }
  }
}
```

{{< /callout >}}

Launch `lite opencode`. Inside OpenCode, run `/models` and select Smart Router under the LiteLLM provider. That is the `smart-router` alias, and every request now routes by tier. Done 🚀

![OpenCode Models](sc_1.png)

![OpenCode Smart Router](sc_2.png)

{{< callout type="info" >}}
OpenCode sends a `reasoningSummary` parameter that plain chat completions reject. The router entry handles it with `drop_params: true`. If you point OpenCode at a tier model directly, add `additional_drop_params: ["reasoningSummary"]` to that model's entry:

```yaml {hl_lines=[6]}
- model_name: cheap/mimo-v2.5
  litellm_params:
    model: openai/mimo-v2.5
    api_base: https://opencode.ai/zen/go/v1
    api_key: os.environ/OPENCODE_GO_API_KEY
    additional_drop_params: ["reasoningSummary"]
```

The [OpenCode integration guide](https://docs.litellm.ai/docs/tutorials/opencode_integration#dropping-opencode-specific-parameters) covers this and more.
{{< /callout >}}

### The Session Header

OpenCode Go wants `x-opencode-session` on every request, one stable id per conversation. It uses the id for provider routing and prompt caching. Get this wrong and every call fails with a `400`:

```text
litellm.BadRequestError: OpenAIException - Error from provider (Console Go): Request is missing 
x-opencode-session and cannot be routed efficiently.
```

The root cause is the provider name. OpenCode sends `x-opencode-session` only when the provider ID starts with `opencode`. My provider is named `litellm`, so OpenCode never sends the header, and OpenCode Go rejects the request with `MissingSessionID`. The proxy cannot forward a header that never arrived. Two changes fix it.

1. Make OpenCode send the header. Add a `chat.headers` plugin that injects `x-opencode-session` with the current session id. Save it as `~/.config/opencode/plugins/opencode-session-header.ts`:

   ```ts {filename="~/.config/opencode/plugins/opencode-session-header.ts"}
   import type { Plugin } from "@opencode-ai/plugin"

   // Injects x-opencode-session on every LLM request so OpenCode Go
   // gets a stable session id per conversation.
   const OpencodeSessionHeader: Plugin = async () => {
     return {
       "chat.headers": async (input, output) => {
         output.headers["x-opencode-session"] = input.sessionID
       },
     }
   }

   export default OpencodeSessionHeader
   export { OpencodeSessionHeader }
   ```

   The `chat.headers` hook runs on every request and merges the returned headers into the HTTP call to the provider. OpenCode loads global plugins at startup.

2. Make the proxy forward it. LiteLLM strips client headers by default. Add this line under `general_settings` in `config.yaml`:

   ```yaml {hl_lines=[2]}
   general_settings:
     forward_client_headers_to_llm_api: true
   ```

   With this line, the proxy passes the plugin's header through to the OpenCode Go backend. The [OpenCode Go docs](https://opencode.ai/docs/go) describe the header and its use for provider routing.

{{< callout type="warning" >}}
The proxy reads its config at startup, not per request. An edit to `config.yaml` while the proxy runs changes nothing. I burned time on this: the config had the right line, the proxy had been up for 3 days, and OpenCode Go kept rejecting the header. **Restart the proxy after any config change.**
{{< /callout >}}

### Silent Failures

Two LiteLLM internal calls do not inherit the client's headers. They go out without `x-opencode-session` and fail. Neither failure stops the proxy, so both are easy to miss.

1. **Background health checks.** The proxy probes each deployment on a timer. The probe carries no session header, so OpenCode Go returns `400 MissingSessionID` every 300 seconds. Disable the probe per model, then tell the proxy to skip the models you disabled:

   ```yaml
   - model_name: cheap/mimo-v2.5
     litellm_params:
       model: openai/mimo-v2.5
       api_base: https://opencode.ai/zen/go/v1
       api_key: os.environ/OPENCODE_GO_API_KEY
     model_info:
       disable_background_health_check: true

   general_settings:
     health_check_skip_disabled_background_models: true
   ```

   Repeat `model_info.disable_background_health_check: true` on every model entry pointed at the OpenCode Go endpoint, not just the one above. With `health_check_skip_disabled_background_models: true`, the proxy skips those disabled models in its health checks.

2. **The LLM classifier.** With `classifier_type: heuristic_first`, ambiguous prompts escalate to the LLM classifier. That call also leaves without the session header. It fails, the router silently falls back to the free heuristic scorer, and routing still works. A working router does not prove the classifier ran. To check, look for `cause=llm_classifier` on the routing decision line in the logs. If you only see `cause=heuristic`, the classifier never ran.

   Fix it with a dedicated classifier deployment that carries a static `x-opencode-session`:

   ```yaml
   - model_name: classifier/opencode-go
     litellm_params:
       model: openai/mimo-v2.5
       api_base: https://opencode.ai/zen/go/v1
       api_key: os.environ/OPENCODE_GO_API_KEY
       extra_headers:
         x-opencode-session: litellm-classifier
   ```

   Then point the [classifier](https://docs.litellm.ai/docs/proxy/auto_routing#classification) at that deployment:

   ```yaml
   classifier_llm_config:
     model: classifier/opencode-go
     timeout_ms: 5000
   ```

{{< callout type="warning" >}}
LiteLLM's config model allows extra fields, so it silently ignores unknown keys. A typo, or a key from a newer release than the one you installed, does not raise an error: the proxy starts clean and the feature simply does not run. Verify a feature by its behavior and its log lines, never by a clean startup.
{{< /callout >}}

## Picking a Classifier

The router needs to decide which tier a prompt belongs to. [Four classifiers in v2](https://docs.litellm.ai/docs/proxy/auto_routing#classification):

| Classifier | Cost | Latency | Notes |
| ----------- | ------ | --------- | ------- |
| `heuristic` | free | sub-ms | Weighted scorer, the default |
| [`trained_heuristic`](https://docs.litellm.ai/blog/heuristic-v2) | free | sub-ms | Calibrated model, better out of the box |
| `heuristic_first` | free for most traffic | sub-ms, LLM only when unsure | Recommended |
| `llm` | one small model call | 1-2s | Most accurate |

`heuristic_first` is the sweet spot. It runs the free local scorer first. Prompts that clearly land at or below `heuristic_first_max_tier` route with no LLM call. Ambiguous prompts escalate to the LLM classifier:

```yaml
classifier_type: heuristic_first
heuristic_first_max_tier: SIMPLE
classifier_llm_config:
  model: classifier/opencode-go  # dedicated deployment with a static session header
  timeout_ms: 5000
classifier_fallback: heuristic  # if the LLM classifier fails, fall back to the free scorer
```

`classifier_fallback` decides what happens when the LLM classifier fails or times out. The default falls back to the heuristic scorer. Set it to `default_model` to route to `complexity_router_default_model` instead. A classifier timeout is not fatal: the request routes anyway, so a slow classifier costs a little latency, not the request.

The LLM classifier call is tracked as `classifier_cost` and deducted from reported savings (v1.100+).

## Why It Saves Tokens

- **Tier selection.** Input tokens cost the same on any model. Output tokens on the cheap tier cost 5-10x less than the flagship. Most coding work does not need flagship reasoning.
- **Heuristic-first classification.** The free scorer handles most traffic with no LLM call. The LLM classifier only runs on ambiguous prompts, and its cost comes off the reported savings.
- **Context escalation**, on by default. If a simple question arrives deep into a long session and the chosen tier cannot hold the prompt, the router bumps it to a tier that fits. No failed calls. No retry tokens.
- **Session pinning** (`session_affinity: true`). A multi-turn session stays on one model. No prompt-cache invalidation from tier switching mid-conversation. The trade: the whole session inherits the first turn's tier.
- **Keyword rules**, hard overrides for known patterns. Multiple matches escalate to the highest matched tier, so rule order does not matter:

  ```yaml
  keyword_tier_rules:
    - keywords: ["rename", "format", "comment", "typo", "whitespace", "lint"]
      tier: SIMPLE
    - keywords: ["refactor", "architecture", "race condition", "deadlock", "memory leak", "concurrency", "thread safety", "migration"]
      tier: REASONING
  semantic_keyword_matching: true   # match paraphrases via embeddings, not just literal keywords
  embedding_model: voyage-3-5
  match_threshold: 0.5
  ```

## Stuck-Task Escalation

A cheap model can get stuck mid-task. It calls the same tool with the same arguments three times, or the same call keeps erroring, while the newest message reads like a harmless follow-up: "can you try a different approach?" Read alone, that turn classifies SIMPLE every time, so the router sends it right back to the model that was already failing.

[Stall escalation](https://docs.litellm.ai/blog/auto-router-stall-escalation) gives the router that judgment:

- It reads the assistant's own tool calls, not your messages. A task counts as stalled once the newest call repeats or errors at least `stall_escalation_repeat_threshold` times across the last `stall_escalation_window` calls
- Anchored on the newest call, so a task that already recovered does not keep escalating
- Reads both Anthropic `tool_use`/`tool_result` blocks (including `is_error`) and chat-completions `tool_calls`/`tool` messages
- Stateless. Detection reruns on every classified turn, so the bump lifts the moment the task looks unstuck

```yaml
stall_escalation_enabled: true
stall_escalation_window: 6
stall_escalation_repeat_threshold: 3
```

It cannot combine with `session_affinity: true` or `classification_mode: user_turn`. Both replay a held routing decision, so detection would never see the tool calls it needs.

To see it fire, send the same follow-up twice: once alone, once with 3 identical failing tool calls ahead of it. Alone it stays SIMPLE. With the history the router bumps one tier and tags the decision:

```text
tier=SIMPLE, signals=('short (8 tokens)', 'code (try)'), routed_model=cheap/mimo-v2.5
tier=MEDIUM, signals=('short (8 tokens)', 'code (try)', 'stall_escalation'), routed_model=mid/longcat-2.0
```

| Run | Tier | stall signal | Routed model |
| --- | --- | --- | --- |
| 3 identical failing tool calls, then the follow-up | MEDIUM | `stall_escalation` | mid/longcat-2.0 |
| The follow-up alone | SIMPLE | none | cheap/mimo-v2.5 |

## Tune Your Tiers

The production case study points both SIMPLE and MEDIUM at the cheapest model, and that is where most of the savings come from. A rough shape to aim for:

| Tier | Traffic share | Spend share |
| ------ | -------------- | ------------- |
| SIMPLE + MEDIUM | ~80% | ~20% |
| COMPLEX | ~15% | ~30% |
| REASONING | ~5% | ~50% |

Watch your proxy logs for a day, then adjust `tier_boundaries` if requests overshoot their tier.

- Default logs show tier fallbacks, classifier failures, and errors.
- `--detailed_debug` adds classifier decisions and full error tracebacks.

### Watch the Router Live

Here is a slice from my proxy. Watch the `selected model` lines: one request routes to `longcat-2.0`, the next to `mimo-v2.5`.

{{< details title="Click to expand: detailed_debug log sample" closed="true" >}}

```sh
❯ litellm --config ~/.config/litellm/config.yaml --detailed_debug | grep "selected model"
00:08:25 - LiteLLM:DEBUG: cost_calculator.py:1296 - selected model name for cost calculation: openai/longcat-2.0
00:08:30 - LiteLLM:DEBUG: cost_calculator.py:1296 - selected model name for cost calculation: openai/mimo-v2.5
```

{{< /details >}}

The raw `detailed_debug` output is mostly noise. I pipe it through `awk` to keep only the picked model and any failures:

```zsh {filename="~/.zshrc"}
litellm-autorouter-watch() {
  litellm --config ~/.config/litellm/config.yaml --detailed_debug 2>&1 \
    | awk '
      /selected model name/ {print $1, "→", $NF; fflush(); next}
      /Uvicorn running on/ {sub(/.*Uvicorn running on /, "Proxy URL: "); print; fflush(); next}
      /LiteLLM Proxy:ERROR:/ {print; fflush()}'
}
```

- `2>&1` sends the debug lines to `awk`
- picked models print as `time → model`
- the startup line becomes `Proxy URL: ...`, and failures print as-is

Run `litellm-autorouter-watch` in one terminal, OpenCode in another.

Here is the sample from above through `litellm-autorouter-watch`:

```text
Proxy URL: http://0.0.0.0:4000 (Press CTRL+C to quit)
00:08:25 → openai/longcat-2.0
00:08:30 → openai/mimo-v2.5
```

The classifier can fail without stopping the router. Here it did not answer within its timeout, so the router fell back to the free scorer and still routed the request:

```text
00:38:19 - LiteLLM Router:WARNING: complexity_router.py:1760 - ComplexityRouter: LLM classifier failed (), falling back to heuristic
00:38:19 - LiteLLM Router:INFO: complexity_router.py:3681 - ComplexityRouter: routing decision cause=heuristic_scorer, tier=SIMPLE, score=0.000, signals=(), routed_model=cheap/mimo-v2.5
```

`cause=heuristic_scorer` is the tell: the free scorer classified the request. The empty parentheses are verbatim; a timeout logs no detail.

## Find Models and Generate the Config

The config above pins three models by hand. [OpenCode Go](https://opencode.ai/docs/go) serves more than two dozen models, so I wrote a script to do the picking. It scrapes live pricing from the [OpenCode Go docs](https://opencode.ai/docs/go#usage-limits), cross-references the live models API, and groups the chat-completions models by output cost:

{{< details title="Click to expand: model grouping script and live output" closed="true" >}}

Save as `group_models.py` and run with `uv run` or plain `python3`:

```bash
uv run group_models.py                  # tier table
uv run group_models.py --format yaml    # generate the proxy config
uv run group_models.py --cheap-max 0.6 --mid-max 2.0 --strong-max 5.0
```

- `--cheap-max`, `--mid-max`, `--strong-max`: output cost ceilings per 1M tokens for the cheap, mid, and strong tiers (defaults 1.0 / 3.0 / 6.0)
- `--format table` prints grouped models with pricing, `--format yaml` prints a full proxy `model_list`

The script keeps only models that offer [Zero Data Retention](https://opencode.ai/docs/go#privacy) and that the `openai/` prefix can drive:

- Drops `grok-4.6` and `gpt-5.6-luna` (30-day retention) and the Muse Spark Contributor tiers (traffic used for training)
- Drops models not served on `/chat/completions`, the `/messages` and `/responses` [endpoints](https://opencode.ai/docs/go#endpoints)

Everything it emits is 0 days retention.

```python {filename="group_models.py"}
#!/usr/bin/env python3
"""Group OpenCode Go chat models by output cost and emit a LiteLLM router config."""
import argparse
import json
import urllib.request
from html.parser import HTMLParser
from typing import NamedTuple

MODELS_URL = "https://opencode.ai/zen/go/v1/models"
DOCS_URL = "https://opencode.ai/docs/go"
CHAT_ENDPOINT = "/chat/completions"
TIERS = ("cheap", "mid", "strong", "ultra")


class _Model(NamedTuple):
    model_id: str
    input_cost: float
    output_cost: float
    cache_cost: float


def _fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=10) as response:
        return response.read()


def _fetch_models():
    """Set of model IDs the OpenCode Go API currently serves."""
    return {model["id"] for model in json.loads(_fetch(MODELS_URL))["data"]}


class _TableParser(HTMLParser):
    """Collect HTML tables as a list of tables, each a list of cell-string rows."""

    def __init__(self):
        super().__init__()
        self._table_depth = 0
        self._row = None
        self._cell = None
        self.tables = []

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self._table_depth += 1
            self.tables.append([])
        elif tag == "tr" and self._table_depth:
            self._row = []
        elif tag in ("td", "th") and self._row is not None:
            self._cell = []

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self._cell is not None:
            self._row.append("".join(self._cell).strip())
            self._cell = None
        elif tag == "tr" and self._row is not None:
            if self._row:
                self.tables[-1].append(self._row)
            self._row = None
        elif tag == "table":
            self._table_depth -= 1

    def handle_data(self, data):
        if self._cell is not None:
            self._cell.append(data)


def _docs_tables():
    parser = _TableParser()
    parser.feed(_fetch(DOCS_URL).decode("utf-8"))
    return parser.tables


def _table(tables, required_columns):
    """Find a table by its header, so new sections cannot shift the index."""
    for table in tables:
        if table and all(column in table[0] for column in required_columns):
            return table[1:]
    raise SystemExit(f"Docs page has no table with columns: {required_columns}")


def _model_id(label):
    """Normalize a display name to a model ID and drop variants like '(Off-Peak)'."""
    return label.split("(")[0].strip().lower().replace(" ", "-")


def _price(cell):
    try:
        return float(cell.replace("$", "").replace(",", "").strip())
    except ValueError:
        return 0.0


def _load_pricing(tables):
    """model ID -> (input, output, cache). Keep the cheapest variant."""
    pricing = {}
    for model, input_cell, output_cell, cache_cell, *_ in _table(
        tables, ["Model", "Input", "Output", "Cached Read"]
    ):
        costs = (_price(input_cell), _price(output_cell), _price(cache_cell))
        model_id = _model_id(model)
        if model_id not in pricing or costs[1] < pricing[model_id][1]:
            pricing[model_id] = costs
    return pricing


def _load_endpoints(tables):
    """model ID -> serving endpoint."""
    return {
        model_id: endpoint
        for _name, model_id, endpoint, *_ in _table(tables, ["Model", "Model ID", "Endpoint"])
    }


def _load_unusable(tables, endpoints):
    """Model IDs the openai/ prefix cannot drive, or that are not Zero Data Retention."""
    unusable = {model_id for model_id, endpoint in endpoints.items() if CHAT_ENDPOINT not in endpoint}
    for model, training, retention, *_ in _table(
        tables, ["Model", "Model training", "Data retention"]
    ):
        if training != "Not used" or not retention.startswith("0 days"):
            unusable.add(_model_id(model))
    return unusable


def _load_catalog(tables):
    """model ID -> _Model, keeping only available chat models with ZDR and pricing."""
    pricing = _load_pricing(tables)
    endpoints = _load_endpoints(tables)
    unusable = _load_unusable(tables, endpoints)
    available = _fetch_models()

    catalog = {}
    for model_id in endpoints:
        if model_id in available and model_id in pricing and model_id not in unusable:
            input_cost, output_cost, cache_cost = pricing[model_id]
            catalog[model_id] = _Model(model_id, input_cost, output_cost, cache_cost)
    return catalog


def _tier(output_cost, thresholds):
    for name, ceiling in zip(TIERS, thresholds):
        if output_cost < ceiling:
            return name
    return TIERS[-1]


def _group(catalog, thresholds):
    """Group models into cost tiers, cheapest first within each tier."""
    groups = {tier: [] for tier in TIERS}
    for model in catalog.values():
        groups[_tier(model.output_cost, thresholds)].append(model)
    for models in groups.values():
        models.sort(key=lambda model: (model.output_cost, model.model_id))
    return groups


def _alias(groups, tier):
    """First model alias for a tier, or None when the tier is empty."""
    return f"{tier}/{groups[tier][0].model_id}" if groups[tier] else None


def _cheapest_model(groups):
    for tier in TIERS:
        if groups[tier]:
            return tier, groups[tier][0]
    raise SystemExit("No chat-completions models with pricing and ZDR found")


def _print_table(groups):
    for tier in TIERS:
        print(f"\n{tier.upper()} (output cost per 1M tokens)")
        print("-" * 55)
        for model in groups[tier]:
            print(
                f"  {model.model_id:<42} in=${model.input_cost:.2f}  "
                f"out=${model.output_cost:.2f}  cache=${model.cache_cost:.3f}"
            )


def _deployment_lines(alias, model_id, extra_headers=None):
    lines = [
        f"  - model_name: {alias}",
        "    litellm_params:",
        f"      model: openai/{model_id}",
        "      api_base: https://opencode.ai/zen/go/v1",
        "      api_key: os.environ/OPENCODE_GO_API_KEY",
    ]
    if extra_headers:
        lines.append("      extra_headers:")
        lines += [f"        {name}: {value}" for name, value in extra_headers.items()]
    lines += ["    model_info:", "      disable_background_health_check: true"]
    return lines


def _smart_router_lines(groups, default_model):
    lines = [
        "  - model_name: smart-router",
        "    litellm_params:",
        "      model: auto_router/complexity_router",
        "      drop_params: true",
        "      complexity_router_config:",
        "        tiers:",
    ]
    for tier, label in (("cheap", "SIMPLE"), ("mid", "MEDIUM"), ("strong", "COMPLEX")):
        alias = _alias(groups, tier)
        if alias:
            lines.append(f"          {label}: {alias}")
    lines.append(f"          REASONING: {_alias(groups, 'strong') or default_model}")
    lines += [
        "        classifier_type: heuristic_first",
        "        heuristic_first_max_tier: SIMPLE",
        "        classifier_llm_config:",
        "          model: classifier/opencode-go",
        "          timeout_ms: 2000",
        "        classifier_fallback: heuristic",
        f"        complexity_router_default_model: {default_model}",
        "        keyword_tier_rules:",
        '          - keywords: ["hi", "hello", "thanks"]',
        "            tier: SIMPLE",
        '          - keywords: ["kubernetes", "race condition"]',
        "            tier: REASONING",
        "        session_affinity: false",
        "        return_raw_model_name: true",
    ]
    return lines


def _router_config(groups):
    cheapest_tier, cheapest = _cheapest_model(groups)
    default_model = _alias(groups, "mid") or f"{cheapest_tier}/{cheapest.model_id}"

    lines = ["model_list:"]
    for tier in TIERS:
        for model in groups[tier]:
            lines += _deployment_lines(f"{tier}/{model.model_id}", model.model_id)
    lines.append("")
    lines += _deployment_lines(
        "classifier/opencode-go", cheapest.model_id, {"x-opencode-session": "litellm-classifier"}
    )
    lines.append("")
    lines += _smart_router_lines(groups, default_model)
    lines += [
        "",
        "general_settings:",
        "  forward_client_headers_to_llm_api: true",
        "  health_check_skip_disabled_background_models: true",
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Group OpenCode Go models by cost tier")
    parser.add_argument("--format", choices=["table", "yaml"], default="table")
    parser.add_argument("--cheap-max", type=float, default=1.0)
    parser.add_argument("--mid-max", type=float, default=3.0)
    parser.add_argument("--strong-max", type=float, default=6.0)
    args = parser.parse_args()

    catalog = _load_catalog(_docs_tables())
    groups = _group(catalog, (args.cheap_max, args.mid_max, args.strong_max))

    if args.format == "yaml":
        print(_router_config(groups))
    else:
        _print_table(groups)


if __name__ == "__main__":
    main()
```

**Live output** (2026-09-14, chat-completions and ZDR only):

```sh

CHEAP (output cost per 1M tokens)
-------------------------------------------------------
  mimo-v2.5                                  in=$0.14  out=$0.28  cache=$0.003
  glm-5.3-flash                              in=$0.15  out=$0.50  cache=$0.030
  hy3                                        in=$0.14  out=$0.58  cache=$0.035
  deepseek-v4-flash                          in=$0.15  out=$0.60  cache=$0.003
  deepseek-v4-flash-vision-exp               in=$0.15  out=$0.60  cache=$0.003
  deepseek-v4.1-flash                        in=$0.15  out=$0.60  cache=$0.003
  mimo-v2.5-pro                              in=$0.43  out=$0.87  cache=$0.004

MID (output cost per 1M tokens)
-------------------------------------------------------
  longcat-2.0                                in=$0.30  out=$1.20  cache=$0.006
  deepseek-v4-pro                            in=$0.66  out=$1.98  cache=$0.022
  hy4-preview                                in=$0.83  out=$2.50  cache=$0.042

STRONG (output cost per 1M tokens)
-------------------------------------------------------
  kimi-k2.6                                  in=$0.95  out=$4.00  cache=$0.160
  kimi-k2.7-code                             in=$0.95  out=$4.00  cache=$0.190
  glm-5.1                                    in=$1.40  out=$4.40  cache=$0.260
  glm-5.2                                    in=$1.40  out=$4.40  cache=$0.260
  glm-5.3                                    in=$1.40  out=$4.40  cache=$0.260

ULTRA (output cost per 1M tokens)
-------------------------------------------------------
  kimi-k3                                    in=$3.00  out=$15.00  cache=$0.300
```

{{< /details >}}

## Bottom Line

Most agent requests are not hard. Do not pay flagship pricing for easy work. A four-tier router with a free classifier cut a real bill in half in production. Point your agent at one name.

Done! Let the router decide and watch the bill shrink. Share the blog post if you like it! 😎
