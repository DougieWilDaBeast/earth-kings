# 15 — ChatGPT Go and Perplexity Pro: what they can do for us

**Inferred**, waits on Will: every proposal below is a recommendation until he answers.

Will, 2026-10-23 18:43 and 18:52: "it's a pure financial decision. We have this opportunity and it's
for free. Figure out how you can use it." Setup only; nothing new is built (D383), and call CG's
Steam and outside-assets decisions are separate. Recorded as [D427](../06-decisions.md), agenda row 326. The same write-up is in the project
files under `reviews/outside-assets/2026-10-23-chatgpt-go-plan.md`.

## The short answer

- **ChatGPT Go gives us one useful thing, maybe: a second pair of eyes on every pull request.**
  Codex code review reads each PR against `AGENTS.md` and comments on serious bugs. Whether Go
  has it is not clear from OpenAI's pages (they list automatic review under Plus), but Will's own
  Go settings show a **Code Review** page, so a two-minute check settles it.
- **ChatGPT Go should not write code on the repo.** Go's Codex is "for lightweight coding tasks",
  on the smaller model, in the desktop app only, with no cloud tasks. It would duplicate the Claude
  threads with a weaker model and add a second builder to reconcile.
- **Perplexity Pro gives us two useful things:** a question box loaded with the game's docs that
  Will and Ewan can ask on their phones without waking a thread, and an independent second opinion
  on the research where being wrong costs money (Steam, licences, tax). Everything else it does is
  what the threads already do.

## Correction to what the coordinator said earlier

Earlier Will was told Codex is Plus/Pro only. That was wrong. As of today:

| | Free / **Go** ($8) | Plus ($20) and up |
| --- | --- | --- |
| Codex at all | **Yes**, "for lightweight coding tasks" | Yes |
| Model | GPT-6 Luna at standard speed, in the desktop app, "subject to rollout" | GPT-6.1 Sol and GPT-6 Luna |
| Where it runs | Desktop app on a computer (works on your own copy of the repo) | Web, CLI, IDE, iOS, desktop |
| Cloud tasks (hand it an issue from the phone, it opens a PR) | **No** | Yes |
| Automatic code review on GitHub PRs | **Not listed for Go**, listed under Plus as a "cloud-based integration" | Yes |
| Usage limits | Not published for Go | Plus: per five-hour window, shared between local and cloud |

Sources: OpenAI's Codex pricing page (learn.chatgpt.com/docs/pricing, read 2026-10-23), the Codex
GitHub code-review page (learn.chatgpt.com/docs/third-party/github), OpenAI's help article "Using
Codex with your ChatGPT plan" (search summary; the page itself refused the fetch). The gap between
"not listed for Go" and the Code Review page in Will's settings is why step 1 below is a check.

## Part 1. ChatGPT Go: Codex code review on our PRs

### Why it is worth two minutes

Every PR here is written by Claude and merged by auto-merge once CI is green. Nobody but CI reads
the diff. A reviewer from a different model family is the cheapest independent check we can get.
By default Codex only flags P0 and P1 problems (real bugs, broken rules), so it should be quiet.

### Setup, on the phone (Brave) or the PC browser

