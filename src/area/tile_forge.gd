class_name TileForge
extends RefCounted
## Builds a Godot [TileSet] from a PixelLab tileset sheet.
##
## Every "godot" sheet PixelLab exports shares one 24x8 layout of two blended
## terrains, so a single table of atlas coordinates covers all of them. A tile
## is picked by its four corners rather than its middle: the code is
## NW*8 + NE*4 + SW*2 + SE, where a set bit means the sheet's upper terrain.

## Corner code -> where that tile sits on the sheet. The two diagonal cases
## (0b0110, 0b1001) are not drawn by PixelLab; [method atlas_coords] stands the
## closest tile in for them.
const WANG := {
	0b0000: Vector2i(20, 2),
	0b0001: Vector2i(0, 0),
	0b0010: Vector2i(1, 0),
	0b0011: Vector2i(4, 0),
	0b0100: Vector2i(0, 5),
	0b0101: Vector2i(0, 2),
	0b0111: Vector2i(4, 2),
	0b1000: Vector2i(1, 5),
	0b1010: Vector2i(1, 2),
	0b1011: Vector2i(3, 2),
	0b1100: Vector2i(4, 5),
	0b1101: Vector2i(4, 1),
	0b1110: Vector2i(3, 1),
	0b1111: Vector2i(12, 3),
}

const SOURCE_ID := 0


static func tile_set_for(sheet: Dictionary) -> TileSet:
	var texture: Texture2D = load(sheet.get("texture", ""))
	if texture == null:
		push_error("TileForge: cannot load sheet texture '%s'" % sheet.get("texture", ""))
		return null

	var size := int(sheet.get("tile_size", 64))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(size, size)
	for coords: Vector2i in WANG.values():
		atlas.create_tile(coords)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(size, size)
	tile_set.add_source(atlas, SOURCE_ID)
	return tile_set


## The sheet position drawing [param code], or the nearest corner pattern the
## sheet does have.
static func atlas_coords(code: int) -> Vector2i:
	if WANG.has(code):
		return WANG[code]
	var best: int = 0b1111
	var best_distance := 5
	for candidate: int in WANG:
		var distance := _bit_distance(candidate, code)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return WANG[best]


static func _bit_distance(a: int, b: int) -> int:
	var difference := a ^ b
	var count := 0
	for bit in 4:
		count += (difference >> bit) & 1
	return count
