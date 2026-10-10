## Process-memory adapter, the web platform's only persistence: values intentionally do
## not survive page reload, and browser memory is script-accessible, so it is never
## represented as a keystore. Also the default a consumer gets when it supplies no adapter.
##
## The shared dictionary lives on Engine metadata rather than in a static variable: a script
## with a static variable stays loaded until exit, and a project that preloads this script
## then reports every script it reached as still in use when the editor quits.
extends "credential_adapter.gd"

const MEMORY_KEY: StringName = &"gd_session_web_memory"

static func _memory() -> Dictionary:
	if not Engine.has_meta(MEMORY_KEY):
		Engine.set_meta(MEMORY_KEY, {})
	return Engine.get_meta(MEMORY_KEY)

func read_value(key: String) -> Result:
	var values: Dictionary = _memory()
	if not values.has(key):
		return Result.new(Status.NOT_FOUND)
	return Result.new(Status.OK, str(values[key]))

func write_value(key: String, value: String) -> Result:
	_memory()[key] = value
	return Result.new(Status.OK)

static func clear_process_memory() -> void:
	Engine.set_meta(MEMORY_KEY, {})
