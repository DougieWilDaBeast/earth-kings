extends Node
## Throwaway: some PixelLab object exports sit on a solid plate instead of on
## transparency, and the plate does not always reach the corners. Find the most
## common opaque colour around the border and clear it.

const FOLDERS := ["res://art/world"]
const TOLERANCE := 0.09
## A plate has to own this much of the whole border ring to count as one —
## measured against every border pixel, not just the opaque ones, or a handful
## of dark outline pixels on an otherwise clear edge looks like a background.
const MIN_SHARE := 0.25


func _ready() -> void:
	for folder: String in FOLDERS:
		for name: String in DirAccess.get_files_at(folder):
			if name.ends_with(".png"):
				_key(folder.path_join(name))
	get_tree().quit(0)


func _key(path: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return
	image.convert(Image.FORMAT_RGBA8)
	var plate := _plate_of(image)
	if plate.a < 0.5:
		print("%s  already clear" % path.get_file())
		return

	var cleared := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.98:
				continue
			var apart := absf(pixel.r - plate.r) + absf(pixel.g - plate.g) + absf(pixel.b - plate.b)
			if apart <= TOLERANCE:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				cleared += 1
	image.save_png(ProjectSettings.globalize_path(path))
	print("%s  keyed %s -> %d px" % [path.get_file(), plate.to_html(false), cleared])


## The colour that owns the border ring, or a transparent colour when nothing does.
func _plate_of(image: Image) -> Color:
	var tally: Dictionary = {}
	var ring := 0
	for x in image.get_width():
		for y in [0, 1, image.get_height() - 2, image.get_height() - 1]:
			_count(image, tally, x, y)
			ring += 1
	for y in image.get_height():
		for x in [0, 1, image.get_width() - 2, image.get_width() - 1]:
			_count(image, tally, x, y)
			ring += 1
	if ring == 0:
		return Color(0, 0, 0, 0)

	var best := ""
	var most := 0
	for key: String in tally:
		if tally[key] > most:
			most = tally[key]
			best = key
	if best == "" or float(most) / float(ring) < MIN_SHARE:
		return Color(0, 0, 0, 0)
	return Color(best)


func _count(image: Image, tally: Dictionary, x: int, y: int) -> void:
	var pixel := image.get_pixel(x, y)
	if pixel.a < 0.98:
		return
	var key := pixel.to_html(false)
	tally[key] = int(tally.get(key, 0)) + 1
