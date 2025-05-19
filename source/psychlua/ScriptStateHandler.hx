package psychlua;

import flixel.util.FlxColor;
import sys.FileSystem;
import tea.SScript;

class ScriptStateHandler {
    public static var hscriptArray:Array<HScript> = [];
    public static var instancesExclude:Array<String> = [];

	public static function setStateForScript(name:String, ?statesInstance:Dynamic, ?setAnyVar:Any = null)
	{
		startHScriptsNamed('states/$name.hx', setAnyVar);
		setOnScripts('game', statesInstance);
	}

	public static function startHScriptsNamed(scriptFile:String, ?setAnyVar:Any = null)
	{
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad))
		{
			scriptToLoad = 'assets/states/' + scriptFile.split('/').pop();
		}

		if(FileSystem.exists(scriptToLoad))
		{
			initHScript(scriptToLoad, setAnyVar);
			return true;
		}
		else
		{
			addTextToDebug('Script file not found: ' + scriptToLoad, FlxColor.RED);
		}
		return false;
	}

	public static function initHScript(file:String, ?setAnyVar:Any = null)
	{
		try
		{
			var newScript:HScript = new HScript(null, file, setAnyVar);
			if(newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in (callValue.exceptions : Array<Dynamic>))
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if(len <= 0) len = e.message.length;
								addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
						}
					}

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize tea interp!!! ($file)');
				}
				else trace('initialized tea interp successfully: $file');
			}
			trace('added tea interp: $file');
		}
		catch(e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if(len <= 0) len = e.message.length;
			addTextToDebug('ERROR - ' + e.message.substr(0, len), FlxColor.RED);
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}

    public static function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = null;
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

    public static function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
					{
						var len:Int = e.message.indexOf('\n') + 1;
						if(len <= 0) len = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
					}
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}

		return returnVal;
	}

    public static function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnHScript(variable, arg, exclusions);
	}

	public static function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			if(!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
	}
}