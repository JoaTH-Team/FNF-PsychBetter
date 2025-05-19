package states;

import flixel.FlxState;
import psychlua.ScriptStateHandler;

class PlayState extends FlxState
{
	public function new() {
		super();

		ScriptStateHandler.setStateForScript('${Type.getClassName(Type.getClass(this)).split('.').pop()}', this, {
			camera: this.camera
		});
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
