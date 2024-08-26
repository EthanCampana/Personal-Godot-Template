extends Node
class_name GameManager

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Function to receive data upon being initialized.
##
## @param data The data to be received, in the form of a Dictionary.
func recieve_data(data : Dictionary):
	pass

## Function to send data before being freed.
##
## @param data The data to be received, in the form of a Dictionary.
func send_data(data : Dictionary):
	pass