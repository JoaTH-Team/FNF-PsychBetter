#if LUA_ALLOWED
import psychlua.LuaUtils;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class InitState extends flixel.FlxState
{
    #if HSCRIPT_ALLOWED
    public var hscript:HScript;
    public var instancesExclude:Array<String> = [];
    #end
    
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
        var newScript:HScript = null;
        try
        {
            hscript = new HScript(null, file);
            if (hscript.exists('onCreate')) hscript.call('onCreate');
            trace('initialized hscript interp successfully: $file');
        }
        catch(e:IrisError)
        {
            var pos:HScriptInfos = cast {fileName: file, showLine: false};
            Iris.error(Printer.errorToString(e, false), pos);
            var hscript:HScript = cast (Iris.instances.get(file), HScript);
            if(hscript != null)
                hscript.destroy();
        }
    }
    #end
    
    
    public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
        var returnVal:Dynamic = LuaUtils.Function_Continue;
        if(args == null) args = [];
        if(exclusions == null) exclusions = [];
        if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];
    
        var result:Dynamic = null;
        if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
        return result;
    }
    
    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
        var returnVal:Dynamic = LuaUtils.Function_Continue;
    
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = new Array();
        if(excludeValues == null) excludeValues = new Array();
        excludeValues.push(LuaUtils.Function_Continue);
    
        @:privateAccess
        if(hscript != null && hscript.exists(funcToCall)) {
            if(!exclusions.contains(hscript.origin)) {
                var callValue = hscript.call(funcToCall, args);
                if(callValue != null)
                {
                    var myValue:Dynamic = callValue.returnValue;
    
                    if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
                    {
                        returnVal = myValue;
                    }
                    else if(myValue != null && !excludeValues.contains(myValue))
                    {
                        returnVal = myValue;
                    }
                }
            }
        }
        #end
    
        return returnVal;
    }
    
    public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        if(exclusions == null) exclusions = [];
        setOnHScript(variable, arg, exclusions);
    }
    
    public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        if(hscript != null && !exclusions.contains(hscript.origin)) {
            if(!instancesExclude.contains(variable))
                instancesExclude.push(variable);
            hscript.set(variable, arg);
        }
        #end
    }

    public function new() {
        super();

        #if HSCRIPT_ALLOWED
        startHScriptsNamed('states/${Type.getClassName(Type.getClass(this)).split('.').pop()}.hx');
        #end
    }

    override function create():Void
    {
        #if HSCRIPT_ALLOWED
        callOnScripts("onCreate", []);
        #end

        super.create();

        // Flixel

        FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 10;
		FlxG.keys.preventDefaultKeys = [TAB];
        FlxG.drawFramerate = FlxG.updateFramerate = ClientPrefs.data.framerate;
        FlxG.mouse.visible = false;

        // Settings - Controls

        FlxG.save.bind('funkin', CoolUtil.getSavePath());

        Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
        ClientPrefs.loadPrefs();

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
        #if DISCORD_ALLOWED DiscordClient.prepare();#end
        backend.Highscore.load();

        if (FlxG.save.data.weekCompleted != null)
			states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

        if(FlxG.save.data != null && FlxG.save.data.fullscreen)
            FlxG.fullscreen = FlxG.save.data.fullscreen;

        // Lua - Mods

        #if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

        // Cleanup

        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

        // Switch to your initial state
        
        @:privateAccess
            FlxG.switchState(Type.createInstance(Main.game.initialState, []));
        
        #if HSCRIPT_ALLOWED
        callOnScripts("onCreatePost", []);
        #end
    }
}