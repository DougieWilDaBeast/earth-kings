@tool
extends Node2D

const MANIFEST_PATH := "res://pixellab/engine-map.json"
const BUILDINGS_CONTROLLER_SCRIPT_PATH := "res://scripts/pixellab_buildings_controller.gd"

func _ready() -> void:
    if get_node_or_null("Tile Layers") != null:
        return
    _build_tile_layers()

func _build_tile_layers() -> void:
    var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    if file == null:
        push_error("PixelLab engine manifest could not be opened")
        return
    var manifest = JSON.parse_string(file.get_as_text())
    if not manifest is Dictionary:
        push_error("PixelLab engine manifest is invalid")
        return

    var parent := Node2D.new()
    parent.name = "Tile Layers"
    # Objects carry z_index = drawOrder (>= 0); keep runtime-built tile layers
    # below them so a layer-0 object is never painted over.
    parent.z_index = -1
    add_child(parent)
    _set_owner(parent)

    var legacy: Dictionary = manifest.get("legacyTerrain", {})
    _build_legacy_layers(
        parent,
        legacy.get("layers", []),
        legacy.get("tileSize", {})
    )

    var projection_layers: Array = manifest.get("projectionLayers", [])
    for layer in projection_layers:
        _build_projection_layer(parent, layer)

    for kit in manifest.get("buildingKits", []):
        _build_building_kit(parent, kit)

func _build_building_kit(parent: Node2D, kit: Dictionary) -> void:
    var controller_script = load(BUILDINGS_CONTROLLER_SCRIPT_PATH)
    if controller_script == null:
        push_error("PixelLab Buildings controller script is missing")
        return
    var controller = controller_script.new()
    controller.name = "Buildings - %s" % str(kit.get("name", kit.get("id", "Kit")))
    controller.kit_id = str(kit.get("id", ""))
    controller.editor_description = "PixelLab native Buildings kit. Select this node to open semantic floor, roof, wall, door, stair, pillar, stamp, and storey tools. Generated visual lanes are managed internally."
    parent.add_child(controller)
    _set_owner(controller)

func _build_projection_layer(parent: Node2D, layer: Dictionary) -> void:
    var tile_set_data := _projection_tile_set(layer)
    var cells_by_y: Dictionary = {}
    for cell in layer.get("cells", []):
        var layer_y := int(cell.get("layerY", 0))
        if not cells_by_y.has(layer_y):
            cells_by_y[layer_y] = []
        cells_by_y[layer_y].append(cell)
    if cells_by_y.is_empty():
        cells_by_y[0] = []

    var terrains_configured := false
    var layer_heights := cells_by_y.keys()
    layer_heights.sort()
    for layer_y in layer_heights:
        var tile_layer := TileMapLayer.new()
        var layer_name: String = str(
            layer.get("tileGroupName", layer.get("gridKind", "Tiles"))
        )
        var height_label: String
        if layer_y == 0:
            height_label = "GROUND"
        elif layer_y > 0:
            height_label = "ELEVATED +%d" % layer_y
        else:
            height_label = "LOWER %d" % abs(layer_y)
        tile_layer.name = "Y%d - %s - %s" % [
            layer_y,
            height_label,
            layer_name,
        ]
        tile_layer.editor_description = "PixelLab projected paint layer Y%d (%s). Godot paints only the selected TileMapLayer. Select the Y level matching the surface you want; Y0 is ground, and each positive level is one stack stride higher." % [
            layer_y,
            height_label,
        ]
        tile_layer.set_meta("pixellab_layer_y", layer_y)
        tile_layer.tile_set = tile_set_data["tile_set"]
        _align_projection_tile_layer(tile_layer, layer, layer_y)
        if not terrains_configured:
            _configure_projection_terrains(tile_layer, layer, tile_set_data["source_to_tile"])
            terrains_configured = true
        tile_layer.y_sort_enabled = true
        parent.add_child(tile_layer)
        _set_owner(tile_layer)
        for cell in cells_by_y[layer_y]:
            var tile_index := int(cell.get("tileIndex", 0))
            if tile_set_data["source_to_tile"].has(tile_index):
                tile_layer.set_cell(
                    Vector2i(int(cell.get("q", 0)), int(cell.get("r", 0))),
                    int(tile_set_data["source_to_tile"][tile_index]),
                    Vector2i.ZERO
                )

