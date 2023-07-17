@tool
extends EditorPlugin

var dock=null;
var dock2=null;
var sheet=null;
var sprite=null;
var animation=[];
var objects:={};
var objects2:={}

var editorSelection=get_editor_interface().get_selection();

func _enter_tree() -> void:
	dock = preload("res://addons/sparrowatlas_editor/source/dock.tscn").instantiate();
	dock2 = preload("res://addons/sparrowatlas_editor/source/dock_2.tscn").instantiate();
	dock.name="SparrowAtlas"
	dock2.name="SparrowAtlas-Packer"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL,dock);
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL,dock2);
	
	editorSelection.selection_changed.connect(OnEditorSelectionChanged);
	objects["spritePath"]=dock.get_node("VBoxContainer/Sprite/SpritePath");
	objects["apply"]=dock.get_node("VBoxContainer/Apply");
	objects["apply1"]=dock.get_node("VBoxContainer/Apply1");
	objects["ispathempty"]=dock.get_node("VBoxContainer/EmptyNodePath/IsEmptyNodePath");
	objects["save"]=dock.get_node("VBoxContainer/Save");
	objects["exportbutton"]=dock.get_node("VBoxContainer/ExportButton");
	objects["sheetPath"]=dock.get_node("VBoxContainer/Sheet/SheetPath");
	objects["offsetX"]=dock.get_node("VBoxContainer/Offset/OffsetX");
	objects["offsetY"]=dock.get_node("VBoxContainer/Offset/OffsetY");
	objects["animIndex"]=dock.get_node("VBoxContainer/Index/Index");
	objects["animIndices"]=dock.get_node("VBoxContainer/Indices/IndicesSplit");
	objects["prefix"]=dock.get_node("VBoxContainer/Prefix/Prefix");
	objects["name"]=dock.get_node("VBoxContainer/Name/Name");
	objects["applyButton"]=dock.get_node("VBoxContainer/Apply");
	objects["target"]=null;
	objects["customOffsetX"]=dock.get_node("VBoxContainer/Offset/OffsetX");
	objects["customOffsetY"]=dock.get_node("VBoxContainer/Offset/OffsetY");
	objects["titleFrames"]=dock.get_node("VBoxContainer/Title9");
	objects["filePath"]=dock.get_node("FilePath");
	
	objects2["filePath"]=dock2.get_node("FilePath");
	objects2["spriteContainer"] = dock2.get_node("VBoxContainer/PanelContainer/HBoxContainer2/ScrollContainer/SpriteContainer")
	objects2["addList"] = dock2.get_node("VBoxContainer/HBoxContainer/AddList")
	objects2["saveAnimPlayer"] = dock2.get_node("VBoxContainer/SaveAnimPlayer")
	objects2["spriteConTemplate"] = dock2.get_node("VBoxContainer/PanelContainer/HBoxContainer2/ScrollContainer/SpriteContainer/Sprite--0").duplicate()
	objects2["sprite0remove"] = dock2.get_node("VBoxContainer/PanelContainer/HBoxContainer2/ScrollContainer/SpriteContainer/Sprite--0/HBoxContainer/RemoveSprite")
	
	for key in objects.keys():
		var obj=objects[key];
		if obj!=null:
			if obj.get_class()=="Button":
				if not obj.pressed.is_connected(OnButtonPressed):
					obj.pressed.connect(OnButtonPressed.bind(obj.name));
	for key in objects2.keys():
		var obj=objects2[key];
		if obj!=null:
			if obj.get_class()=="Button":
				if not obj.pressed.is_connected(OnButtonPressed):
					if not obj.name == "RemoveSprite":
						obj.pressed.connect(OnButtonPressed.bind(obj.name));
					else:
						obj.pressed.connect(onSpriteRemovalPressed.bind(obj.get_parent().get_parent()));
		
				
	
	objects["prefix"].text_changed.connect(PrefixChanged);
	objects["animIndex"].value_changed.connect(OnIndexChanged);
	ToggleEditor(false);
	pass

func _exit_tree() -> void:
	if dock!=null:
		remove_control_from_docks(dock);
	if dock2!=null:
		remove_control_from_docks(dock2);
	pass

