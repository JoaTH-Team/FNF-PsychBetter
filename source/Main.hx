package;

import debug.FPSCounter;
import flixel.FlxGame;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import openfl.display.Sprite;
import psychlua.ScriptTraceHandler;
import states.PlayState;

class Main extends Sprite
{
	public static var fpsVar:FPSCounter;
	public static var scriptTraceVar:ScriptTraceHandler;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, PlayState));
		fpsVar = new FPSCounter();
		addChild(fpsVar);

		scriptTraceVar = new ScriptTraceHandler();
		addChild(scriptTraceVar);
	}
	public static function addTextToDebug(text:String, ?color:FlxColor = FlxColor.WHITE):Void
		return scriptTraceVar.scriptTrace(text, color);
}
