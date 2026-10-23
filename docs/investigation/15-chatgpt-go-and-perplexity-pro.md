# 15 — ChatGPT Go and Perplexity Pro: what they can do for us

**Investigation, no decision taken** (Will, 2026-10-23, [D428](../06-decisions.md)). Nothing below is set up or built, and the `AGENTS.md` review rules it mentions were taken out again.

Will, 2026-10-23 18:43 and 18:52: "it's a pure financial decision. We have this opportunity and it's
for free. Figure out how you can use it." Setup only; nothing new is built (D383), and call CG's
Steam and outside-assets decisions are separate. Recorded as [D427](../06-decisions.md), agenda row 326. The same write-up is in the project
files under `reviews/outside-assets/2026-10-23-chatgpt-go-plan.md`.

## The rule this plan is built on

Will, 18:55: no plan where Will copies from one window to another. So **GitHub is the bus.** Every
tool here writes into the repo (a PR comment, an issue comment), and the Claude threads already
read the repo. Will sets each thing up once, then never carries anything. Each route is marked by
how much of Will's hands it needs:

| Route | Will's hands | What moves, with no one carrying it |
| --- | --- | --- |
| Codex reviews every new PR | **One-time** (turn it on, 2 min) | Codex comments on the PR; the thread that owns the PR is already watching and answers it |
| Threads ask Codex for a second look themselves | **Zero** after setup | A thread comments `@codex review` on its own PR when the change is risky |
| Weekly sweep of late Codex comments | **Zero** | A scheduled workflow turns Codex comments on already-merged PRs into issues labelled `codex-review` |
| Perplexity research for the threads | **One-time** (make an API key, paste it into a repo secret, 3 min) | A thread opens an issue labelled `research`; a workflow sends it to Perplexity's API and posts the cited answer back as a comment; the thread reads it |
| Perplexity Project reading the live repo | **One-time** (connect GitHub in Perplexity) | The question box reads the docs from GitHub, so nothing is ever re-uploaded |
| ~~Will runs Research and pastes the link~~ | Ongoing | Dropped: that is the courier job |
| ~~Re-uploading docs to a Project weekly~~ | Ongoing | Dropped: if the GitHub connector isn't offered, the Project goes, not the rule |
| ~~Comet browser automations~~ | Ongoing (Will's browser must be open) | Dropped |

## The short answer

- **ChatGPT Go gives us one useful thing, maybe: a second pair of eyes on every pull request.**
  Codex code review reads each PR against `AGENTS.md` and comments on serious bugs. Whether Go
  has it is not clear from OpenAI's pages (they list automatic review under Plus), but Will's own
  Go settings show a **Code Review** page, so a two-minute check settles it.
- **ChatGPT Go should not write code on the repo.** Go's Codex is "for lightweight coding tasks",
  on the smaller model, in the desktop app only, with no cloud tasks. It would duplicate the Claude
  threads with a weaker model and add a second builder to reconcile.
- **Perplexity Pro gives us two useful things:** an independent second opinion on research where
  being wrong costs money (Steam, licences, tax), which the threads can ask for themselves through
  its API, and a question box that reads the docs live from GitHub for Will and Ewan to ask on
  their phones. Everything else it does is what the threads already do.

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
5. That's all. The next PR any thread opens should get a comment from
   `chatgpt-codex-connector` within a few minutes; the coordinator sees that on GitHub, so Will
   doesn't need to report it.

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
- **Lands after the merge:** a small scheduled workflow (`.github/workflows/codex-sweep.yml`,
  Mondays, built on Will's yes) finds Codex comments on PRs that had already merged and opens one
  issue per comment, labelled `codex-review`. The issue lands in the inbox like any other; the
  coordinator's next status shows it. Nobody carries it.
- **Threads can ask on their own:** a thread with a risky change comments `@codex review` on its
  own PR (if Go allows the on-demand review). Zero hands.

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

### Use 1. Research the threads can ask for themselves (★, one-time setup)

The threads already search the web. Perplexity is worth adding **as well**, not instead, as an
independent second opinion when a wrong answer costs money or breaks a rule: Steam's AI-disclosure
and refund rules, a licence's small print, Steamworks fees and tax forms, age ratings. The route,
with no courier:

1. A thread opens a GitHub issue with the question, labelled `research`.
2. A workflow (`.github/workflows/research.yml`, built on Will's yes, standard library only)
   sends the question to Perplexity's Sonar API with the repo secret `PERPLEXITY_API_KEY` and
   posts the answer and its sources back as a comment on the issue.
3. The thread reads the comment through GitHub, compares it with its own sources, and says where
   they differ in its write-up. The issue closes.

Will's one-time setup (3 minutes, on the PC is easiest, works on the phone):
1. **perplexity.ai → Settings → API** (the `</> API` tab). Check it shows a monthly Pro credit
   (Perplexity's FAQ says $5 on the first of each month; some newer guides say this changed). **If
   there is no included credit, stop: this route would cost money, so it is dropped.**
2. **Generate API key**, and if it offers a spending cap or auto top-up, set auto top-up **off**,
   so it can never spend past the free credit.
3. GitHub → **earth-kings → Settings → Secrets and variables → Actions → New repository secret**,
   name `PERPLEXITY_API_KEY`, paste the key, Save. The key never goes anywhere else.

$5 a month covers a few hundred short Sonar questions, far more than we need (a few a month). The
workflow only runs on issues labelled `research` by someone with write access, so a stranger can't
spend it.

### Use 2. A question box that reads the repo (★, one-time setup)

For Will or Ewan on a phone: "what did we decide about hunger on the floor?", "what's left before
Steam?", answered with the doc and decision number, without starting a thread or using Claude's
usage. This one is Will using a tool, not carrying anything.

1. Perplexity → **Settings → Connectors → GitHub** → connect, only the earth-kings repo. If there
   is no GitHub connector on Pro, **skip this use**: uploading files that go stale would mean
   ongoing work, which the rule rules out.
2. **Projects → New project → "Earth Kings"**, sources: the GitHub connector. Instructions (paste
   once): "Answer questions about the game Earth Kings from the earth-kings repo only, starting from
   docs/00-index.md. Quote the file and decision number (D…) you used. If the repo doesn't say, say
   so. You never settle a design question: if something is open, say it is open and who decides."
3. Share it with Ewan if Pro lets Ewan in on a free account.

It is a reader, not a source: an answer from it never goes into the ledger.

### What is just duplication (skip)

- General web research: the threads already search; the API route is only for money and legal calls.
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
| Perplexity research (API) | `research` issues answered; times it changed or confirmed a money/legal call; credit used | Any one call changed or confirmed | It ever asks for payment, or its answers are wrong when checked |
| Perplexity Project | Times Will or Ewan used it | Used at all | Not used (leaving it costs nothing) |

On 31 October the coordinator posts one line per tool: keep or drop, with the counts, read
straight off GitHub (comments and labelled issues), so nobody keeps a tally by hand. Dropping
Codex means turning off Automatic review; the `AGENTS.md` section can stay (it costs nothing).

## Decisions (letter for the coordinator to assign)

1. ★ **GitHub is the bus; Will never carries anything.** Every route is zero or one-time hands;
   anything that would need Will ongoing is dropped, not worked around.
2. ★ **Turn on Codex code review if Go has it** (Will's two-minute check), new PRs only, earth-kings
   only, **advisory, not a required check**; threads may ask `@codex review` themselves.
3. ★ **No Codex coding on the repo** on Go; cloud tasks only ever as a new decision after
   play-test 9 and a Plus upgrade.
4. ★ **Perplexity research through its API**, if Pro's API tab shows free monthly credit (auto
   top-up off): Will sets the `PERPLEXITY_API_KEY` repo secret once; a thread then builds the
   `research` workflow and the Monday `codex-sweep` workflow in one tools PR.
5. ★ **A Perplexity Project reading the repo through its GitHub connector**, if the connector
   exists; no uploads.
6. ★ **Skip** Comet, Labs and image generation (never game art).
7. ★ **One-week trial to 31 October**, counted off GitHub, keep or drop on the 31st.

Will's whole job, once: open ChatGPT → Settings → Code Review (2 min); Perplexity → Settings → API,
make a key, paste it into the GitHub secret (3 min); Perplexity → Connectors → GitHub (1 min).
