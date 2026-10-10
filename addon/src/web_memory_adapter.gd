## Process-memory adapter, the web platform's only persistence: values intentionally do
## not survive page reload, and browser memory is script-accessible, so it is never
## represented as a keystore. Also the default a consumer gets when it supplies no adapter.
extends "credential_adapter.gd"
static var _values: Dictionary[String, String] = {}

func read_value(key: String) -> Result:
	if not _values.has(key):
		return Result.new(Status.NOT_FOUND)
	return Result.new(Status.OK, _values[key])

func write_value(key: String, value: String) -> Result:
	_values[key] = value
	return Result.new(Status.OK)

static func clear_process_memory() -> void:
	_values.clear()
