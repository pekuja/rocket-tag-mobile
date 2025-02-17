extends Control

@export var server_scene : PackedScene
@export var client_scene : PackedScene

@onready var _serverAddressLineEdit = $HFlowContainer/VFlowContainer/ServerAddress
@onready var _yourIpAddressLabel = $YourIpAddress

const SETTINGS_FILE_NAME = "user://settings.cfg"

func _ready():
	if FileAccess.file_exists(SETTINGS_FILE_NAME):
		var settings_file = FileAccess.open(SETTINGS_FILE_NAME, FileAccess.READ)
		var address = settings_file.get_line()
		_serverAddressLineEdit.text = address
	
	for address in IP.get_local_addresses():
		# crude way of detecting a non-localhost IPv4 address
		if address.match("*.*.*.*") and address != "127.0.0.1":
			_yourIpAddressLabel.text = "Your IP address: %s" % address
			break

func _on_join_game_pressed() -> void:
	var address = _serverAddressLineEdit.text
	var settings_file = FileAccess.open(SETTINGS_FILE_NAME, FileAccess.WRITE)
	settings_file.store_line(address)
	
	var scene = client_scene.instantiate()
	scene.name = "Sync"
	scene.server_address = address
	var root = get_tree().get_root()
	root.add_child(scene)
	hide()

func _on_host_game_pressed() -> void:
	var scene = server_scene.instantiate()
	scene.name = "Sync"
	var root = get_tree().get_root()
	root.add_child(scene)
	hide()
