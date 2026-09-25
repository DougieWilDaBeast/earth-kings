# Sprite size test

What PixelLab makes for the size test goes here. The instructions are in
[docs/20](../../docs/20-pixellab-size-test.md), and the viewer is `.\ek.ps1 sizetest`
(`tools/size_test.tscn`).

```
art/size_test/
  <size>/<unit>/idle/<facing>.png              still rotations: north, south, east, west (+ diagonals)
  <size>/<unit>/attack/<facing>/frame_000.png  animation frames
  <size>/<unit>/metadata.json                  the prompt and settings it was made with
  portrait/sworn_blade.png                     the portrait, if made
  shots/                                       screenshots from the viewer (F12), not kept in git
  RESULTS.md                                   costs, frame counts and the verdict
```

`.\ek.ps1 sizetest import <zip> <unit> <size> [state]` puts a PixelLab download here. The 64s are
read from `art/units/`, so they are not copied here.

Nothing in this folder is used by the game itself. Once a size is chosen, Tier 1 is generated at that
size into `art/units/` as usual.
