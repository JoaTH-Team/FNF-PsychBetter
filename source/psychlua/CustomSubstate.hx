package psychlua;

import flixel.FlxObject;
import flixel.FlxSubState;
import sys.FileSystem;
import sys.io.File;

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

class CustomSubstate extends MusicBeatSubstate
{
    public static var name:String = 'unnamed';
    public static var instance(get, null):CustomSubstate;
    
    #if HSCRIPT_ALLOWED
    public var hscript:HScript;
    public var instancesExclude:Array<String> = [];
    #end

    static function get_instance():CustomSubstate {
        return (FlxG.state != null && FlxG.state.subState is CustomSubstate) 
            ? cast(FlxG.state.subState, CustomSubstate) 
            : null;
    }

    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua) {
        var lua = funk.lua;
        Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
        Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
        Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
    }
    #end
    
    public static function openCustomSubstate(name:String, ?pauseGame:Bool = false) {
        var state = MusicBeatState.getState();
        if (state == null) {
            trace('Cannot open substate - no active state!');
            return false;
        }

        if (pauseGame && Std.isOfType(state, PlayState)) {
            var playState:PlayState = cast state;
            FlxG.camera.followLerp = 0;
            playState.persistentUpdate = false;
            playState.persistentDraw = true;
            playState.paused = true;
            if (FlxG.sound.music != null) {
                FlxG.sound.music.pause();
                playState.vocals.pause();
            }
        }
        
        var substate = new CustomSubstate(name);
        state.openSubState(substate);
        
        if (Std.isOfType(state, PlayState)) {
            var playState:PlayState = cast state;
            playState.setOnHScript('customSubstate', substate);
            playState.setOnHScript('customSubstateName', name);
        }
        return true;
    }

    #if HSCRIPT_ALLOWED
    public function startHScriptsNamed(scriptFile:String) {
        #if MODS_ALLOWED
        var scriptToLoad:String = Paths.modFolders(scriptFile);
        if (!FileSystem.exists(scriptToLoad))
            scriptToLoad = Paths.getSharedPath(scriptFile);
        #else
        var scriptToLoad:String = Paths.getSharedPath(scriptFile);
        #end
    
        if (FileSystem.exists(scriptToLoad)) {
            initHScript(scriptToLoad);
            return true;
        }
        return false;
    }
    
    public function initHScript(file:String) {
        try {
            hscript = new HScript(null, file);
            hscript.execute();
            if (hscript.exists('onCreate')) hscript.call('onCreate');
            trace('initialized hscript interp successfully: $file');
        }
        catch(e:IrisError) {
            var pos:HScriptInfos = cast {fileName: file, showLine: false};
            Iris.error(Printer.errorToString(e, false), pos);
            var hscript:HScript = cast (Iris.instances.get(file), HScript);
            if (hscript != null)
                hscript.destroy();
        }
        catch(e:Dynamic) {
            trace('HScript Error: $e');
        }
    }
    #end

    public static function closeCustomSubstate() {
        if (instance != null) {
            var state = MusicBeatState.getState();
            if (state != null) {
                state.closeSubState();
            }
            instance = null;
            return true;
        }
        return false;
    }

    public static function insertToCustomSubstate(tag:String, ?pos:Int = -1) {
        if (instance == null) return false;
        
        var state = MusicBeatState.getState();
        if (state == null || !Std.isOfType(state, PlayState)) return false;
        
        var playState:PlayState = cast state;
        var tagObject:FlxObject = cast playState.variables.get(tag);
        #if LUA_ALLOWED 
        if (tagObject == null) tagObject = cast playState.modchartSprites.get(tag); 
        #end

        if (tagObject != null) {
            if (pos < 0) instance.add(tagObject);
            else instance.insert(pos, tagObject);
            return true;
        }
        return false;
    }

    override function create() {
        instance = this;
        var state = MusicBeatState.getState();
        
        #if HSCRIPT_ALLOWED
        startHScriptsNamed('substates/$name.hx');
        callOnHScript('onCustomSubstateCreate', [name]);
        #end
        
        if (state != null && Std.isOfType(state, PlayState)) {
            cast(state, PlayState).callOnScripts('onCustomSubstateCreate', [name]);
        }
        
        super.create();
        
        #if HSCRIPT_ALLOWED
        callOnHScript('onCustomSubstateCreatePost', [name]);
        #end
        if (state != null && Std.isOfType(state, PlayState)) {
            cast(state, PlayState).callOnScripts('onCustomSubstateCreatePost', [name]);
        }
    }
    
    public function new(name:String) {
        CustomSubstate.name = name;
        super();
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }
    
    override function update(elapsed:Float) {
        var state = MusicBeatState.getState();
        
        #if HSCRIPT_ALLOWED
        callOnHScript('onCustomSubstateUpdate', [name, elapsed]);
        #end
        if (state != null && Std.isOfType(state, PlayState)) {
            cast(state, PlayState).callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
        }
        
        super.update(elapsed);
        
        #if HSCRIPT_ALLOWED
        callOnHScript('onCustomSubstateUpdatePost', [name, elapsed]);
        #end
        if (state != null && Std.isOfType(state, PlayState)) {
            cast(state, PlayState).callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
        }
    }

    override function destroy() {
        var state = MusicBeatState.getState();
        
        #if HSCRIPT_ALLOWED
        callOnHScript('onCustomSubstateDestroy', [name]);
        #end
        if (state != null && Std.isOfType(state, PlayState)) {
            cast(state, PlayState).callOnScripts('onCustomSubstateDestroy', [name]);
        }
        
        name = 'unnamed';
        instance = null;

        if (state != null && Std.isOfType(state, PlayState)) {
            var playState:PlayState = cast state;
            playState.setOnHScript('customSubstate', null);
            playState.setOnHScript('customSubstateName', name);
        }
        
        super.destroy();
    }

    #if HSCRIPT_ALLOWED
    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic {
        if (args == null) args = [];
        if (hscript != null && hscript.exists(funcToCall))
            return hscript.call(funcToCall, args);
        return null;
    }
    #end
}