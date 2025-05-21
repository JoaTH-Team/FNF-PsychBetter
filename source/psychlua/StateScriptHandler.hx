package psychlua;

import flixel.FlxState;

class StateScriptHandler {
    #if HSCRIPT_ALLOWED
    public static var hscript:HScript;
    public static var instancesExclude:Array<String> = [];
    #end

    public static function setStateScript(state:FlxState, fileName:String):Void {
        #if HSCRIPT_ALLOWED
        if(hscript != null)
        {
            hscript.destroy();
            hscript = null;
        }
        #end

        if(state != null)
        {
            startHScriptsNamed("states/" + fileName + ".hx");
            setOnScripts('game', state);
        }
    }

    #if HSCRIPT_ALLOWED
    public static function startHScriptsNamed(scriptFile:String)
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

    public static function initHScript(file:String)
    {
        try
        {
            var newScript:HScript = new HScript(null, file);
            if(newScript.parsingException != null)
            {
                trace('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
                newScript.destroy();
                return;
            }

            if(hscript != null) hscript.destroy();
            hscript = newScript;
            if(newScript.exists('onCreate'))
            {
                var callValue = newScript.call('onCreate');
                if(!callValue.succeeded)
                {
                    for (e in callValue.exceptions)
                    {
                        if (e != null)
                        {
                            var len:Int = e.message.indexOf('\n') + 1;
                            if(len <= 0) len = e.message.length;
                                trace('ERROR ($file: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
                        }
                    }

                    newScript.destroy();
                    hscript = null;
                    trace('failed to initialize tea interp!!! ($file)');
                }
                else trace('initialized tea interp successfully: $file');
            }

        }
        catch(e)
        {
            var len:Int = e.message.indexOf('\n') + 1;
            if(len <= 0) len = e.message.length;
            trace('ERROR - ' + e.message.substr(0, len), FlxColor.RED);
            if(hscript != null)
            {
                hscript.destroy();
                hscript = null;
            }
        }
    }
    #end

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

        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = new Array();
        if(excludeValues == null) excludeValues = new Array();
        excludeValues.push(LuaUtils.Function_Continue);

        if (hscript == null)
            return returnVal;
        if(hscript.exists(funcToCall) && !exclusions.contains(hscript.origin))
        {
            var myValue:Dynamic = null;
            try {
                var callValue = hscript.call(funcToCall, args);
                if(!callValue.succeeded)
                {
                    var e = callValue.exceptions[0];
                    if(e != null)
                    {
                        var len:Int = e.message.indexOf('\n') + 1;
                        if(len <= 0) len = e.message.length;
                        trace('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
                    }
                }
                else
                {
                    myValue = callValue.returnValue;
                    if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
                    {
                        returnVal = myValue;
                    }
                    else if(myValue != null && !excludeValues.contains(myValue))
                        returnVal = myValue;
                }
            }
            catch(e) {}
        }
        #end

        return returnVal;
    }

    public static function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        if(exclusions == null) exclusions = [];
        setOnHScript(variable, arg, exclusions);
    }

    public static function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        if(hscript != null && !exclusions.contains(hscript.origin))
        {
            if(!instancesExclude.contains(variable))
                instancesExclude.push(variable);
            hscript.set(variable, arg);
        }
        #end
    }
}