class_name SaveData extends Resource

@export var main_scene : String = ""

const PATH: String = "user://savegame.tres"

func save() -> void:
    ResourceSaver.save(self,PATH)

static func load_or_create() -> SaveData:
    var res :  SaveData
    if FileAccess.file_exists(PATH):
        res = load(PATH) as SaveData 
    else:
        res = SaveData.new()
        res.save()
    return res