1. Open **chatgpt.com → Settings → Coding → Code Review** (the page in Will's screenshot).
2. If it shows an **Upgrade** prompt or says it needs Plus: stop here. Go does not include it.
   Skip to Part 2. (Not worth $12 a month more for this alone; see the stop rule.)
3. If it offers to connect GitHub: tap **Connect GitHub**, sign in as **DougieWilDaBeast**, and
   when GitHub asks which repositories, pick **Only select repositories → earth-kings**. Not "All".
4. Back on the Code Review page, pick **dougiewildabeast/earth-kings** and turn on
   **Automatic review** (under Review code). If there is a **Review trigger**, choose "when a PR
   is opened" (not "every push", which would review each fix again).
5. Tell the coordinator it is on. The next PR any thread opens should get a comment from
   `chatgpt-codex-connector` within a few minutes.

To turn it off: same page, Automatic review off; or GitHub → Settings → Applications → ChatGPT
Codex → Configure → remove the repo.

### Advisory, not a required check

Make it **advisory**. It posts a review comment, not a pass/fail check, so it cannot gate a merge
without changing branch protection, and our PRs merge about seven minutes after CI starts. If it
were required, every PR would wait on OpenAI's queue and its usage limit, and a slow or exhausted
day would stall the whole pipeline.

How its comments get handled:
- **Lands before the merge:** the thread that owns the PR is already watching it, gets the comment
  like any review, and fixes it or replies why not (that is already the rule for reviews).
- **Lands after the merge:** once a week (or when the coordinator asks), a thread reads Codex
  comments on merged PRs and opens one issue per real finding, labelled `codex-review`.

`AGENTS.md` gets a **Code Review Rules** section (Codex reads the nearest `AGENTS.md`), so it
checks our own rules: content in `data/`, `EventBus` between systems, docs in the same PR, a
decision entry for anything settled, quotes never edited, nothing **Inferred** written as settled,
no secrets. That is the one repo change, in a docs-only PR.

### What not to do with ChatGPT Go

- **Don't let it build.** No Codex coding on the repo, desktop app or otherwise. Go has no cloud
  tasks, so it would mean a copy of the repo on the PC, Godot installed for the suites, and Will
  steering it: that is a coder's job and a second builder on main, which is the reconciliation cost
  we already pay when Will's other Claude account jumps main. If Will ever upgrades to Plus, cloud
  tasks could take small board issues one at a time (branch `codex/…`, label `codex`, pulled in by
  a thread like Ewan's PRs), but only after play-test 9 and only as a fresh decision.
- **Don't click "Fix" or "Create PR" on its review comments.** A thread fixes findings, so the
  docs and decision numbers stay right.
- **No secrets in prompts or comments:** no itch API key, butler token, keystore password,
  PixelLab key. They never go into ChatGPT or Perplexity.
- **Don't connect "All repositories"** or give it more than the one repo.

## Part 2. Perplexity Pro

What Pro has today (third-party guides, which disagree; check in the app): unlimited Pro searches,
Research (deep research) and Labs runs per month, a choice of models, file uploads, **Projects**
(the new name for Spaces since late July 2026) with shared files and instructions, connectors
(Google Drive, GitHub and others, depending on rollout), the Comet browser, image generation. API
credit: older guides say $5 a month; newer ones say Pro now gets a one-off bonus that only pays for
Perplexity's own agent. Either way, nothing here needs it.

### Use 1. An "Earth Kings" Project to ask questions in (★)

What it is for: Will or Ewan on a phone asking "what did we decide about hunger on the floor?",
"what's left before Steam?", "what's Ewan's list of open questions?" and getting an answer with the
doc it came from, without starting a thread or using Claude's usage.

Setup on the phone (Perplexity app) or perplexity.ai:
1. **Projects → New project**, name it **Earth Kings**.
2. Instructions (paste): "You answer questions about the game Earth Kings from the attached files
   only. Quote the file and the decision number (D…) you used. If the files don't say, say so; never
   guess. You never settle a design question: if something is open, say it is open and who decides."
3. Files: try the **GitHub connector** first (Settings → Connectors → GitHub, only the earth-kings
   repo), so it reads the live docs. If the connector isn't offered, upload these instead (the
   coordinator can put a fresh bundle in /mnt/project-files/ on request): `docs/00-index.md`,
   `docs/05-roadmap.md`, `docs/28-the-first-hour.md`, `docs/30-questions-for-the-founders.md`,
   `docs/06-decisions.md`, `docs/worldbuilding/answers.md`, the onboarding pack.
4. Invite Ewan to the Project (Share → invite by email), if Pro lets you share with a free account.

Limits, said plainly: uploaded files go stale the day they are uploaded (re-upload weekly or use
the connector); it is a reader, not a source; an answer from it is never a founder's answer and
never goes into the ledger. If a question matters, ask the coordinator to check it.

### Use 2. A second opinion where being wrong costs money (★)

The threads already do web research. Perplexity is worth running **as well**, not instead, when a
wrong answer costs money or a rule breach: Steam's AI-disclosure and refund rules, a licence's
small print (CC-BY attribution, a paid pack's terms), Steamworks fees and tax forms, age ratings.
How: Will (or the coordinator, by asking Will) runs **Research** with the question, then pastes the
share link into the project chat. The thread compares it with its own sources and says where they
differ. Expect this a few times a month at most.

### What is just duplication (skip)

- General web research: the threads already search.
- Labs pages, reports and dashboards: the threads make those as artifacts.
- Comet browser: nothing for it to do here.
- The API credit: no thread needs a search API.
- Image generation: **never for game art.** Only `dougie` makes art, in PixelLab, and every
  AI-made asset must be traced and disclosed ([22](../22-asset-provenance.md), [D426](../06-decisions.md)). Mixing another generator in muddies
  that record.

## The one-week trial (24 to 31 October)

| Tool | Measure | Keep if | Stop if |
| --- | --- | --- | --- |
| Codex review | Each Codex comment marked real or noise by the thread that reads it; count of real findings the suites and soak missed; how many landed before merge | At least one real finding the suites missed, and fewer than one in three comments noise | Not on Go; or zero real findings; or more noise than signal; or it slows merges |
| Perplexity Project | Questions Will and Ewan asked; answers that matched the docs when checked | Used at least three times and right when checked | Not used, or wrong more than once on something the docs answer |
| Perplexity research | Times it changed or confirmed a money/legal call | Any one | Never asked for (fine: it costs nothing to leave unused) |

On 31 October the coordinator posts one line per tool: keep or drop, with the counts. Dropping
Codex means turning off Automatic review; the `AGENTS.md` section can stay (it costs nothing).

## Decisions (letter for the coordinator to assign)

1. ★ **Turn on Codex code review if Go has it** (Will's two-minute check, step 1), automatic on
   new PRs, only the earth-kings repo, **advisory, not a required check**.
2. ★ **No Codex coding on the repo** on Go; cloud tasks only ever as a new decision after
   play-test 9 and a Plus upgrade.
3. ★ **A Perplexity "Earth Kings" Project** for Will and Ewan to ask questions in, GitHub
   connector if offered, read-only, never a source for the ledger.
4. ★ **Perplexity Research as a second opinion** on money and legal calls only, pasted back to
   the thread.
5. ★ **Skip** Comet, the API credit, Labs and image generation (never for game art).
6. ★ **One-week trial to 31 October**, measured as above, keep or drop on the 31st.
