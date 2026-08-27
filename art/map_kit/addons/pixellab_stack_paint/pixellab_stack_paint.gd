@tool
extends EditorPlugin

const TILE_LAYER_PARENT := "Tile Layers"
const LAYER_Y_META := "pixellab_layer_y"
const DUAL_GRID_META := "pixellab_dual_grid_terrain"
const CONTEXT_SOURCES_META := "pixellab_context_terrain_sources"
const TERRAIN_SET := 0
const CORNER_BITS := [
    TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
    TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
    TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
    TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
]
const FULL_TILE_OFFSETS := [
    Vector2i.ZERO,
    Vector2i.RIGHT,
    Vector2i.DOWN,
    Vector2i(1, 1),
]

var _dual_grid_layer: TileMapLayer
var _dual_grid_vertices := {}
var _dual_grid_syncing := false
var _dual_grid_sync_queued := false

func _enter_tree() -> void:
    var undo_redo := get_undo_redo()
    undo_redo.history_changed.connect(_queue_dual_grid_sync)
    undo_redo.version_changed.connect(_queue_dual_grid_sync)
    set_process(true)

func _exit_tree() -> void:
    var undo_redo := get_undo_redo()
    if undo_redo.history_changed.is_connected(_queue_dual_grid_sync):
        undo_redo.history_changed.disconnect(_queue_dual_grid_sync)
    if undo_redo.version_changed.is_connected(_queue_dual_grid_sync):
        undo_redo.version_changed.disconnect(_queue_dual_grid_sync)

func _process(_delta: float) -> void:
    _track_selected_dual_grid_layer()

func _handles(object: Object) -> bool:
    # Without _handles the editor never routes _forward_canvas_gui_input to
    # this plugin. Claim only PixelLab-authored layers, never the user's own
    # TileMapLayers.
    return (
        object is TileMapLayer
        and (object.has_meta(LAYER_Y_META) or object.has_meta(DUAL_GRID_META))
    )

func _edit(object: Object) -> void:
    if object is TileMapLayer and object.has_meta(DUAL_GRID_META):
        _set_dual_grid_layer(object)
    else:
        _set_dual_grid_layer(null)

func _forward_canvas_gui_input(event: InputEvent) -> bool:
    if not event is InputEventMouseButton:
        return false
    var button_event := event as InputEventMouseButton
    if button_event == null:
        return false
    if button_event.button_index != MOUSE_BUTTON_LEFT:
        return false

    var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
    if selected_nodes.size() != 1 or not selected_nodes[0] is TileMapLayer:
        return false
    var selected_layer := selected_nodes[0] as TileMapLayer
    if not button_event.pressed or not selected_layer.has_meta(LAYER_Y_META):
        return false
    var layers := _projection_layers()
    if layers.size() < 2:
        return false

    var surface_layer = _surface_layer_at(button_event.position, layers)
    if surface_layer == null:
        return false
    if button_event.ctrl_pressed:
        surface_layer = _layer_for_y(layers, _layer_y(surface_layer) + 1)
        if surface_layer == null:
            return false
    _select_layer(surface_layer)
    return false

func _track_selected_dual_grid_layer() -> void:
    var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
    var selected_layer: TileMapLayer = null
    if (
        selected_nodes.size() == 1
        and selected_nodes[0] is TileMapLayer
        and selected_nodes[0].has_meta(DUAL_GRID_META)
    ):
        selected_layer = selected_nodes[0] as TileMapLayer
    _set_dual_grid_layer(selected_layer)

func _set_dual_grid_layer(layer: TileMapLayer) -> void:
    if layer == _dual_grid_layer:
        return
    _dual_grid_layer = layer
    _dual_grid_sync_queued = false
    if not is_instance_valid(_dual_grid_layer):
        _dual_grid_vertices = {}
        return
    _dual_grid_vertices = _collect_dual_grid_vertices(_dual_grid_layer)

func _queue_dual_grid_sync() -> void:
    if _dual_grid_syncing or _dual_grid_sync_queued:
        return
    _dual_grid_sync_queued = true
    _sync_dual_grid_brush.call_deferred()