func Notification(what,data):
	match what:
		"UpdateSprite":
			if sprite!=null and sheet!=null:
				var frame=sheet[objects["animIndex"].value];
				if animation.size()>0:
					frame=animation[objects["animIndex"].value];
					
				var widthcalc = 0; if len(frame.frameWidth) > 0: widthcalc = (int(frame.frameWidth) - int(frame.width))/2
				var heightcalc = 0; if len(frame.frameHeight) > 0: heightcalc = (int(frame.frameHeight) - int(frame.height))/2
				
				var spriteCrop=Rect2(int(frame.x),int(frame.y),int(frame.width),int(frame.height));
				var obj=objects["target"];
				if obj!=null:
					obj.texture=sprite;
					obj.region_enabled=true;
					obj.region_rect=spriteCrop;
					obj.offset=-Vector2(int(frame.frameX) + widthcalc,int(frame.frameY) + heightcalc)+Vector2(objects["customOffsetX"].value,objects["customOffsetY"].value);
			pass;
			
		"NewAnimation":
			objects["animIndex"].value=0;
			objects["animIndex"].max_value=animation.size()-1;
			Notification("UpdateSprite",{});
			pass;
		
		"NoAnimation":
			objects["animIndex"].value=0;
			objects["animIndex"].max_value=sheet.size()-1;
			Notification("UpdateSprite",{});
			pass;
	pass;
func getLastParent(node:Node) -> Node:
	var current_node = node

	while current_node.get_parent() and !current_node.get_parent().name.contains("@"):
		current_node = current_node.get_parent()
	return current_node

var longlinepath = "@EditorNode@17637/@Control@697/@Panel@698/@VBoxContainer@706/@HSplitContainer@709/@HSplitContainer@717/@HSplitContainer@725/@VBoxContainer@726/@VSplitContainer@728/@VSplitContainer@754/@VBoxContainer@755/@PanelContainer@800/MainScreen/@CanvasItemEditor@10090/@VSplitContainer@9915/@HSplitContainer@9917/@HSplitContainer@9919/@Control@9920/@SubViewportContainer@9921/@SubViewport@9922/"
func getNodePath(node:Node) -> String:
	return str(node.get_path()).replace(longlinepath,"").replace("/root/","").replace(str(getLastParent(node).name,"/"),"")
	
func OnEditorSelectionChanged():
	var nodes=editorSelection.get_selected_nodes();
	if not nodes.is_empty():
		var node=nodes[0];
		if node.get_class()=="Sprite2D":
			ToggleEditor(true);
			objects["target"]=node;
			print("target: ",objects["target"])
			print("target path: ",getNodePath(objects["target"]))
		else:
			ToggleEditor(false);

func ToggleEditor(state):
	if dock!=null:
		var editableTypes:=["LineEdit","SpinBox","Button","HSlider"];
		if state:
			dock.modulate.a=1.0;
			for key in objects.keys():
				var obj=objects[key];
				if obj!=null:
					if obj.get_class() in editableTypes:
						if obj.get_class()!="Button":
							obj.editable=true;
						else:
							obj.disabled=false;
		else:
			dock.modulate.a=0.5;
			for key in objects.keys():
				var obj=objects[key];
				if obj!=null:
					if obj.get_class() in editableTypes:
						if obj.get_class()!="Button":
							obj.editable=false;
						else:
							obj.disabled=true;

