package psychlua;

import substates.GameOverSubstate;

class GifFunctions {
    public static function implement(funk:FunkinLua)
    {
        var lua:State = funk.lua;
        var game:PlayState = PlayState.instance;

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, ?gif:String = null, ?x:Float = 0, ?y:Float = 0) {
			tag = tag.replace('.', '');
			LuaUtils.resetGifTag(tag);
			var leGif:ModchartGif = new ModchartGif(x, y);
			if(gif != null && gif.length > 0)
			{
				leGif.loadGif(Paths.gif(gif));
			}
			game.modchartGif.set(tag, leGif);
			leGif.active = true;
		});
        Lua_helper.add_callback(lua, "addLuaGif", function (tag:String, front:Bool = false) {
            var myGif:FlxSprite = null;
			if(game.modchartGif.exists(tag)) myGif = game.modchartGif.get(tag);
			else if(game.variables.exists(tag)) myGif = game.variables.get(tag);

			if(myGif == null) return false;

			if(front)
				LuaUtils.getTargetInstance().add(myGif);
			else
			{
				if(!game.isDead)
					game.insert(game.members.indexOf(LuaUtils.getLowestCharacterGroup()), myGif);
				else
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), myGif);
			}
			return true;
        });
        Lua_helper.add_callback(lua, "removeLuaGif", function(tag:String, destroy:Bool = true) {
			if(!game.modchartGif.exists(tag)) {
				return;
			}

			var pee:ModchartGif = game.modchartGif.get(tag);
			if(destroy) {
				pee.kill();
			}

			LuaUtils.getTargetInstance().remove(pee, true);
			if(destroy) {
				pee.destroy();
				game.modchartGif.remove(tag);
			}
		});
    }
}