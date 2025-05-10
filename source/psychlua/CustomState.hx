package psychlua;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class CustomState extends MusicBeatState {
	public static var instance:CustomState;
	#if LUA_ALLOWED public var lua:FunkinLua; #end

    #if HSCRIPT_ALLOWED
    public var hscript:HScript;
    public var instancesExclude:Array<String> = [];
    #end

    #if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
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

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

    public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
        var returnVal:Dynamic = LuaUtils.Function_Continue;
        #if LUA_ALLOWED
        if(args == null) args = [];
        if(exclusions == null) exclusions = [];
        if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

        if(lua.closed)
            return returnVal;

        if(exclusions.contains(lua.scriptName))
            return returnVal;

        var myValue:Dynamic = lua.call(funcToCall, args);
        if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
        {
            returnVal = myValue;
        }
        else if(myValue != null && !excludeValues.contains(myValue))
        {
            returnVal = myValue;
        }
        #end
        return returnVal;
    }
    
    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
        try {
        	var returnVal:Dynamic = LuaUtils.Function_Continue;
        	#if HSCRIPT_ALLOWED
        	if (exclusions == null)
        		exclusions = new Array();
        	if (excludeValues == null)
        		excludeValues = new Array();
        	excludeValues.push(LuaUtils.Function_Continue);
        	@:privateAccess
        	if (hscript != null && hscript.exists(funcToCall))
        	{
        		if (!exclusions.contains(hscript.origin))
        		{
        			var callValue = hscript.call(funcToCall, args);
        			if (callValue != null)
        			{
        				var myValue:Dynamic = callValue.returnValue;
        				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
        					&& !excludeValues.contains(myValue)
        					&& !ignoreStops)
        				{
        					returnVal = myValue;
        				}
        				else if (myValue != null && !excludeValues.contains(myValue))
        				{
        					returnVal = myValue;
        				}
        			}
        		}
        	}
        	#end
        	return returnVal;
        }
        catch (e:IrisError)
        {
            Iris.error(Printer.errorToString(e, false));
            return null;
        }
    }
    
    public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        if(exclusions == null) exclusions = [];
        setOnHScript(variable, arg, exclusions);
    }

    public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		// if(exclusions.contains(lua.scriptName))
		// 	continue;
        if (lua != null && !exclusions.contains(lua.scriptName))
        {
            if (!instancesExclude.contains(variable))
                instancesExclude.push(variable);
        }
		lua.set(variable, arg);
		#end
	}
    
    public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        try {
            #if HSCRIPT_ALLOWED
            if (exclusions == null)
                exclusions = [];
            if (hscript != null && !exclusions.contains(hscript.origin))
            {
                if (!instancesExclude.contains(variable))
                    instancesExclude.push(variable);
                hscript.set(variable, arg);
            }
            #end
        }
        catch (e:IrisError)
        {
            Iris.error(Printer.errorToString(e, false));
        }
    }

    var nameScripts:String = "Nothing";

    public function new(file:String) {
        super();

        #if HSCRIPT_ALLOWED
        startHScriptsNamed('states/$file.hx');
        startLuasNamed('states/$file.lua');
        #end
        
        // idk why
        if (file != null) nameScripts = file;
        else nameScripts = "Nothing";
    }

    override function create() {
        #if DISCORD_ALLOWED
		DiscordClient.changePresence("Custom States: " + nameScripts, null);
		#end

        #if HSCRIPT_ALLOWED
        setOnScripts("game", this);
        setOnScripts("initLuaShader", initLuaShader);
        setOnScripts("createRuntimeShader", createRuntimeShader);
        #end

        #if HSCRIPT_ALLOWED
        callOnScripts('onCreate', []);
        super.create();
        callOnScripts('onCreatePost', []);
        #else
        super.create(); // prevent cannot compile
        #end
    }

    override function update(elapsed:Float) {
        #if HSCRIPT_ALLOWED
        callOnScripts('onUpdate', [elapsed]);
        super.update(elapsed);
        callOnScripts('onUpdatePost', [elapsed]);
        #else
        super.update(elapsed);
        #end
    }

    override function beatHit() {
        #if HSCRIPT_ALLOWED
        super.beatHit();
        callOnScripts('onBeatHit', []);
        setOnHScript('curBeat', curBeat);
        setOnHScript('curDecBeat', curDecBeat);
        #else
        super.beatHit();
        #end
    }

    override function stepHit() {
        #if HSCRIPT_ALLOWED
        super.stepHit();
        callOnScripts('onStepHit', []);
        setOnHScript('curStep', curStep);
        setOnHScript('curDecStep', curDecBeat);
        #else
        super.stepHit();
        #end
    }

    override function destroy() {
        #if HSCRIPT_ALLOWED
        callOnScripts('onDestroy', []);
        super.destroy();
        #else
        super.destroy();
        #end
    }

    #if sys
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if sys
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (LUA_ALLOWED && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				return true;
			}
		}
            FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end
}