class_name ControlsData extends Resource


@export var input_actions : Dictionary
@export var event_actions : Dictionary

const PATH:String = "user://controls.tres"

func save() -> void:
    ResourceSaver.save(self,PATH)

static func load_or_create() -> ControlsData:
    var res : ControlsData 
    if FileAccess.file_exists(PATH):
        res = load(PATH) as ControlsData 
    else:
        res = ControlsData.new()
        res.save()
    return res

func load_controls():
    for action in self.event_actions:
        InputMap.action_erase_events(action)
        InputMap.action_add_event(action, event_actions[action])