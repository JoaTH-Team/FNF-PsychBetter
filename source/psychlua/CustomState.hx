package psychlua;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

class CustomState extends MusicBeatState {
    var nameScripts:String = "Nothing";
    var instance:CustomState = null;

    public function new(file:String) {
        super();

        instance = this;

        // idk why
        if (file != null) nameScripts = file;
        else nameScripts = "Nothing";
    }

    override function create() {
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Custom States: " + nameScripts, null);
        #end

        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        StateScriptHandler.setState('$nameScripts', this);
        #end

        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        StateScriptHandler.setOnScripts("initLuaShader", initLuaShader);
        StateScriptHandler.setOnScripts("createRuntimeShader", createRuntimeShader);
        #end

        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        StateScriptHandler.callOnScripts('onCreate', []);
        super.create();
        StateScriptHandler.callOnScripts('onCreatePost', []);
        #else
        super.create(); // prevent cannot compile
        #end
    }

    override function update(elapsed:Float) {
        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        StateScriptHandler.callOnScripts('onUpdate', [elapsed]);
        super.update(elapsed);
        StateScriptHandler.callOnScripts('onUpdatePost', [elapsed]);
        #else
        super.update(elapsed);
        #end
    }

    override function beatHit() {
        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        super.beatHit();
        StateScriptHandler.callOnScripts('onBeatHit', []);
        StateScriptHandler.setOnScripts('curBeat', curBeat);
        StateScriptHandler.setOnScripts('curDecBeat', curDecBeat);
        #else
        super.beatHit();
        #end
    }

    override function stepHit() {
        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        super.stepHit();
        StateScriptHandler.callOnScripts('onStepHit', []);
        StateScriptHandler.setOnScripts('curStep', curStep);
        StateScriptHandler.setOnScripts('curDecStep', curDecBeat);
        #else
        super.stepHit();
        #end
    }

    override function destroy() {
        #if (HSCRIPT_ALLOWED || LUA_ALLOWED)
        StateScriptHandler.callOnScripts('onDestroy', []);
        StateScriptHandler.destroy();
        #end
        
        super.destroy();
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