func _build_legacy_layers(parent: Node2D, layers: Array, tile_size: Dictionary) -> void:
    if layers.is_empty():
        return
    var tile_set := TileSet.new()
    tile_set.tile_size = Vector2i(
        int(tile_size.get("width", 16)),
        int(tile_size.get("height", 16))
    )

    var terrain_ids := []
    var terrain_names := []
    var terrain_walkable := []
    for layer in layers:
        var rules: Dictionary = layer.get("tileRules", {})
        var local_terrain_ids: Array = rules.get("terrain_ids", [])
        var local_terrain_names: Array = rules.get("terrains", [])
        var local_walkable: Array = rules.get("terrain_walkable", [])
        var local_count: int = min(2, min(local_terrain_ids.size(), local_terrain_names.size()))
        for local_index in range(local_count):
            var terrain_id := int(local_terrain_ids[local_index])
            var global_index := terrain_ids.find(terrain_id)
            var walkable = (
                local_walkable[local_index]
                if local_index < local_walkable.size()
                else null
            )
            if global_index < 0:
                terrain_ids.append(terrain_id)
                terrain_names.append(str(local_terrain_names[local_index]))
                terrain_walkable.append(walkable)
            elif terrain_walkable[global_index] == null and walkable != null:
                terrain_walkable[global_index] = walkable

    var terrain_set := 0
    tile_set.add_terrain_set(terrain_set)
    tile_set.set_terrain_set_mode(terrain_set, TileSet.TERRAIN_MODE_MATCH_CORNERS)
    for terrain_index in range(terrain_names.size()):
        tile_set.add_terrain(terrain_set, terrain_index)
        tile_set.set_terrain_name(terrain_set, terrain_index, terrain_names[terrain_index])

    var has_walkability := false
    for value in terrain_walkable:
        if value != null:
            has_walkability = true
            break
    var walkable_layer := -1
    var physics_layer := -1
    if has_walkability:
        walkable_layer = tile_set.get_custom_data_layers_count()
        tile_set.add_custom_data_layer()
        tile_set.set_custom_data_layer_name(walkable_layer, "walkable")
        tile_set.set_custom_data_layer_type(walkable_layer, TYPE_BOOL)
        physics_layer = tile_set.get_physics_layers_count()
        tile_set.add_physics_layer()

    var configured_patterns := {}
    var context_sources := []
    for source_id in range(layers.size()):
        var layer: Dictionary = layers[source_id]
        var atlas := TileSetAtlasSource.new()
        var texture := load(str(layer.get("image", ""))) as Texture2D
        if texture == null:
            continue
        atlas.texture = texture
        atlas.texture_region_size = tile_set.tile_size
        var atlas_columns := int(layer.get("atlasColumns", 4))
        var atlas_tiles: Array = layer.get("atlasTiles", [])
        if atlas_tiles.is_empty():
            for atlas_index in range(atlas_columns * int(layer.get("atlasRows", 4))):
                atlas.create_tile(Vector2i(atlas_index % atlas_columns, atlas_index / atlas_columns))
        else:
            for atlas_index in atlas_tiles:
                var tile_index := int(atlas_index)
                atlas.create_tile(Vector2i(tile_index % atlas_columns, tile_index / atlas_columns))
        tile_set.add_source(atlas, source_id)
        _configure_legacy_atlas_terrains(
            tile_set,
            atlas,
            layer,
            terrain_ids,
            terrain_walkable,
            terrain_set,
            walkable_layer,
            physics_layer,
            configured_patterns
        )
        var context_source := _legacy_context_terrain_source(
            layer,
            source_id,
            terrain_ids
        )
        if not context_source.is_empty():
            context_sources.append(context_source)

    var tile_layer := TileMapLayer.new()
    tile_layer.name = "Y0 - GROUND - Terrain"
    tile_layer.editor_description = "PixelLab ground terrain. All terrain pairs share this native layer so Godot can autotile across them."
    tile_layer.set_meta("pixellab_dual_grid_terrain", true)
    if not context_sources.is_empty():
        tile_layer.set_meta("pixellab_context_terrain_sources", context_sources)
    tile_layer.tile_set = tile_set
    parent.add_child(tile_layer)
    _set_owner(tile_layer)
    for source_id in range(layers.size()):
        var layer: Dictionary = layers[source_id]
        var atlas_columns := int(layer.get("atlasColumns", 4))
        for placement in layer.get("placements", []):
            var atlas_index := int(placement.get("tileIndex", 0))
            tile_layer.set_cell(
                Vector2i(int(placement.get("q", 0)), int(placement.get("r", 0))),
                source_id,
                Vector2i(atlas_index % atlas_columns, atlas_index / atlas_columns)
            )

