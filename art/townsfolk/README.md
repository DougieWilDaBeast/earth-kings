# Townsfolk, on the base body

Generated 2026-10-12 with `tools/pixellab.py dress town_<id> --outfit "..."`: eight people who do not
fight, dressed onto the founders' blank base body in the blended finish
([D55](../../docs/06-decisions.md), [D57](../../docs/06-decisions.md)). Idle only, eight facings each,
in `<id>/idle/`; the sentence each was made from is in its `metadata.json`.

| Folder | Who | Made for |
| --- | --- | --- |
| `keeper` | an old library keeper with a lamp | Ondry the Keeper (`library`), who wears `neuron_chief` |
| `duster` | a stooped old servant with a feather duster | Odger, who dusts (`library_vault`), who wears `quant_monkey` |
| `trader` | a desert trader with a ledger | Ibb the Trader (`village_dune`), who wears `quant_monkey` |
| `spice_seller` | a woman spice seller with a basket | Ysolde the Spice-seller (`village_dune`), who wears `drunk_elf` |
| `innkeeper` | a stout innkeeper with a tankard | anyone who keeps an inn |
| `fisher` | a fisherwoman with a net | the shore village |
| `farmer` | a farmer with a pitchfork | the villages |
| `elder` | an old woman with a walking stick | the villages |

**Inferred**, for `doug-md` to confirm: who each is for. Since 2026-10-14 each is a unit of its own
(`town_<id>` in `data/units.json`) and wears the townsfolk who walk their rounds of work in the
villages and the great city ([D85](../../docs/06-decisions.md)).
