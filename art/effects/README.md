# Fight effects

Generated 2026-10-12 with `tools/pixellab.py effect`: a still drawn from words, then set moving.
Each folder is one effect, `frame_000.png` onwards, 64 × 64.

| Folder | For |
| --- | --- |
| `slash` | a sword or claw hit |
| `arrow` | a shot in flight |
| `heal` | Mend and other healing |
| `burst` | a fire spell or a blast landing |
| `charge` | a charged spell building ([D59](../../docs/06-decisions.md)) |
| `block` | a shield turning a swing aside ([D59](../../docs/06-decisions.md)) |

The status and item icons that go with them (stun, bleed, burn, provoke, vulnerable, charging,
tired, block, draught, herb; 32 × 32, made with `image`) are in `art/ui/status/`.

In the fight since 2026-10-13 ([D82](../../docs/06-decisions.md)): which moment plays which effect,
and which state wears which icon, is `effects` and `status_icons` in `data/skirmish.json`. Bleed,
burn, provoke, vulnerable and the block icon are not shown yet: nothing in the fight gives those.