func _projection_tile_set(layer: Dictionary) -> Dictionary:
    var tile_set := TileSet.new()
    var projection: Dictionary = layer.get("projection", {})
    var cell_size: Dictionary = projection.get("cellSize", {})
    tile_set.tile_size = Vector2i(
        int(cell_size.get("width", layer.get("tileW", 16))),
        int(cell_size.get("height", layer.get("tileH", 16)))
    )
    var grid_kind := str(layer.get("gridKind", ""))
    if grid_kind == "iso":
        tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
        tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
    elif grid_kind == "hex-flat-top" or grid_kind == "hex-pointy-top":
        tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
        tile_set.tile_layout = (
            TileSet.TILE_LAYOUT_STAIRS_DOWN
            if grid_kind == "hex-flat-top"
            else TileSet.TILE_LAYOUT_STAIRS_RIGHT
        )
        tile_set.tile_offset_axis = (
            TileSet.TILE_OFFSET_AXIS_VERTICAL
            if grid_kind == "hex-flat-top"
            else TileSet.TILE_OFFSET_AXIS_HORIZONTAL
        )

    var source_to_tile: Dictionary = {}
    for asset in layer.get("tileAssets", []):
        var texture := load(str(asset.get("assetPath", ""))) as Texture2D
        if texture == null:
            continue
        var source := TileSetAtlasSource.new()
        source.texture = texture
        source.texture_region_size = Vector2i(texture.get_width(), texture.get_height())
        source.create_tile(Vector2i.ZERO)
        var source_id := tile_set.get_next_source_id()
        tile_set.add_source(source, source_id)
        source_to_tile[int(asset.get("tileIndex", 0))] = source_id
    return {"tile_set": tile_set, "source_to_tile": source_to_tile}

func _align_projection_tile_layer(
    tile_layer: TileMapLayer,
    layer: Dictionary,
    layer_y: int = 0
) -> void:
    var projection: Dictionary = layer.get("projection", {})
    var origin_data: Dictionary = projection.get(
        "editorOrigin",
        projection.get("origin", {})
    )
    var q_data: Dictionary = projection.get("qBasis", {})
    var r_data: Dictionary = projection.get("rBasis", {})
    var stack_data: Dictionary = projection.get("stackBasis", {})
    var desired_origin := Vector2(
        float(origin_data.get("x", 0)),
        float(origin_data.get("y", 0))
    )
    desired_origin += layer_y * Vector2(
        float(stack_data.get("x", 0)),
        float(stack_data.get("y", 0))
    )
    var desired_q := Vector2(
        float(q_data.get("x", 0)),
        float(q_data.get("y", 0))
    )
    var desired_r := Vector2(
        float(r_data.get("x", 0)),
        float(r_data.get("y", 0))
    )
    var native_origin := tile_layer.map_to_local(Vector2i.ZERO)
    var native_q := tile_layer.map_to_local(Vector2i(1, 0)) - native_origin
    var native_r := tile_layer.map_to_local(Vector2i(0, 1)) - native_origin
    var determinant := native_q.x * native_r.y - native_r.x * native_q.y
    var m00 := (desired_q.x * native_r.y - desired_r.x * native_q.y) / determinant
    var m01 := (-desired_q.x * native_r.x + desired_r.x * native_q.x) / determinant
    var m10 := (desired_q.y * native_r.y - desired_r.y * native_q.y) / determinant
    var m11 := (-desired_q.y * native_r.x + desired_r.y * native_q.x) / determinant
    var x_basis := Vector2(m00, m10)
    var y_basis := Vector2(m01, m11)
    var translation := desired_origin - Vector2(
        x_basis.x * native_origin.x + y_basis.x * native_origin.y,
        x_basis.y * native_origin.x + y_basis.y * native_origin.y
    )
    tile_layer.transform = Transform2D(x_basis, y_basis, translation)