func OnButtonPressed(id):
	match id:
		"Apply":
			if dock!=null:
				var spritePath=objects["spritePath"].text;
				var sheetPath=objects["sheetPath"].text;
				var newSprite = FileAccess;
				var newSheet = FileAccess;
				
				spritePath=str(spritePath).replace('\\',"/");
				sheetPath=str(sheetPath).replace('\\',"/");
				
				if newSprite.file_exists(spritePath):
					newSprite=load(spritePath);
				else:
					newSprite=null;

				if newSheet.file_exists(sheetPath):
					newSheet=ConvertXML(sheetPath);
				else:
					newSheet=null;
					
				sprite=newSprite;
				sheet=newSheet;
				Notification("UpdateSprite",{})
			pass;
				
		"Apply1":
			Notification("UpdateSprite",{});
			pass;
		
		"Save":
			objects["filePath"].popup();
			
			await objects["filePath"].dir_selected;

			#if not objects["filePath"].get_ok():
			#	print("Couldn't export the new animation properly.");
			#	return;
			#print("Exported the new animation successfully.")
			
			if animation!=null and sheet!=null and sprite!=null:
				var newAnim=Animation.new();
				var newTrackRect=newAnim.add_track(Animation.TYPE_VALUE);
				var newTrackOffset=newAnim.add_track(Animation.TYPE_VALUE);
				var path = getNodePath(objects["target"])
				if objects["ispathempty"].is_pressed():
					path = ""
				newAnim.track_set_path(newTrackRect,str(path,":region_rect"));
				newAnim.track_set_path(newTrackOffset,str(path, ":offset"));
				var indices = [];
				if len(objects["animIndices"].text) > 0:
					indices = str(objects["animIndices"].text).split(",")
				var animLength = 0.0
				var curIndexAdd = 0
				for index in animation.size():
					var indicesfound = true
					if indices.size() > 0:
						indicesfound = false
						for i in indices:
							if int(i) == index:
								indicesfound = true
								break
					#if animation.has(index):
					if !indicesfound: continue
					var frame=animation[index];
					
					var widthcalc = 0; if len(frame.frameWidth) > 0: widthcalc = (int(frame.frameWidth) - int(frame.width))/2
					var heightcalc = 0; if len(frame.frameHeight) > 0: heightcalc = (int(frame.frameHeight) - int(frame.height))/2
				
					var targetCrop=Rect2(int(frame.x),int(frame.y),int(frame.width),int(frame.height));
					var targetOffset=-Vector2(str(frame.frameX).to_float(),str(frame.frameY).to_float())+Vector2(objects["offsetX"].value,objects["offsetY"].value);
						
					newAnim.track_insert_key(newTrackRect,curIndexAdd*0.5,targetCrop,0);
					newAnim.track_insert_key(newTrackOffset,curIndexAdd*0.5,targetOffset,0);
					animLength += 0.5
					curIndexAdd += 1
					
				newAnim.length = animLength
				#removeFile(str(objects["filePath"].current_path).left(-1),objects["name"].text+".tres")
				ResourceSaver.save(newAnim, str(objects["filePath"].current_path)+objects["name"].text+".tres")
			pass;
		"ExportButton":
			objects["filePath"].popup();
			await objects["filePath"].dir_selected;
			if sheet!=null and sprite!=null:
				var anims = getAllAnims()
				var path = getNodePath(objects["target"])
				if objects["ispathempty"].is_pressed():
					path = ""
				for k in anims.keys():
					var newAnim=Animation.new();
					var newTrackRect=newAnim.add_track(Animation.TYPE_VALUE);
					var newTrackOffset=newAnim.add_track(Animation.TYPE_VALUE);
					
					newAnim.track_set_path(newTrackRect,str(path,":region_rect"));
					newAnim.track_set_path(newTrackOffset,str(path, ":offset"));
					
					var animLength = 0.0
					for index in anims[k].size():
						var frame=anims[k][index];
						
						var width = int(frame.width); if len(frame.frameWidth) > 0: width = int(frame.frameWidth)
						var height = int(frame.height); if len(frame.frameHeight) > 0: height = int(frame.frameHeight)
						
						var widthcalc = 0; if len(frame.frameWidth) > 0: widthcalc = (int(frame.frameWidth) - int(frame.width))/2
						var heightcalc = 0; if len(frame.frameHeight) > 0: heightcalc = (int(frame.frameHeight) - int(frame.height))/2
				
						var targetCrop=Rect2(int(frame.x),int(frame.y),int(frame.width),int(frame.height));
						var targetOffset=-Vector2(int(frame.frameX) + widthcalc,int(frame.frameY) + heightcalc)+Vector2(objects["offsetX"].value,objects["offsetY"].value);
							
						newAnim.track_insert_key(newTrackRect,index*0.5,targetCrop,0);
						newAnim.track_insert_key(newTrackOffset,index*0.5,targetOffset,0);
						
						animLength += 0.5
						
					newAnim.length = animLength
					var filePath = str(objects["filePath"].current_path) + k + ".tres"
					#removeFile(str(objects["filePath"].current_path).left(-1),objects["name"].text+".tres")
					ResourceSaver.save(newAnim,filePath)
		"AddList":
			var spriteobj = objects2["spriteConTemplate"].duplicate()
			objects2["spriteContainer"].add_child(spriteobj)
			
			var siz = objects2["spriteContainer"].get_children().size()
			spriteobj.name = "Sprite--" + str(siz-1)
			spriteobj.get_node("HBoxContainer/Label").text = "Sprite " + str(siz-1)
			spriteobj.get_node("HBoxContainer/RemoveSprite").pressed.connect(onSpriteRemovalPressed.bind(spriteobj));
			pass
		"SaveAnimPlayer":
			objects2["filePath"].popup();

			await objects2["filePath"].file_selected;
			var AnimPlayer = AnimationPlayer.new()
			for spriteobj in objects2["spriteContainer"].get_children():
				var spritePath = spriteobj.get_node("SpritePath/Path")
				var sheetPath = spriteobj.get_node("SheetPath/Path")
				
				var spritePathText = spritePath.text
				if len(spritePathText) > 0 and spritePathText.ends_with(".png"):
					var sheetPathText = sheetPath.text
					#print(spritePathText)
					if len(sheetPath.text) == 0 and !sheetPath.text.ends_with(".xml"): sheetPathText = spritePathText.replace(".png",".xml")
					var newSprite = FileAccess;
					var newSheet = FileAccess;
					
					spritePathText=str(spritePathText).replace('\\',"/");
					sheetPathText=str(sheetPathText).replace('\\',"/");
					
					if newSprite.file_exists(spritePathText):
						newSprite=load(spritePathText);
					else:
						newSprite=null;

					if newSheet.file_exists(sheetPathText):
						newSheet=ConvertXML(sheetPathText);
					else:
						newSheet=null;
						
					var spriteName = ""
					if spritePathText.rfind("/") != 1:
						spriteName = spritePathText.substr(spritePathText.rfind("/") + 1).replace(".png","")
						#print(spriteName)
					if newSheet:
						var anims = getAllAnims(newSheet)
						var animLib = AnimationLibrary.new()
						for k in anims.keys():
							var newAnim=Animation.new();
							var newTrackRect=newAnim.add_track(Animation.TYPE_VALUE);
							var newTrackOffset=newAnim.add_track(Animation.TYPE_VALUE);
							
							newAnim.track_set_path(newTrackRect,str(":region_rect"));
							newAnim.track_set_path(newTrackOffset,str(":offset"));
							
							var animLength = 0.0
							for index in anims[k].size():
								var frame=anims[k][index];
								
								var width = int(frame.width); if len(frame.frameWidth) > 0: width = int(frame.frameWidth)
								var height = int(frame.height); if len(frame.frameHeight) > 0: height = int(frame.frameHeight)
								
								var widthcalc = 0; if len(frame.frameWidth) > 0: widthcalc = (int(frame.frameWidth) - int(frame.width))/2
								var heightcalc = 0; if len(frame.frameHeight) > 0: heightcalc = (int(frame.frameHeight) - int(frame.height))/2
						
								var targetCrop=Rect2(int(frame.x),int(frame.y),int(frame.width),int(frame.height));
								var targetOffset=-Vector2(int(frame.frameX) + widthcalc,int(frame.frameY) + heightcalc)+Vector2(objects["offsetX"].value,objects["offsetY"].value);
									
								newAnim.track_insert_key(newTrackRect,index*0.5,targetCrop,0);
								newAnim.track_insert_key(newTrackOffset,index*0.5,targetOffset,0);
								
								animLength += 0.5
								
							newAnim.length = animLength
							animLib.add_animation(k,newAnim)
							
						AnimPlayer.add_animation_library(spriteName,animLib)
					else:
						push_error("Sheet for " + sheetPathText + " is null!")
			#print(objects2["filePath"].current_path)
			var packe = PackedScene.new()
			var result = packe.pack(AnimPlayer)
			if result == OK:
				ResourceSaver.save(packe,objects2["filePath"].current_path)
		
	pass;
