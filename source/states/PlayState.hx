package states;

import flixel.FlxState;
import psychlua.ScriptStateHandler;

class PlayState extends FlxState
{
	public function new() {
		super();

		ScriptStateHandler.setStateForScript('PlayState', this, [
			{name: "camera", value: camera},
		]);
	}
	
	override public function create()
	{
		ScriptStateHandler.callOnScripts("onCreate", []);
		
		super.create();

		ScriptStateHandler.callOnScripts("onCreatePost", []);
	}

	override public function update(elapsed:Float)
	{
		ScriptStateHandler.callOnScripts("onUpdate", [elapsed]);

		super.update(elapsed);

		ScriptStateHandler.callOnScripts("onUpdatePost", [elapsed]);
	}
}
