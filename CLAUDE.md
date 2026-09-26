@AGENTS.md

## Claude Code specifics

If the `delegate` MCP tool is connected (it needs `dougie`'s LLM gateway; see
`.mcp.json` and `LLM_GATEWAY_DIR`), use it to save the Claude allowance. If it is not
connected, or `gateway_status` says the gateway is down, carry on without it and say so once.

Delegate (lane in brackets):
- summarising a long Godot or soak log: `delegate_file`, so it never enters your context (cheap)
- first drafts of `data/` JSON variations — names, rumour lines, errand wording — for you to
  review against `docs/04-data-formats.md` (code)
- a second-opinion review of a small diff (strong)
- anything quoting the founders, or any file under `docs/worldbuilding/` (private only)

Keep for yourself: GDScript systems work, anything touching save format or `EventBus`,
balance numbers, `06-decisions.md`, and every status written into `answers.md`. A delegated
draft is reviewed before it is written to the repo; for the voice-note mapping, the status is
decided by reading the note whole, not by the draft.