func _sync_dual_grid_brush() -> void:
    _dual_grid_sync_queued = false
    if _dual_grid_syncing or not is_instance_valid(_dual_grid_layer):
        return
    var current := _collect_dual_grid_vertices(_dual_grid_layer)
    var changed_by_terrain := {}
    var vertices := {}
    for vertex in _dual_grid_vertices.keys():
        vertices[vertex] = true
    for vertex in current.keys():
        vertices[vertex] = true
    for vertex in vertices.keys():
        var previous := int(_dual_grid_vertices.get(vertex, -1))
        var terrain := int(current.get(vertex, -1))
        if terrain == previous:
            continue
        if not changed_by_terrain.has(terrain):
            changed_by_terrain[terrain] = []
        changed_by_terrain[terrain].append(vertex)
    _dual_grid_syncing = true
    var affected_cells := {}
    for terrain in changed_by_terrain.keys():
        var cells := {}
        for vertex in changed_by_terrain[terrain]:
            for offset in FULL_TILE_OFFSETS:
                var cell := Vector2i(vertex) + Vector2i(offset)
                cells[cell] = true
                affected_cells[cell] = true
        _dual_grid_layer.set_cells_terrain_connect(
            cells.keys(),
            TERRAIN_SET,
            int(terrain),
            true
        )
    var synced_vertices := _collect_dual_grid_vertices(_dual_grid_layer)
    _resolve_context_terrain_tiles(
        _dual_grid_layer,
        affected_cells,
        synced_vertices
    )
    _dual_grid_syncing = false
    _dual_grid_vertices = _collect_dual_grid_vertices(_dual_grid_layer)

func _collect_dual_grid_vertices(layer: TileMapLayer) -> Dictionary:
    var vertices := {}
    for cell in layer.get_used_cells():
        var tile_data := layer.get_cell_tile_data(cell)
        if tile_data == null or tile_data.get_terrain_set() != TERRAIN_SET:
            continue
        for index in range(CORNER_BITS.size()):
            vertices[Vector2i(cell) + FULL_TILE_OFFSETS[index]] = (
                tile_data.get_terrain_peering_bit(CORNER_BITS[index])
            )
    return vertices

func _context_cells(
    layer: TileMapLayer,
    affected_cells: Dictionary,
    sources: Array
) -> Dictionary:
    var context_cells := {}
    for affected_cell in affected_cells.keys():
        var origin := Vector2i(affected_cell)
        for y_offset in range(-2, 3):
            for x_offset in range(-2, 3):
                context_cells[origin + Vector2i(x_offset, y_offset)] = true
    var source_ids := {}
    for source in sources:
        if source is Dictionary:
            source_ids[int(source.get("source_id", -1))] = true
    for used_cell in layer.get_used_cells():
        if source_ids.has(layer.get_cell_source_id(used_cell)):
            context_cells[used_cell] = true
    return context_cells

func _resolve_context_terrain_tiles(
    layer: TileMapLayer,
    affected_cells: Dictionary,
    vertices: Dictionary
) -> void:
    var sources = layer.get_meta(CONTEXT_SOURCES_META, [])
    if not sources is Array or sources.is_empty():
        return
    var context_cells := _context_cells(layer, affected_cells, sources)
    for context_cell in context_cells.keys():
        var cell := Vector2i(context_cell)
        for source in sources:
            if not source is Dictionary:
                continue
            if not _context_source_owns_cell(source, cell, vertices):
                continue
            var request := _context_pattern_for_cell(source, cell, vertices)
            var tile_index := _context_tile_for_pattern(source, request)
            if tile_index < 0:
                continue
            var columns := int(source.get("columns", 4))
            var source_id := int(source.get("source_id", 0))
            var atlas_coords := Vector2i(tile_index % columns, tile_index / columns)
            if (
                layer.get_cell_source_id(cell) != source_id
                or layer.get_cell_atlas_coords(cell) != atlas_coords
            ):
                layer.set_cell(cell, source_id, atlas_coords)
            break

func _context_source_owns_cell(
    source: Dictionary,
    cell: Vector2i,
    vertices: Dictionary
) -> bool:
    var lower := int(source.get("lower", -1))
    var upper := int(source.get("upper", -1))
    for offset in FULL_TILE_OFFSETS:
        var position := cell + Vector2i(offset)
        if not vertices.has(position):
            return false
        var terrain := int(vertices[position])
        if terrain != lower and terrain != upper:
            return false
    return true

