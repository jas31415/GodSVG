extends AttributeEditor

@onready var num_edit: LineEdit = $LineEdit
@onready var slider: Button = $Slider

var show_slider := true:
	set(new_value):
		if show_slider != new_value:
			show_slider = new_value
			setup_slider()

var slider_step := 0.1

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

var is_float := true

signal value_changed(new_value: float)
var _value: float  # Must not be updated directly.

func set_value(new_value: float, emit_value_changed := true):
	var old_value := _value
	_value = validate(new_value)
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value)
	elif num_edit != null:
		num_edit.text = str(_value)
		set_text_tint()
		queue_redraw()

func get_value() -> float:
	return _value


func _init(show_slider_value := false) -> void:
	show_slider = show_slider_value

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.value)
		attribute.value_changed.connect(set_value)
		set_text_tint()
	num_edit.text = str(get_value())
	num_edit.tooltip_text = attribute_name
	setup_slider()

func validate(new_value: float) -> float:
	if allow_lower:
		if allow_higher:
			return new_value
		else:
			return minf(new_value, max_value)
	else:
		if allow_higher:
			return maxf(new_value, min_value)
		else:
			return clampf(new_value, min_value, max_value)

func _on_value_changed(new_value: float) -> void:
	num_edit.text = str(new_value)
	if attribute != null:
		attribute.value = new_value


# Hacks to make LineEdit bearable.

func _on_focus_entered() -> void:
	get_tree().paused = true

func _on_focus_exited() -> void:
	set_value(num_edit.text.to_float())
	get_tree().paused = false

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text.to_float())
	num_edit.release_focus()

func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(num_edit, event)


func add_tooltip(text: String) -> void:
	if num_edit == null:
		await ready
	num_edit.tooltip_text = text


# Slider

func set_text_tint() -> void:
	if num_edit != null:
		if attribute != null and get_value() == attribute.default:
			num_edit.add_theme_color_override(&"font_color", Color(0.65, 0.65, 0.65))
		else:
			num_edit.remove_theme_color_override(&"font_color")

func setup_slider() -> void:
	if slider == null:
		await ready
	slider.visible = show_slider
	num_edit.theme_type_variation = &"RightConnectedLineEdit" if show_slider else &""
	num_edit.custom_minimum_size.x = 46 if show_slider else 54
	num_edit.size.x = 0

var slider_hovered := false:
	set(new_value):
		if slider_hovered != new_value:
			slider_hovered = new_value
			queue_redraw()

func _draw() -> void:
	if show_slider:
		var slider_size := slider.get_size()
		var line_edit_size := num_edit.get_size()
		draw_set_transform(Vector2(line_edit_size.x, 1))
		var stylebox := StyleBoxFlat.new()
		stylebox.corner_radius_top_right = 5
		stylebox.corner_radius_bottom_right = 5
		stylebox.bg_color = Color("#121233")
		draw_style_box(stylebox, Rect2(Vector2.ZERO, slider_size - Vector2(1, 2)))
		var fill_height := (slider_size.y - 4) * (get_value() - min_value) / max_value
		if slider_hovered:
			draw_rect(Rect2(0, 1 + slider_size.y - 4 - fill_height,
					slider_size.x - 2, fill_height), Color("#def"))
		else:
			draw_rect(Rect2(0, 1 + slider_size.y - 4 - fill_height,
					slider_size.x - 2, fill_height), Color("#defa"))

func _on_slider_resized() -> void:
	queue_redraw()  # Whyyyyy why are they a wrong size at first...

func _on_slider_gui_input(event: InputEvent) -> void:
	var slider_h := slider.get_size().y - 4
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		slider_hovered = true
		if event.button_mask == MOUSE_BUTTON_LEFT:
			set_value(snappedf(lerpf(max_value, min_value,
					(event.position.y - 4) / slider_h), slider_step))

func _on_slider_mouse_exited() -> void:
	slider_hovered = false
