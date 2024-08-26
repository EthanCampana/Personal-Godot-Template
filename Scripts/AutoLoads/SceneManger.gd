extends Node


"""
TODO:
	Re-implement the scene manager caching of scenes to use the ResourceLoader cache instead of my own :D  
"""


signal _content_invalid(path:String)
signal _content_failure(path:String)
signal _content_not_exist(path:String)
signal _content_not_exist_cache(path:String)
signal _content_loaded_cache()
signal menu_closed()
signal controls_menu_closed()




## Represents data for a loaded scene.
class LoadedSceneData:
	## The scene resource to be loaded.
	var scene : Resource
	## The node to load the scene into.
	var load_into : Node
	## The transition to be used when loading the scene.
	var transition : String

	## Creates a new instance of LoadedSceneData.
	## 
	## Arguments:
	## - scene: The scene resource to be loaded.
	## - load_into: The node to load the scene into.
	## - transition: The transition to be used when loading the scene.
	## 
	## Returns:
	## A new instance of LoadedSceneData.
	func newSceneData(scene : Resource, load_into : Node, transition : String) -> LoadedSceneData:
		var s = LoadedSceneData.new()
		s.scene = scene
		s.load_into = load_into
		s.transition = transition
		return s



# Internal Variables
var _load_in_progress : bool # Flag to check if a scene is being loaded 
var _scene_to_load : String # Scene to load
var _load_progress_timer : Timer # Timer to monitor threaded load
var _load_into : Node # Node to load scene into
var _load_scene_data: LoadedSceneData # Loaded scene data 
var _loaded_scenes_cache : Dictionary = {} # Dictionary of loaded scenes key: scenePath, value: LoadedSceneResource
var _transition : String # Stored transition type for scene swap
var _cache_queue : Array = [] # Queue of scenes to load into cache
var _menu_opened: bool = false # Flag to check if a menu is opened
var uiMenu  : CanvasLayer # UI Menu to add to the scene tree


@onready var TransitionMgr : Transitions = preload("res://Scenes/TransitionManager.tscn").instantiate()
@onready var settings_menu: PackedScene = preload("res://Scenes/Menus/settings_menu.tscn")
@onready var  cm : PackedScene = preload("res://Scenes/Menus/controls_menu.tscn")

func _ready():
	get_tree().root.add_child.call_deferred(TransitionMgr)
	_content_invalid.connect(_on_content_invalid.bind(_scene_to_load))
	_content_failure.connect(_on_content_load_failure.bind(_scene_to_load))
	_content_not_exist.connect(_on_content_not_exist.bind(_scene_to_load))
	_content_not_exist_cache.connect(_on_content_not_exist_cache.bind(_scene_to_load))

## Opens the controls menu.
##
## If the settings menu is already opened, it adds a new instance of the controls menu to the UI menu,
## waits for the menu to be closed, and then frees the instance.
##
## If the settings menu is not opened, it creates a new UI menu, adds an instance of the controls menu to it,
## waits for the menu to be closed, emits the 'menu_closed' signal, frees the UI menu, and sets '_menu_opened' to false.
func open_controls_menu()-> void:
	if _menu_opened:
		uiMenu.add_child(cm.instantiate())
		await uiMenu.get_child(1).menu_closed
		uiMenu.get_child(1).queue_free()
		controls_menu_closed.emit()
	else:
		uiMenu = CanvasLayer.new()
		_menu_opened = true
		uiMenu.add_child(cm.instantiate())
		await uiMenu.get_child(0).menu_closed
		menu_closed.emit()
		_menu_opened = false
		uiMenu.queue_free()

func open_settings_menu()-> void:
	if not _menu_opened:
		uiMenu = CanvasLayer.new()
		_menu_opened = true
		uiMenu.add_child(settings_menu.instantiate())
		TransitionMgr.transition()
		await TransitionMgr.transition_finished
		TransitionMgr.transition_out()
		await TransitionMgr.transition_finished
		get_tree().root.add_child(uiMenu)
		await uiMenu.get_child(0).menu_closed
		menu_closed.emit()
		_menu_opened = false
		uiMenu.queue_free()

func _verify_scene_path(scene_path:String) -> bool:
	if not ResourceLoader.exists(scene_path):
		_content_not_exist.emit(scene_path) 
		return false
	return true

