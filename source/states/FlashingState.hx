package states;

import flixel.FlxSubState;

import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState
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

	public static var leftState:Bool = false;

	public var warnText:FlxText;
	public var bg:FlxSprite;

	override function create()
	{
		#if HSCRIPT_ALLOWED
		callOnScripts("onCreate", []);
		#end

		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		#if HSCRIPT_ALLOWED
		callOnScripts("onCreatePost", []);
		#end
	}

	override function update(elapsed:Float)
	{
		#if HSCRIPT_ALLOWED
		callOnScripts("onUpdate", [elapsed]);
		#end

		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.data.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		callOnScripts("onUpdatePost", [elapsed]);
		#end
	}

	override function destroy():Void
	{
        #if HSCRIPT_ALLOWED
        callOnScripts('onDestroy', []);
        super.destroy();
        #else
        super.destroy();
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
}