func _configure_projection_terrains(
    tile_layer: TileMapLayer,
    layer: Dictionary,
    source_to_tile: Dictionary
) -> void:
    var rules = layer.get("tileRules", {})
    if rules == null or not rules is Dictionary or rules.is_empty():
        return
    var rule_type := str(rules.get("rule_type", ""))
    var arity := int(rules.get("arity", 0))
    var grid_kind := str(layer.get("gridKind", ""))
    if rule_type == "corner":
        if arity != 4 or grid_kind == "hex-flat-top" or grid_kind == "hex-pointy-top":
            return
    elif rule_type == "edge":
        if arity == 4 and (grid_kind == "hex-flat-top" or grid_kind == "hex-pointy-top"):
            return
        if arity == 6 and grid_kind != "hex-flat-top" and grid_kind != "hex-pointy-top":
            return
        if arity != 4 and arity != 6:
            return
    else:
        return

    var tile_set: TileSet = tile_layer.tile_set
    var terrain_set := tile_set.get_terrain_sets_count()
    tile_set.add_terrain_set()
    var terrain_names = rules.get("terrains", [])
    for terrain_index in range(2):
        tile_set.add_terrain(terrain_set, terrain_index)
        if terrain_names is Array and terrain_index < terrain_names.size():
            tile_set.set_terrain_name(terrain_set, terrain_index, str(terrain_names[terrain_index]))
    tile_set.set_terrain_set_mode(
        terrain_set,
        TileSet.TERRAIN_MODE_MATCH_CORNERS
        if rule_type == "corner"
        else TileSet.TERRAIN_MODE_MATCH_SIDES
    )

    var peering_bits: Array = []
    if rule_type == "corner":
        peering_bits = _corner_peering_bits(grid_kind)
    elif arity == 4:
        peering_bits = _four_edge_peering_bits(grid_kind)
    else:
        peering_bits = _hex_edge_peering_bits(grid_kind)

    var rule_tiles: Dictionary = rules.get("tiles", {})
    for asset_tile_index in source_to_tile.keys():
        var tile_index := int(asset_tile_index)
        var source_id := int(source_to_tile[asset_tile_index])
        var source := tile_set.get_source(source_id) as TileSetAtlasSource
        if source == null:
            continue
        var tile_data := source.get_tile_data(Vector2i.ZERO, 0)
        tile_data.set_terrain_set(terrain_set)
        var rule_entry = rule_tiles.get("tile_%d" % tile_index, {})
        var is_filler: bool = rule_entry.is_empty() and str(rules.get("connectivity", "same")) == "other"
        var mask := int(rule_entry.get("mask", 0))
        var tile_terrain := 1 if is_filler else 0
        if rule_type == "corner" and mask == 0:
            tile_terrain = 1
        tile_data.set_terrain(tile_terrain)
        for bit_index in range(peering_bits.size()):
            var peering_bit := int(peering_bits[bit_index])
            if peering_bit < 0:
                continue
            var terrain := 0
            if is_filler:
                terrain = 1
            elif rule_type == "corner":
                terrain = 1 - ((mask >> bit_index) & 1)
            elif str(rules.get("connectivity", "same")) == "other":
                terrain = (mask >> bit_index) & 1
            else:
                terrain = 0 if ((mask >> bit_index) & 1) != 0 else 1
            tile_data.set_terrain_peering_bit(peering_bit, terrain)

    _add_projection_terrain_aliases(
        tile_set,
        rules,
        source_to_tile,
        terrain_set,
        rule_type,
        arity,
        peering_bits
    )

