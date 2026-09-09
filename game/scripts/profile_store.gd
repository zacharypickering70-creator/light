extends RefCounted
const DEFAULTS={"coins":30,"heart":0,"weapon":0,"spirit":0,"chapter":1}

static func sanitize(raw: Dictionary) -> Dictionary:
	var result: Dictionary=DEFAULTS.duplicate()
	for key in result:
		var value: Variant=raw.get(key,result[key])
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): continue
		result[key]=clampi(int(value),1 if key=="chapter" else 0,999999 if key=="coins" else (2 if key=="chapter" else 5))
	return result

static func read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	var parsed: Variant=parser.data
	if not parsed is Dictionary: return {}
	var raw: Variant=parsed.get("data",parsed)
	if not raw is Dictionary: return {}
	if not raw.has("coins"): return {}
	return sanitize(raw)

static func load_profile(path: String) -> Dictionary:
	var data: Dictionary=read_valid(path)
	if not data.is_empty(): return data
	data=read_valid(path+".bak")
	return DEFAULTS.duplicate() if data.is_empty() else data

static func save_profile(data: Dictionary,path: String) -> Error:
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version":1,"data":sanitize(data)}))
	file.flush()
	file.close()
	if read_valid(path+".tmp").is_empty(): return ERR_FILE_CORRUPT
	if not read_valid(path).is_empty():
		var backup_error: Error=DirAccess.copy_absolute(path,path+".bak")
		if backup_error!=OK: return backup_error
	return DirAccess.rename_absolute(path+".tmp",path)
