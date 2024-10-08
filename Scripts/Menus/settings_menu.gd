class_name SettingsMenu
extends Menu 

@onready var WindowSizeDropDown : OptionButton = $VBoxContainer/MarginContainer/GridContainer/ScreenSize
@onready var WindowModeDropDown: OptionButton = $VBoxContainer/MarginContainer/GridContainer/WindowMode
@onready var MusicVolumeSlider : HSlider = $"VBoxContainer/MarginContainer/GridContainer/Music Volume"
@onready var SfxVolumeSlider : HSlider = $"VBoxContainer/MarginContainer/GridContainer/SFX Volume"
@onready var  cm : PackedScene = preload("res://Scenes/Menus/controls_menu.tscn")

const WINDOW_MODE_OPTIONS : Array[String] = [
	"Window Mode",
	"Borderless Window",
	"Full-Screen",
	"Borderless Full-Screen"
]

var settingsData : SettingsData 

func _ready():
	settingsData = SettingsData.load_or_create()
	add_drop_down_options()
	WindowSizeDropDown.selected = settingsData.Window_Size
	WindowModeDropDown.selected = settingsData.Window_Mode
	SfxVolumeSlider.value = settingsData.sfx_volume
	MusicVolumeSlider.value = settingsData.music_volume

## Closes the settings menu
func close_settings():
	emit_signal("menu_closed")
	queue_free()

## Saves the settings data
func save():
	settingsData.save()

func add_drop_down_options():
	for option in Settings.WINDOW_MODE_OPTIONS:
		WindowModeDropDown.add_item(option)
	for sizew in Settings.WINDOW_SIZE.keys():
		WindowSizeDropDown.add_item(sizew)

func _on_exit_button_pressed():
	close_settings()

func _on_music_volume_value_changed(value):
	MusicVolumeSlider.value = value
	settingsData.music_volume = value

func _on_sfx_volume_value_changed(value):
	SfxVolumeSlider.value = value
	settingsData.sfx_volume = value

func _on_window_mode_item_selected(index : int):
	Settings.set_window_mode(index)
	settingsData.Window_Mode = index

func _on_screen_size_item_selected(index : int):
	DisplayServer.window_set_size(Settings.WINDOW_SIZE.values()[index])
	settingsData.Window_Size = index

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE:
			get_tree().paused = true
		NOTIFICATION_EXIT_TREE:
			save()
			get_tree().paused = false 


func _on_controls_pressed():
	self.visible = false
	SceneManger.open_controls_menu()
	await SceneManger.controls_menu_closed
	self.visible = true

