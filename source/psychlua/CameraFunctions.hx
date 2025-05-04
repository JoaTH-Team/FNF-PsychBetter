package psychlua;

class CameraFunctions {
    public static function implement(funk:FunkinLua)
    {
        var lua = funk.lua;
        var game:PlayState = PlayState.instance;
        Lua_helper.add_callback(lua, "makeLuaCamera", function (tag:String) {
            tag = tag.replace('.', '');
            LuaUtils.resetCameraTag(tag);
            var camera = new FlxCamera();
            camera.bgColor = FlxColor.TRANSPARENT;
            camera.active = true;
            game.modchartCameras.set(tag, camera);
        });
        Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '') {
			var real = game.getLuaObject(obj);
			if(real!=null){
				real.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}

			var split:Array<String> = obj.split('.');
			var object:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(object != null) {
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			FunkinLua.luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
        Lua_helper.add_callback(lua, "addLuaCamera", function (tag:String, defaultDraw:Bool) {
			if(game.modchartCameras.exists(tag)) {
				var shit:FlxCamera = game.modchartCameras.get(tag);
				FlxG.cameras.add(shit, defaultDraw);
			}
        });
		Lua_helper.add_callback(lua, "removeLuaCamera", function (tag:String, destroy:Bool = true) {
			if(!game.modchartCameras.exists(tag)) {
				return;
			}

			var pee:FlxCamera = game.modchartCameras.get(tag);
			FlxG.cameras.remove(pee, destroy);
			game.modchartTexts.remove(tag);
		});
    }
}