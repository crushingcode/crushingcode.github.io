---
title: "Faster at What, Exactly?"
date: "2026-11-20"
authors:
  - name: Nishant Srivastava
    link: /about/
tags: ["ai-engineering", "engineering-culture"]
---

![Banner](header.webp)

<!--Short abstract goes here-->

Companies are racing to be AI native, paying for tokens and cutting headcount, while the release still takes six weeks. The code got faster. Nothing else did.

<!--more-->

Every conversation about a slow release ends the same way. Flaky tests, manual QA, three approvals before a deploy. Then someone in a meeting says it.

> "Why don't you just use Codex?"

Fellow engineers tell me this line shows up everywhere. Any friction gets the same answer: use AI, it'll be faster.

**Faster at What, Exactly?**

Ask that out loud and people pause. The honest answer is the typing, the part where someone sits down and writes the feature. That part did get faster. I can scaffold a screen or wire up a data layer in an afternoon that used to cost a week. Nobody's arguing with that.

## Everyone is going AI native

Meta [tied AI usage to performance reviews](https://www.businessinsider.com/meta-ai-employee-performance-review-overhaul-2025-11), then [stopped counting tokens](https://timesofindia.indiatimes.com/technology/tech-news/months-after-meta-made-ai-tools-mandatory-for-employees-company-execs-tell-engineers-performance-reviews-will-not-count-ai-use-and-ask-managers-to-look-at/articleshow/133731983.cms) once people chased the number. JPMorgan [ranks engineers on a Copilot dashboard](https://www.businessinsider.com/jpmorgan-track-software-engineers-ai-use-dashboards-2026-4). Amazon [wants retail teams shipping three times faster](https://www.businessinsider.com/amazon-tracks-ai-use-engineers-internal-friction-2026-4). Coinbase [gave engineers a week to learn the tools](https://fortune.com/2025/08/25/coinbase-ceo-brian-armstrong-ai-coding-assistants-mandate-tech/). Shopify [won't approve a hire until a team proves AI can't do it](https://www.theverge.com/news/644943/shopify-ceo-memo-ai-hires-job).

## The 20% number

Every one of those programs points at the writing. The usual line is that coding is 20% of an engineer's job. A study from Microsoft Research [asked engineers how their week breaks down](https://www.microsoft.com/en-us/research/wp-content/uploads/2024/11/Time-Warp-Developer-Productivity-Study.pdf). Coding was about a tenth of it, less than meetings. The 20% was what they wanted, not what they got. So the number everyone plans around is generous.

But the code was never the whole job. The other 80% is meetings, answering the same question for the third time, chasing a decision from someone who'd rather not make it. It's two teams agreeing where the boundary sits. The security review asking what happens when a token leaks. QA finding the edge case nobody wrote down. Picking the deploy window where the fewest people get woken up at 2 am.

The agent doesn't sit in the standup. It doesn't get pinged at 7 pm. It doesn't walk into a room with two people who disagree and come out with a decision.

## The typing got faster, the release did not

One [review of two years of engineering data](https://pages.faros.ai/hubfs/AI_Engineering_Report_2026_The_Acceleration_Whiplash_Faros.pdf) found more code, more bugs, review queues stretching out, more PRs merging with nobody looking. A [look at hundreds of millions of code changes](https://www.gitclear.com/the_ai_code_quality_maintainability_gap) found copy paste replacing refactoring. DORA's [survey of the industry](https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report) had almost everyone using AI, most feeling faster, and stability worse anyway. METR [had experienced developers slower with AI](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) while swearing they were faster. [Their follow-up](https://metr.org/blog/2026-02-24-uplift-update/) softened it. Fair. The writing did get faster. It still wasn't the queue.

## The generalist problem

Companies are pushing engineers to become generalists, because an agent makes any domain look reachable. Backend shipping frontend, mobile touching infra, everyone reviewing everything. You end up with a team that is fine at ten things and expert at none. Fine is not what quality is built on.

Contribution is not ownership. The owner is the person who tells stakeholders what changed, what it breaks, and when it ships. An agent can generate the change. It cannot sit in that meeting. And being able to contribute does not transfer the reasons the code looks the way it does. The security review asks about the token that leaks, not the diff. Maintainability is what the next person needs a year later, and the contributor has moved on by then.

Then the PR lands in a repo that was never set up for this. No agent instructions, no conventions the model can read, boundaries that only make sense if you lived in the code for a year. The owners leave far more comments than they would on a normal PR, because the change does not fit anything around it. That part is fixable, but it takes months. Companies want the result this quarter.

## The bill nobody reads

There's a third cost nobody puts on a slide. Tokens. Gartner [expects coding agent spend to pass an average developer's salary by 2028](https://www.gartner.com/en/newsroom/press-releases/2026-06-24-gartner-predicts-ai-coding-costs-will-surpass-average-developer-salary-by-2028-as-token-consumption-surges), and the heaviest users already bill more in a month than a junior engineer earns. Microsoft will spend about $170 billion this year, most of it on AI. Nobody holds a meeting about the token line.

The layoffs get the press release. Klarna [made AI the face of cutting support staff](https://www.fastcompany.com/91571824/the-great-ai-layoff-is-turning-into-the-great-ai-rehire), then hired people back when quality dropped. Ford did the same with quality engineers. Microsoft offered buyouts to 60,000 people in October.

Then Outlook went down this week and stayed down for more than a day. Microsoft says the cuts had nothing to do with it. Maybe. But the people who answer the pager are [down by a quarter since 2022](https://workforce.ai/headcount/microsoft-email-outage-who-is-on-call), and the M365 engineers are down by 40%. Nobody will ever prove the reductions caused the outage, but the [tribal knowledge that walked out the door](https://www.wired.com/story/the-microsoft-outage-is-a-warning-for-the-world/) would have helped while it was broken. A thin bench does not take a server down. It decides how long the server stays down.

Pay for the new thing, cut the thing that keeps the old thing alive, and find out in production which one was load-bearing.

## The bottleneck moved

So the bottleneck just moved. Companies sped up the part that was easiest to measure, left the rest where it was, then act surprised when the release still takes six weeks, or when production goes down and nobody left knows how to bring it back.

## What would actually work

None of this is complicated, which is probably why nobody does it. If I ran one of these programs, I'd keep the dashboards and change the questions.

Measure the flow, not the adoption. Lead time, time to first review, change failure rate, rework, incidents. If those move, the program is working. If they don't, the dashboard is just a count of people who opened the tool.

Fix the repo before scaling the agent. Clear boundaries, conventions written down, tests that fail for the right reason, CI that people trust. Most of ["AI ready"](/blog/upgrading-repositories-for-ai-agents-a-practical-guide/) is what good engineering already meant. It takes quarters, and it is the one thing that makes review cheaper instead of heavier.

Keep domain owners. Let agents widen what one person can attempt, but do not pretend the reviewer's trust problem went away. Cross-domain PRs should come with the owner attached, as a pair or a co-author, not dropped in a queue for someone who has never seen that code. Smaller batches help more than any tool here.

Budget tokens per repo, not per engineer. Most of the bill is the model reading your code, so a tangled codebase costs more to work in.

Be careful with the layoffs. You are not trading salary for tokens, you are trading salary for incident duration and lost context.

For an individual, the move is the same. Be the person who understands the system, can verify the change, and owns the outcome. Generation speed is no longer scarce. Judgment is.

Next time someone asks why you don't throw a coding agent at it, ask them what they actually want faster. If it's the code, sure, hand it over. If it's the delivery, the code was never the slow part.
