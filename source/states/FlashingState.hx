package states;

import flixel.FlxSubState;

import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState
{
    public function new() {
        super();

        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        StateScriptHandler.setState('${Type.getClassName(Type.getClass(this)).split('.').pop()}', this);
        #end
    }

	public static var leftState:Bool = false;

	public var warnText:FlxText;
	public var bg:FlxSprite;

	override function create()
	{
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		StateScriptHandler.callOnScripts("onCreate", []);
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

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		StateScriptHandler.callOnScripts("onCreatePost", []);
		#end
	}

	override function update(elapsed:Float)
	{
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		StateScriptHandler.callOnScripts("onUpdate", [elapsed]);
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

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		StateScriptHandler.callOnScripts("onUpdatePost", [elapsed]);
		#end
	}

	override function destroy():Void
	{
        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        StateScriptHandler.callOnScripts('onDestroy', []);
        super.destroy();
        #else
        super.destroy();
        #end
	}	

	override function beatHit() {
        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        super.beatHit();
        StateScriptHandler.callOnScripts('onBeatHit', []);
        StateScriptHandler.setOnScripts('curBeat', curBeat);
        StateScriptHandler.setOnScripts('curDecBeat', curDecBeat);
        #else
        super.beatHit();
        #end
    }

    override function stepHit() {
        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        super.stepHit();
        StateScriptHandler.callOnScripts('onStepHit', []);
        StateScriptHandler.setOnScripts('curStep', curStep);
        StateScriptHandler.setOnScripts('curDecStep', curDecBeat);
        #else
        super.stepHit();
        #end
    }
}