func _add_projection_terrain_aliases(
    tile_set: TileSet,
    rules: Dictionary,
    source_to_tile: Dictionary,
    terrain_set: int,
    rule_type: String,
    arity: int,
    peering_bits: Array
) -> void:
    var rule_tiles: Dictionary = rules.get("tiles", {})
    for mask in range(1 << arity):
        var visual_tile := _closest_projection_tile_for_mask(rule_tiles, mask, arity)
        for center_terrain in range(2):
            if (
                rule_type == "edge"
                and str(rules.get("connectivity", "same")) == "other"
                and center_terrain == 1
            ):
                continue
            var alias_tile := visual_tile
            if alias_tile < 0 or not source_to_tile.has(alias_tile):
                continue
            var source := tile_set.get_source(int(source_to_tile[alias_tile])) as TileSetAtlasSource
            if source == null:
                continue
            var alternative := source.create_alternative_tile(Vector2i.ZERO)
            var tile_data := source.get_tile_data(Vector2i.ZERO, alternative)
            tile_data.set_terrain_set(terrain_set)
            tile_data.set_terrain(center_terrain)
            for bit_index in range(peering_bits.size()):
                var peering_bit := int(peering_bits[bit_index])
                if peering_bit < 0:
                    continue
                var terrain := 0
                if rule_type == "corner":
                    terrain = 1 - ((mask >> bit_index) & 1)
                elif str(rules.get("connectivity", "same")) == "other":
                    terrain = (mask >> bit_index) & 1
                else:
                    terrain = 0 if ((mask >> bit_index) & 1) != 0 else 1
                tile_data.set_terrain_peering_bit(peering_bit, terrain)

func _closest_projection_tile_for_mask(
    rule_tiles: Dictionary,
    mask: int,
    arity: int
) -> int:
    var best_tile := -1
    var best_score := -1
    var best_mask := 1 << arity
    for key in rule_tiles.keys():
        var text_key := str(key)
        if not text_key.begins_with("tile_") or not text_key.substr(5).is_valid_int():
            continue
        var tile_index := int(text_key.substr(5))
        var entry = rule_tiles[key]
        if not entry is Dictionary:
            continue
        var masks: Array = []
        var configured_masks = entry.get("masks")
        if configured_masks is Array:
            masks = configured_masks
        else:
            masks = [int(entry.get("mask", -1))]
        for candidate in masks:
            var candidate_mask := int(candidate)
            if candidate_mask == mask:
                return tile_index
            var score := arity - _projection_popcount(candidate_mask ^ mask)
            if (
                score > best_score
                or (score == best_score and candidate_mask < best_mask)
                or (
                    score == best_score
                    and candidate_mask == best_mask
                    and tile_index < best_tile
                )
            ):
                best_tile = tile_index
                best_score = score
                best_mask = candidate_mask
    return best_tile

func _projection_popcount(value: int) -> int:
    var count := 0
    var remaining := value
    while remaining != 0:
        count += remaining & 1
        remaining >>= 1
    return count

func _configure_legacy_atlas_terrains(
    tile_set: TileSet,
    atlas: TileSetAtlasSource,
    layer: Dictionary,
    terrain_ids: Array,
    terrain_walkable: Array,
    terrain_set: int,
    walkable_layer: int,
    physics_layer: int,
    configured_patterns: Dictionary
) -> void:
    var rules = layer.get("tileRules", {})
    if not rules is Dictionary or str(rules.get("rule_type", "")) != "pattern_4x4":
        return
    var local_terrain_ids: Array = rules.get("terrain_ids", [])
    if local_terrain_ids.size() < 2:
        return

    var columns := int(layer.get("atlasColumns", 4))
    var terrain_tiles: Dictionary = rules.get("native_terrain_tiles", {})
    var preserves_context := local_terrain_ids.size() > 2
    for key in terrain_tiles.keys():
        var tile_index := int(str(key).trim_prefix("tile_"))
        var coords := Vector2i(tile_index % columns, tile_index / columns)
        if not atlas.has_tile(coords):
            continue
        var corners: Array = terrain_tiles[key].get("corners", [])
        if corners.size() != 4:
            continue
        var global_corners := []
        for corner in corners:
            var local_index := int(corner)
            if local_index < 0 or local_index >= local_terrain_ids.size():
                global_corners = []
                break
            var global_index := terrain_ids.find(int(local_terrain_ids[local_index]))
            if global_index < 0:
                global_corners = []
                break
            global_corners.append(global_index)
        if global_corners.size() != 4:
            continue
        var pattern_key := "%d,%d,%d,%d" % global_corners
        if not preserves_context and configured_patterns.has(pattern_key):
            continue
        if not preserves_context:
            configured_patterns[pattern_key] = true
        var tile_data := atlas.get_tile_data(coords, 0)
        tile_data.set_terrain_set(terrain_set)
        tile_data.set_terrain(int(global_corners[0]))
        var peering_bits := _corner_peering_bits(str(layer.get("gridKind", "")))
        var corner_for_bit := [
            global_corners[3],
            global_corners[2],
            global_corners[1],
            global_corners[0],
        ]
        for bit_index in range(peering_bits.size()):
            tile_data.set_terrain_peering_bit(
                int(peering_bits[bit_index]),
                int(corner_for_bit[bit_index])
            )

        if walkable_layer < 0:
            continue
        # A corner blocks only when its terrain explicitly says non-walkable.
        var blocked := []
        for corner in global_corners:
            var declared = (
                terrain_walkable[int(corner)]
                if int(corner) < terrain_walkable.size()
                else null
            )
            blocked.append(declared != null and not bool(declared))
        var fully_walkable := true
        for is_blocked in blocked:
            if is_blocked:
                fully_walkable = false
                break
        tile_data.set_custom_data_by_layer_id(walkable_layer, fully_walkable)
        _set_quadrant_collision(tile_data, physics_layer, blocked, tile_set.tile_size)

