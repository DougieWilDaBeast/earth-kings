extends Node
## Throwaway: report-only. Does a sprite sit on a solid plate, or on transparency?

const SAMPLES := [
	"res://art/units/sworn_blade/idle/south.png",
	"res://art/units/longbow/idle/south.png",
	"res://art/units/slime/idle/south.png",
	"res://art/units/legion_gold/idle/south.png",
	"res://art/units/dirte/idle/south.png",
	"res://art/units/goblin/idle/south.png",
]


func _ready() -> void:
	for path: String in SAMPLES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null:
			print("%s  MISSING" % path)
			continue
		image.convert(Image.FORMAT_RGBA8)
		var opaque := 0
		var total := image.get_width() * image.get_height()
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).a > 0.98:
					opaque += 1
		print("%-46s corner=%s a=%.2f  opaque %d%%" % [
			path.get_file() + " " + path.get_base_dir().get_base_dir().get_file(),
			image.get_pixel(0, 0).to_html(false),
			image.get_pixel(0, 0).a,
			roundi(float(opaque) / float(total) * 100.0),
		])
	get_tree().quit(0)
