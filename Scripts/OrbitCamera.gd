extends Node3D

@export var look_at_position: Vector3 = Vector3.ZERO
@export var mouse_sensitivity: float = 1.;
@export var scroll_step: float = 0.1;
@export var min_scroll: float = 0.1;

var _orbit_radius : float     = 3.
var _orbit_rotation : Vector2 = Vector2(180, 0)

func _ready():
    _apply_position(Vector2())

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
            _apply_position(event.relative * mouse_sensitivity)

    if event is InputEventMouseButton and event.is_pressed():
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _orbit_radius -= scroll_step
            _orbit_radius = max(_orbit_radius, min_scroll)
            _apply_position(Vector2.ZERO)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _orbit_radius += scroll_step
            _orbit_radius = max(_orbit_radius, min_scroll)
            _apply_position(Vector2.ZERO)
            
func _apply_position(offset : Vector2):
    _orbit_rotation += offset
    
    _orbit_rotation.y = clamp(_orbit_rotation.y, -89, 89)
    
    var translation := Transform3D()
    translation = translation.translated_local(Vector3.FORWARD * -_orbit_radius)
    
    var rotation_matrix := Transform3D()
    rotation_matrix = rotation_matrix.rotated(Vector3.UP, deg_to_rad(_orbit_rotation.x))
    rotation_matrix = rotation_matrix.rotated(Vector3.RIGHT, deg_to_rad(-_orbit_rotation.y))
    
    position = Vector3.ZERO * translation * rotation_matrix;

    transform = transform.looking_at(look_at_position)