func _load_scenes_from_queue_to_cache()-> void:
	while len(_cache_queue) > 0:
		var item= _cache_queue.pop_front()
		_scene_to_load = item.get("scene_path") 
		_load_into = item.get("load_into") 
		_transition = item.get("transition")     
		_load_in_progress = true
		_load_content_threaded()
		await _content_loaded_cache

func load_scenes_into_cache(scene_to_load:String,load_into:Node=null,transition:String="fadeIn")-> void:
	if _load_in_progress:
		push_warning("Scene Manager is loading something already")
		push_warning("Add Request to queue")
		_cache_queue.append({"scene_path":scene_to_load,"load_into":load_into,"transition":transition})
	_cache_queue.append({"scene_path":scene_to_load,"load_into":load_into,"transition":transition})
	_load_scenes_from_queue_to_cache()

func load_scene_and_swap(scene_to_load:String,load_into:Node=null,outgoing_scene: Node = null,transition:String="fadeIn")-> void:
	if _load_in_progress:
		push_warning("Scene Manager is loading something already")
	_scene_to_load = scene_to_load
	_load_into = load_into
	_transition = transition
	if load_into == null:
		load_into = Node2D.new()
	if not _verify_scene_path(_scene_to_load):
		return
	_swap_scenes(outgoing_scene)


func _load_content_threaded()-> void:
	var loader = ResourceLoader.load(_scene_to_load)
	if not ResourceLoader.exists(_scene_to_load) or loader == null:
		self.emit_signal("_content_invalid",_scene_to_load)
		return
	_load_progress_timer = Timer.new()
	_load_progress_timer.set_wait_time(0.1)
	_load_progress_timer.timeout.connect(_monitor_threaded_load)
	get_tree().root.add_child(_load_progress_timer)
	_load_progress_timer.start()
	
func _monitor_threaded_load() -> void:
	var load_progress = []
	var load_status = ResourceLoader.load_threaded_get_status(_scene_to_load,load_progress)
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_content_invalid.emit(_scene_to_load)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_progress_timer.stop()
			_load_progress_timer.queue_free()
			_loaded_scenes_cache[_scene_to_load] = _load_scene_data.newSceneData(ResourceLoader.load_threaded_get(_scene_to_load),_load_into,_transition)
			_content_loaded_cache.emit()
			_load_in_progress = false   
		ResourceLoader.THREAD_LOAD_FAILED:
			_content_failure.emit(_scene_to_load)
			_load_progress_timer.stop()
			return


func _unload_Node(n: Node) -> void:
	if n != null:
		if n != get_tree().root:
			n.queue_free()

func swap_scenes_cache(cache_scene_path: String,unload_scene : Node = null)-> void:
	var lsd : LoadedSceneData = _loaded_scenes_cache.get(cache_scene_path)
	if lsd == null:
		_content_not_exist_cache.emit(cache_scene_path)
		return
	_load_into.add_child(lsd.scene.instantiate())
	TransitionMgr.transition(lsd.transition)
	await TransitionMgr.transition_finished
	TransitionMgr.transition_out()
	_unload_Node(unload_scene)  
	get_tree().root.add_child(_load_into)
	return

## Swaps scenes and performs a transition.[br]
## Parameters:[br]
## - unload_scene: The scene to unload before swapping. Defaults to null.[br]
## Returns: None[br]
## This function swaps scenes by loading a new scene, instantiating it, adding it as a child to the `_load_into` node,[br]
## performing a transition using the `TransitionMgr` singleton, waiting for the transition to finish, performing a transition out,[br]
## unloading the `unload_scene` if provided, and finally adding the `_load_into` node as a child to the root of the scene tree.[br]
func _swap_scenes(unload_scene: Node = null)-> void:
	var new_scene = ResourceLoader.load(_scene_to_load)
	_load_into.add_child(new_scene.instantiate())
	TransitionMgr.transition(_transition)
	await TransitionMgr.transition_finished
	TransitionMgr.transition_out()
	_unload_Node(unload_scene)  
	get_tree().root.add_child(_load_into)
	return

func _on_content_not_exist_cache(path: String):
	printerr("ERROR: Failed to load resource: '%s' it could not be found in cache" % [path])
	return

func _on_content_not_exist(path: String):
	printerr("ERROR: Failed to load resource: '%s' it may not exist" % [path])
	return

func _on_content_load_failure(path: String):
	printerr("ERROR: Failed to load resource: '%s' load failure" % [path])
	return

func _on_content_invalid(path: String):
	printerr("ERROR: Failed to load resource: '%s' content my be invalid or corrupted" % [path])
	return
