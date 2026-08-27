One folder per character, one folder per state, PixelLab rotation names inside:

	art/units/<character>/<state>/{north,south,east,west}.png

Point a template in data/units.json at a state folder:

	"sprite_dir": "res://art/units/golden_knight/idle"

Units pick the rotation matching their facing; diagonals are kept for later.
metadata.json next to each character is the PixelLab export manifest.
