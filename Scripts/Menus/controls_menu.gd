extends Menu 
class_name ControlsMenu


@onready var input_button : PackedScene = preload("res://Scenes/UI/input_button.tscn")
@onready var action_list :  = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList

# Dictionary of all the controls we want the player to be able to change
@export var input_actions : Dictionary 	= {"jump": "Jump"} 

# Control Reosource Data
var controlData : ControlsData 

var is_remapping : bool = false
var action_to_remap : String = ""
var remapping_button : Button = null


# On ready we create the default controls or load the custom user controls
func _ready():
	controlData = ControlsData.load_or_create()	
	if controlData.input_actions.size() != self.input_actions.size():
		_create_default_controls()
		_create_default_action_list()
	else:
		controlData.load_controls()
		_create_action_list()


# Creates the default controls
func _create_default_controls():
	controlData.input_actions = input_actions
	for action in input_actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			controlData.event_actions[action] = events[0]
	controlData.save()
	return



# Creates the action list in th UI
func _create_action_list():
	for item in action_list.get_children():
		item.queue_free()
	for action in input_actions:
		var button = input_button.instantiate()
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")

		action_label.text = input_actions[action]
		var events = InputMap.action_get_events(action)

		if events.size() > 0:
			input_label.text = _update_action_list(button, events[0]) 
		else:
			input_label.text = "None"
		
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button,action))
	return





# Creates the default action list in th UI
func _create_default_action_list():
	InputMap.load_from_project_settings()
	for item in action_list.get_children():
		item.queue_free()
	for action in input_actions:
		var button = input_button.instantiate()
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")

		action_label.text = input_actions[action]
		var events = InputMap.action_get_events(action)

		if events.size() > 0:
			input_label.text = _update_action_list(button, events[0]) 
		else:
			input_label.text = "None"
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button,action))
		
	return


# Sets the clicked button open to remapping
func _on_input_button_pressed(button : Button , action : String) -> void:
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press a key to bind..."

# Detects the input event of key pressed when remapping is enabled
func _input(event):
	if is_remapping:
		if (
			event is InputEventKey ||
			(event is InputEventMouseButton && event.pressed)
		):
			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(remapping_button, event)
			controlData.event_actions[action_to_remap] = event
			is_remapping = false
			action_to_remap = ""
			remapping_button = null
			controlData.save()
			accept_event()

# Update the action list with the new input event
func _update_action_list(button: Button, event: InputEventWithModifiers):
	button.find_child("LabelInput").text = event.as_text().trim_suffix("(Physical)")

# Reset the controls to the default once the reset button is pressed
func _on_button_pressed():
	_create_default_action_list()