func _context_pattern_for_cell(
    source: Dictionary,
    cell: Vector2i,
    vertices: Dictionary
) -> Array:
    var pattern: Array = []
    for row in range(4):
        var values: Array = []
        for column in range(4):
            var position := cell + Vector2i(column - 1, row - 1)
            values.append(_context_value(source, position, vertices))
        pattern.append(values)
    return pattern

func _context_value(
    source: Dictionary,
    position: Vector2i,
    vertices: Dictionary
) -> int:
    var wildcard := int(source.get("wildcard", 255))
    if not vertices.has(position):
        return wildcard
    var terrain := int(vertices[position])
    var lower := int(source.get("lower", -1))
    var upper := int(source.get("upper", -1))
    if terrain == upper:
        return 1
    if terrain != lower:
        return wildcard
    if (
        vertices.has(position + Vector2i.UP)
        and int(vertices[position + Vector2i.UP]) == upper
    ):
        return 2
    return 0

func _context_tile_for_pattern(source: Dictionary, request: Array) -> int:
    var tiles = source.get("tiles", {})
    if not tiles is Dictionary:
        return -1
    var indices: Array = []
    for key in tiles.keys():
        var text_key := str(key)
        if text_key.begins_with("tile_") and text_key.substr(5).is_valid_int():
            indices.append(int(text_key.substr(5)))
    indices.sort()
    var best_tile := -1
    var best_wildcards := 17
    for tile_index in indices:
        var entry = tiles.get("tile_%d" % int(tile_index), {})
        if not entry is Dictionary:
            continue
        var candidate = entry.get("pattern", [])
        if not candidate is Array or not _context_patterns_match(
            candidate,
            request,
            int(source.get("wildcard", 255))
        ):
            continue
        var wildcards := _context_pattern_wildcards(
            candidate,
            int(source.get("wildcard", 255))
        )
        if wildcards < best_wildcards:
            best_tile = int(tile_index)
            best_wildcards = wildcards
    return best_tile

func _context_patterns_match(
    candidate: Array,
    request: Array,
    wildcard: int
) -> bool:
    if candidate.size() != 4 or request.size() != 4:
        return false
    for row in range(4):
        if not candidate[row] is Array or not request[row] is Array:
            return false
        if candidate[row].size() != 4 or request[row].size() != 4:
            return false
        for column in range(4):
            var expected := int(candidate[row][column])
            var actual := int(request[row][column])
            if expected != wildcard and actual != wildcard and expected != actual:
                return false
    return true

func _context_pattern_wildcards(pattern: Array, wildcard: int) -> int:
    var count := 0
    for row in pattern:
        for value in row:
            if int(value) == wildcard:
                count += 1
    return count

func _projection_layers() -> Array:
    var root := get_editor_interface().get_edited_scene_root()
    if root == null:
        return []
    var parent := root.get_node_or_null(TILE_LAYER_PARENT)
    if parent == null:
        return []
    var layers: Array = []
    for child in parent.get_children():
        if child is TileMapLayer and child.has_meta(LAYER_Y_META):
            layers.append(child)
    return layers

func _surface_layer_at(screen_position: Vector2, layers: Array):
    var best_layer = null
    var best_y := -2147483648
    for layer in layers:
        var local_position: Vector2 = layer.get_global_transform_with_canvas().affine_inverse() * screen_position
        var cell: Vector2i = layer.local_to_map(local_position)
        if layer.get_cell_source_id(cell) == -1:
            continue
        var layer_y := _layer_y(layer)
        if layer_y > best_y:
            best_y = layer_y
            best_layer = layer
    return best_layer

func _layer_for_y(layers: Array, layer_y: int):
    for layer in layers:
        if _layer_y(layer) == layer_y:
            return layer
    return null

func _layer_y(layer: TileMapLayer) -> int:
    return int(layer.get_meta(LAYER_Y_META, 0))

func _select_layer(layer) -> void:
    var selection := get_editor_interface().get_selection()
    var selected_nodes := selection.get_selected_nodes()
    if selected_nodes.size() == 1 and selected_nodes[0] == layer:
        return
    selection.clear()
    selection.add_node(layer)
