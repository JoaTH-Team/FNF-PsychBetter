package psychlua;

import flixel.FlxObject;
import flixel.FlxSubState;
import sys.FileSystem;
import sys.io.File;

class CustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;
	
	#if HSCRIPT_ALLOWED
	public var hscript:HScript;
	public var instancesExclude:Array<String> = [];
	#end

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
		Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
		Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
	}
	#end
	
	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if(pauseGame)
		{
			FlxG.camera.followLerp = 0;
			PlayState.instance.persistentUpdate = false;
			PlayState.instance.persistentDraw = true;
			PlayState.instance.paused = true;
			if(FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				PlayState.instance.vocals.pause();
			}
		}
		var substate = new CustomSubstate(name);
		PlayState.instance.openSubState(substate);
		PlayState.instance.setOnHScript('customSubstate', substate);
		PlayState.instance.setOnHScript('customSubstateName', name);
	}

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end
	
		if(FileSystem.exists(scriptToLoad))
		{
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}
	
	public function initHScript(file:String)
	{
		try
		{
			hscript = new HScript(null, file);
			if (hscript.exists('onCreate')) hscript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
		}
		catch(e:Dynamic)
		{
			trace('HScript Error: $e');
			var stack = haxe.CallStack.exceptionStack();
			trace('Stack: ${stack.join("\n")}');
		}
	}
	#end

	public static function closeCustomSubstate()
	{
		if(instance != null)
		{
			if (PlayState.instance != null)
				PlayState.instance.closeSubState();
			instance = null;
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance != null)
		{
			var tagObject:FlxObject = cast (PlayState.instance.variables.get(tag), FlxObject);
			#if LUA_ALLOWED if(tagObject == null) tagObject = cast (PlayState.instance.modchartSprites.get(tag), FlxObject); #end

			if(tagObject != null)
			{
				if(pos < 0) instance.add(tagObject);
				else instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('states/$name.hx');
		callOnHScript('onCustomSubstateCreate', [name]);
		#end
		
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		
		#if HSCRIPT_ALLOWED
		callOnHScript('onCustomSubstateCreatePost', [name]);
		#end
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
	}
	
	public function new(name:String)
	{
		CustomSubstate.name = name;
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function update(elapsed:Float)
	{
		#if HSCRIPT_ALLOWED
		callOnHScript('onCustomSubstateUpdate', [name, elapsed]);
		#end
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		
		super.update(elapsed);
		
		#if HSCRIPT_ALLOWED
		callOnHScript('onCustomSubstateUpdatePost', [name, elapsed]);
		#end
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		#if HSCRIPT_ALLOWED
		callOnHScript('onCustomSubstateDestroy', [name]);
		#end
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		
		name = 'unnamed';
		instance = null;

		if (PlayState.instance != null) {
			PlayState.instance.setOnHScript('customSubstate', null);
			PlayState.instance.setOnHScript('customSubstateName', name);
		}
		super.destroy();
	}

	#if HSCRIPT_ALLOWED
	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		if(args == null) args = [];
		if(hscript != null && hscript.exists(funcToCall))
			return hscript.call(funcToCall, args);
		return null;
	}
	#end
}