func _legacy_context_terrain_source(
    layer: Dictionary,
    source_id: int,
    terrain_ids: Array
) -> Dictionary:
    var rules = layer.get("tileRules", {})
    if not rules is Dictionary:
        return {}
    var local_terrain_ids: Array = rules.get("terrain_ids", [])
    if local_terrain_ids.size() < 3:
        return {}
    var lower := terrain_ids.find(int(local_terrain_ids[0]))
    var upper := terrain_ids.find(int(local_terrain_ids[1]))
    if lower < 0 or upper < 0:
        return {}
    return {
        "source_id": source_id,
        "columns": int(layer.get("atlasColumns", 4)),
        "wildcard": int(rules.get("wildcard", 255)),
        "lower": lower,
        "upper": upper,
        "tiles": rules.get("tiles", {}),
    }

func _set_quadrant_collision(
    tile_data: TileData,
    physics_layer: int,
    blocked: Array,
    tile_size: Vector2i
) -> void:
    """Collision for the blocked corners of one tile, in TILE-CENTRED coords.

    Godot expresses tile collision around the tile centre, so a 16px tile spans
    -8..8 on both axes. `blocked` is [NW, NE, SW, SE]. All four collapses to a
    single full-tile rect rather than four abutting quadrants, which keeps the
    common solid tile at one polygon instead of four.
    """
    var half := Vector2(tile_size) * 0.5
    var polygons: Array[PackedVector2Array] = []
    var all_blocked := true
    for is_blocked in blocked:
        if not is_blocked:
            all_blocked = false
            break
    if all_blocked:
        polygons.append(PackedVector2Array([
            Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
            Vector2(half.x, half.y), Vector2(-half.x, half.y),
        ]))
    else:
        # quadrant origins in the same [NW, NE, SW, SE] order as `blocked`
        var origins := [
            Vector2(-half.x, -half.y), Vector2(0, -half.y),
            Vector2(-half.x, 0), Vector2(0, 0),
        ]
        for index in range(blocked.size()):
            if not blocked[index]:
                continue
            var origin: Vector2 = origins[index]
            polygons.append(PackedVector2Array([
                origin, origin + Vector2(half.x, 0),
                origin + half, origin + Vector2(0, half.y),
            ]))
    tile_data.set_collision_polygons_count(physics_layer, polygons.size())
    for index in range(polygons.size()):
        tile_data.set_collision_polygon_points(physics_layer, index, polygons[index])

func _four_edge_peering_bits(grid_kind: String) -> Array:
    if grid_kind == "iso":
        return [14, 2, 6, 10]
    return [12, 0, 4, 8]

func _hex_edge_peering_bits(grid_kind: String) -> Array:
    if grid_kind == "hex-pointy-top":
        return [2, 6, 8, 10, 14, 0]
    return [2, 4, 6, 10, 12, 14]

func _corner_peering_bits(grid_kind: String) -> Array:
    if grid_kind == "iso":
        return [5, 9, 1, 13]
    return [3, 7, 15, 11]

func _set_owner(node: Node) -> void:
    if Engine.is_editor_hint() and get_tree().edited_scene_root != null:
        node.owner = get_tree().edited_scene_root
