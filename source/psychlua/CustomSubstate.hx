package psychlua;

import flixel.FlxState;
import flixel.FlxObject;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

class CustomSubstate extends MusicBeatSubstate
{
    public static var name:String = 'unnamed';
    public static var instance:CustomSubstate;
    
    #if HSCRIPT_ALLOWED
    public var hscript:HScript;
    public var instancesExclude:Array<String> = [];
    #end
    
    #if sys
    public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
    #end

    // Reference to parent state to avoid direct PlayState.instance access
    public var parentState:FlxState;

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
        if(instance != null) return;
        
        var playState = Type.getClassName(Type.getClass(FlxG.state)) == "PlayState" ? cast(FlxG.state, PlayState) : null;
        if(playState == null) return;
        
        if(pauseGame)
        {
            FlxG.camera.followLerp = 0;
            playState.persistentUpdate = false;
            playState.persistentDraw = true;
            playState.paused = true;
            if(FlxG.sound.music != null) {
                FlxG.sound.music.pause();
                playState.vocals.pause();
            }
        }
        
        var substate = new CustomSubstate(name, playState);
        playState.openSubState(substate);
        playState.setOnHScript('customSubstate', instance);
        playState.setOnHScript('customSubstateName', name);
    }

    public static function closeCustomSubstate():Bool
    {
        if (instance != null && instance.parentState != null) {
            instance.parentState.closeSubState();
            instance.cameras = [];
            instance.members = [];
            instance.clear();
            instance.destroy();
            instance.kill();
            instance.close();
            return true;
        }
        return false;
    }

    public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
    {
        if(instance != null)
        {
            var playState = Type.getClassName(Type.getClass(FlxG.state)) == "PlayState" ? cast(FlxG.state, PlayState) : null;
            if(playState == null) return false;
            
            var tagObject:FlxObject = cast (playState.variables.get(tag), FlxObject);
            #if LUA_ALLOWED if(tagObject == null) tagObject = cast (playState.modchartSprites.get(tag), FlxObject); #end

            if(tagObject != null)
            {
                if(pos < 0) instance.add(tagObject);
                else instance.insert(pos, tagObject);
                return true;
            }
        }
        return false;
    }

    #if sys
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

    override function create()
    {
        instance = this;

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Custom Substate: " + name, null);
        #end

        if(parentState != null && Std.isOfType(parentState, PlayState))
        {
            var playState:PlayState = cast parentState;
            playState.callOnScripts('onCustomSubstateCreate', [name]);
        }

        super.create();
        
        if(parentState != null && Std.isOfType(parentState, PlayState))
        {
            var playState:PlayState = cast parentState;
            playState.callOnScripts('onCustomSubstateCreatePost', [name]);
        }
    }
    
    override function update(elapsed:Float)
    {
        if(parentState != null && Std.isOfType(parentState, PlayState))
        {
            var playState:PlayState = cast parentState;
            playState.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
        }

        super.update(elapsed);
        
        if(parentState != null && Std.isOfType(parentState, PlayState))
        {
            var playState:PlayState = cast parentState;
            playState.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
        }
    }
    
    public function new(name:String, parentState:FlxState)
    {
        CustomSubstate.name = name;
        this.parentState = parentState;
        super();
        if (parentState != null && Std.isOfType(parentState, PlayState)) {
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}
        
        #if HSCRIPT_ALLOWED
        setScriptState('states/$name.hx', parentState);
        #end
    }
}