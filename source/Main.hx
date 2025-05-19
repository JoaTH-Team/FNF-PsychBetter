package;

import backend.WindowsAPI;
import debug.FPSCounter;
import flixel.FlxGame;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import psychlua.HScript;
import psychlua.ScriptTraceHandler;
import states.PlayState;

class Main extends Sprite
{
	public static var fpsVar:FPSCounter;
	public static var scriptTraceVar:ScriptTraceHandler;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	static var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: PlayState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: false, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};
	
	public function new()
	{
		super();
		WindowsAPI.fixScaling();
		WindowsAPI.darkMode(true);

		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		
		fpsVar = new FPSCounter();
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		addChild(fpsVar);

		scriptTraceVar = new ScriptTraceHandler();
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		addChild(scriptTraceVar);
	}
	public static function addTextToDebug(text:String, ?withNameScript:Bool = true, ?color:FlxColor = FlxColor.WHITE):Void
	{
		var msg = (withNameScript ? HScript.nameScript + ": " : "") + text;
		scriptTraceVar.scriptTrace(msg, color);
	}
}
