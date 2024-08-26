class_name MainMenu
extends Control


@onready var version_num : Label = $VBoxContainer/MarginContainer/Label

var sd : SaveData


# Called when the node enters the scene tree for the first time.
func _ready():
	self.sd = SaveData.load_or_create()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_settings_pressed():
	self.visible = false
	SceneManger.open_settings_menu()
	await SceneManger.menu_closed
	self.visible = true 

func _on_start_pressed():
	SceneManger.load_scene_and_swap(sd.main_scene,get_tree().root,self)

func _on_quit_pressed():
	get_tree().quit()
