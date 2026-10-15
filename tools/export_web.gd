extends SceneTree
# Run with --headless --editor --path game --script ../tools/export_web.gd
func _initialize() -> void:
	call_deferred("build")
func build() -> void:
	for i in range(120):
		await process_frame
	var platform := EditorExportPlatformWeb.new()
	var preset := platform.create_preset()
	preset.set("variant/thread_support", false)
	preset.set("vram_texture_compression/for_mobile", true)
	preset.set("html/canvas_resize_policy", 2)
	preset.set("html/head_include", "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover\"><style>html,body,canvas{touch-action:none;overscroll-behavior:none}#rotate-tip{display:none}@media(orientation:portrait){#rotate-tip{display:block;position:fixed;bottom:15%;left:5%;right:5%;padding:16px;background:#172131e8;color:#ffe0aa;border-radius:12px;text-align:center;font:16px sans-serif;pointer-events:none}}</style>")
	var output := ProjectSettings.globalize_path("res://../docs/index.html")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var result := platform.export_project(preset, false, output)
	for i in range(platform.get_message_count()):
		print(platform.get_message_text(i))
	if result == OK:
		var html := FileAccess.get_file_as_string(output)
		html = html.replace("</body>", "<div id=\"rotate-tip\">Turn your phone sideways for larger controls.</div></body>")
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(html)
		file.close()
		FileAccess.open(output.get_base_dir().path_join(".nojekyll"), FileAccess.WRITE).close()
		print("WEB BUILD READY: ", output)
	quit(result)