func onSpriteRemovalPressed(parent:Node):
	objects2["spriteContainer"].remove_child(parent)
	var siz = objects2["spriteContainer"].get_children().size()
	var i = 0
	for spriteobj in objects2["spriteContainer"].get_children():
		spriteobj.name = "Sprite--" + str(i)
		spriteobj.get_node("HBoxContainer/Label").text = "Sprite " + str(i)
		i += 1
#func removeFile(dirPath:String,filePath:String):
#	var dir = DirAccess.open(dirPath)
#	if dir:
#		var path = dirPath+"/"+filePath
#		if dir.file_exists(path):
#			var result = dir.remove(path)
#			if result == OK:
#				#print("FILE REMOVE SUCCESS")
#				pass
#			else:
#				print("FILE REMOVE ERROR")
		
func getAllAnims(sheet = sheet):
	var anims = {}
	for frame in sheet:
		var nam = str(frame.name).left(-4)
		if !anims.has(nam):
			anims[nam] = []
		anims[nam].append(frame);
	return anims
	

func PrefixChanged(newPrefix):
	animation=[];
	if newPrefix!="":
		var newFrames:=[];
		for frame in sheet:
			if str(frame.name).begins_with(newPrefix):
				newFrames.append(frame);
		animation=newFrames;
		Notification("NewAnimation",{});
	else:
		Notification("NoAnimation",{});
	pass;

func OnIndexChanged(val):
	Notification("UpdateSprite",{});
	if animation.size()>0:
		objects["titleFrames"].text=str(val,"/",animation.size()-1)
	else:
		if sheet!=null:
			objects["titleFrames"].text=str(val,"/",sheet.size()-1)
	
func ConvertXML(path):
	var entries:=["name","width","height","frameX","frameY","frameWidth","frameHeight","x","y"];
	var file=XMLParser.new();
	var result=[];
	file.open(path);
	while file.read()==OK:
		if file.get_named_attribute_value_safe("name")!="":
			var frame={};
			for entry in entries:
				frame[entry]=file.get_named_attribute_value_safe(entry)
			result.append(frame);
	return result;
	pass;
