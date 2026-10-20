# 12 — A small on-device model for fight plans: what it would take

**Looked at 2026-10-20** for `dougie`, who asked at the founders' meeting for a small model that
"reads a list of rules and plans and picks one in real time" and named EmbeddingGemma 2
([D298](../06-decisions.md), #385, [part 1 of the transcript](../worldbuilding/voice-notes/2026-10-20-founders-meeting-part-1.md)).
This is the investigation that row asked for, the first pass: what the model is, how big it is, what
would run it inside a Godot build, what that costs against the stack rules, and the cheapest way to
find out whether it fights better than the rules we have. **The fight run with and without it is not
done yet**; the last section says how to do it. Nothing here is settled: the proposal at the end is
**Inferred**, for the founders to keep or drop.

## What the game has today

- **The rule.** `AGENTS.md`: Godot 4.7, GDScript, no .NET, no plugins, no build step. Python only
  for the tools in `tools/`. No `addons/` folder exists.
- **The seam.** [D03](../06-decisions.md): a mind returns plans; only the engine changes the world.
  [D02](../06-decisions.md): local only, offline, no server.
- **The brain.** `src/skirmish/skirmish_brain.gd` thinks for every side: it picks a target, a skill
  and a tactic from the doctrines, stances and moves in `data/skirmish.json` → `tactics`. It is
  hand-written on purpose ([18](../18-combat-direction.md#tactics)): it runs at once in the browser
  and on phones, a seed still gives the same fight, and every move can be read and tuned in data.
  The who-wins bouts and the party clashes think with the same brain, so any change to it can be
  measured on them.
- **What ships.** Four exports: Windows, Linux, macOS universal, and Web with threads off. Steam
  first, the First Hour free in the browser on itch, phones after ([D255](../06-decisions.md)).
  The browser build is about 56 MB. CI runs the thirteen suites and the soak on Ubuntu with the
  official Godot 4.7.2 binary, headless.
- **AI on the store page.** Steam asks what AI made ([D297](../06-decisions.md),
  [32](../32-the-pipeline.md)). Model weights in the build would be the first AI-made thing in the
  game itself, and the runtime and the weights would both need rows in
  [22](../22-asset-provenance.md) and `data/credits.json`.
- **A model already in the repo, as a tool.** `tools/transcribe_voice_notes.py` runs faster-whisper
  on the founders' recordings. It is fetched from Hugging Face on the maker's machine and never
  ships. That is the shape a dev-side model takes here.

## The model: EmbeddingGemma 2

Released by Google DeepMind on 6 October 2026, Apache 2.0, built on Gemma 4. The text core is 270M
parameters; the vision and audio encoders are separate and optional, so a fight-plan use ships text
only. Output is a 768-wide vector that can be cut to 512, 256 or 128. Official GGUF files exist from
the ggml team and llama.cpp gained the architecture on release day; community ONNX conversions exist
too.

| EmbeddingGemma 2, text only | Size |
| --- | --- |
| GGUF Q4 (Unsloth's build) | 176 MB |
| ONNX int8 (a community build) | about 274 MB |
| Memory while running, as reported | about 191 MB |

Not "a couple of gigabytes", then: a quarter of one. Two things about it decide everything below.

- **It is an embedder.** It turns a piece of text into a vector so that the nearest other text can
  be found. Given a fight situation written as words and a list of plans written as words, it will
  pick the plan whose words are closest. It does not reason about a plan nobody wrote. That is what
  [D298](../06-decisions.md) already says, and it holds for the new version.
- **It needs a native runtime.** GDScript cannot run it. Something compiled (llama.cpp or ONNX
  Runtime) has to be in the build, and in Godot that is a GDExtension: a plugin, with a binary per
  platform.

## What could run it inside Godot

Everything in this space is young. Two of them are usable today; the rest are one-person proofs of
concept.

| Runtime | What it is | Godot | Platforms | Licence | Where it stands |
| --- | --- | --- | --- | --- | --- |
| **NobodyWho** | llama.cpp as a GDExtension: chat, embeddings, structured output, tool calls | 4.5+ | Windows, Linux, macOS, Android; Vulkan and Metal on the GPU; **no web** | EUPL-1.2, which it says allows commercial use | 1.6k stars, active. Runs GGUF, so EmbeddingGemma 2 once its bundled llama.cpp is from this month |
| **godot-native-rl** | ncnn as a GDExtension, for small trained policies (MLPs, LSTMs) | 4.5+ | Windows, Linux, macOS and **Web** verified; CPU only | MIT | Early, one maintainer. The only one that could survive the browser build, and even that needs Godot's extension-capable web template, which our preset does not use |
| godot-onnx-loader | ONNX Runtime 1.22, CPU only, float32 only | 4.6+ | Linux supported; Windows and macOS experimental | MIT | One star. Honest about its limits |
| godot-infer | ONNX graphs on Godot's own RenderingDevice (Vulkan, D3D12, Metal) | 4.5+ | Desktop | MIT | No releases yet |
| godot_onnx_extension | ONNX Runtime, Windows and Android | unstated | Windows, Android | MIT | Stale proof of concept |

### Windows ML and NPUs

`dougie` asked about these by name, so they are answered here, but they do not change the choice.

- **Windows ML** is Microsoft's copy of ONNX Runtime built into Windows. CPU and the older DirectML
  path work on every supported Windows. The NPU and vendor GPU providers (OpenVINO for Intel, QNN
  for Qualcomm, VitisAI for AMD, TensorRT-RTX for NVIDIA) are downloaded on demand and need Windows
  11 24H2 or later. There is no Godot binding at all: using it means writing a GDExtension in C++
  against the Windows App SDK, and it serves only the Windows export. Linux, macOS, the browser and
  the Steam Deck get nothing from it.
- **NPUs in general.** A Godot forum thread from July 2026 lands where this does: almost nothing in
  Godot reaches an NPU. Linux has no common path, Apple's Neural Engine is reached only through
  CoreML, and Valve's hardware survey does not count NPUs at all. llama.cpp has an Intel OpenVINO
  backend in preview and an experimental Qualcomm Hexagon backend, so the llama.cpp route may get
  there in time. For a model this small it does not matter: the ncnn comparison doc makes the point
  that CPU SIMD wins for tiny networks and NPU gains show only on big vision and language models.

So: Windows ML and NPUs are a later optimisation of whichever runtime wins, not a starting point.

## What any of them costs

Any native extension is the same stack decision, whichever one it is:

- **A numbered decision** and an edit to the Stack line in `AGENTS.md`.
- **A Linux binary committed** (or built) for CI, or every headless suite fails to load it.
  A universal dylib and signing for macOS. Nothing for the Web export as it stands.
- **Licence rows** in [22](../22-asset-provenance.md) and the credits, and Steam's AI note.
- **Determinism goes.** A seeded fight no longer replays the same on every machine once a float
  model is in the loop. The soak on seed 77, the who-wins clips and "a seed still gives the same
  fight" all lean on that today.
- **Two brains.** The browser First Hour and phones either lose the feature or keep the rules brain
  beside the model, and the two must agree enough that a fight on itch is the fight on Steam.
- **Size.** A quarter of a gigabyte on top of a game that is tens of megabytes.

## The proposal: try it offline first (Inferred)

Because the model only finds the nearest text, it may not need to be in the game at all.

The fight state the brain sees is nearly discrete: a doctrine, a role, a stance, whether a foe is
hurt or marked or soft, reach, who is close to the lead. If the situations the brain can be in can
be **enumerated**, a Python tool in `tools/` can embed every situation and every plan with
EmbeddingGemma 2 on the maker's machine, pick the winning plan for each, and write the table into
`data/skirmish.json`. The game then does a dictionary lookup. It runs everywhere including the
browser, stays deterministic, ships nothing new, and the model is a dev tool like faster-whisper
already is. The rule holds and nothing in the stack changes.

If the situations **cannot** be enumerated (if the plans have to read a fight that was never
written down), that is the finding that justifies a runtime, and NobodyWho with the Q4 GGUF on a
branch is the cheapest way to test it, on Windows and Linux only.

Either way the test is the one [D298](../06-decisions.md) asked for, and the harness exists:
`python3 tools/party_war.py all` and `tools/who_wins.py` already print results tables from the same
brain. Run the sixteen bouts and a set of party clashes with the rules brain, then with the model's
plans behind the same seam, and compare who wins, how long the fights run, and whether the words
over the fighters' heads still read. That run is the next step on #385 and needs no change to the
stack to start.

## Sources

Read 2026-10-20. [Google's EmbeddingGemma 2 announcement](https://blog.google/innovation-and-ai/technology/developers-tools/embeddinggemma-2/);
[ggml-org GGUF files](https://huggingface.co/ggml-org/embeddinggemma-2-GGUF);
[Unsloth's run guide](https://unsloth.ai/docs/models/embeddinggemma-2);
[a community ONNX build](https://huggingface.co/pamin-labs/embeddinggemma-2-text-int8-onnx);
[NobodyWho](https://github.com/nobodywho-ooo/nobodywho);
[godot-native-rl](https://github.com/minigraphx/godot-native-rl) and its
[ncnn versus ONNX Runtime note](https://github.com/minigraphx/godot-native-rl/blob/main/docs/ncnn_vs_onnx.md);
[godot-onnx-loader](https://github.com/DynamicDevices/godot-onnx-loader);
[godot-infer](https://github.com/FrancoYudica/godot-infer);
[godot_onnx_extension](https://github.com/joemarshall/godot_onnx_extension/);
[Windows ML overview](https://learn.microsoft.com/en-us/windows/ai/new-windows-ml/overview) and
[its execution providers](https://learn.microsoft.com/en-us/windows/ai/new-windows-ml/supported-execution-providers);
[Access to NPU from Godot, Godot forum](https://forum.godotengine.org/t/access-to-npu-from-godot/141426);
[OpenVINO in llama.cpp](https://medium.com/openvino-toolkit/openvino-lands-in-llama-cpp-run-gguf-models-on-intel-cpu-gpu-and-npu-d6fca1d633e8).
