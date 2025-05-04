package psychlua;

#if HSCRIPT_ALLOWED
import psychlua.LuaUtils;
import psychlua.HScript;
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class CustomState extends MusicBeatState
{
    #if HSCRIPT_ALLOWED
	var hscript:HScript;
	public function startedHScripts(scriptFile:String)
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
			hscript.execute();
			if (hscript.exists('onCreate')) hscript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			if(hscript != null)
				hscript.destroy();
		}
	}

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null) {
		#if HSCRIPT_ALLOWED
		if(hscript != null)
		{
			if (hscript.exists(funcToCall))
				hscript.executeFunction(funcToCall, args);
		}
		#end
	}
	#end

    public function new(scriptFile:String) {
        super();

        startedHScripts("states/" + scriptFile + ".hx");
    }

    override function create() {
        #if HSCRIPT_ALLOWED
        callOnScripts("onCreate", []);
        #end

        super.create();

        #if HSCRIPT_ALLOWED
		callOnScripts("onCreatePost", []);
		#end

		#if HSCRIPT_ALLOWED
		if (hscript != null) {
			hscript.set("game", MusicBeatState.getState());
		}
		#end
    }

    override function update(elapsed:Float) {
        #if HSCRIPT_ALLOWED
		callOnScripts("onUpdate", [elapsed]);
		#end

        super.update(elapsed);

        #if HSCRIPT_ALLOWED
		callOnScripts("onUpdatePost", [elapsed]);
		#end
    }

    override function beatHit() {
		super.beatHit();

		#if HSCRIPT_ALLOWED
		callOnScripts("onBeatHit", []);
		if (hscript != null) {
			hscript.set("curBeat", curBeat);
			hscript.set("curDecBeat", curDecBeat);
		}
		#end
	}

	override function stepHit() {
		super.stepHit();

		#if HSCRIPT_ALLOWED
		callOnScripts("onStepHit", []);
		if (hscript != null) {
			hscript.set("curStep", curStep);
		}
		#end
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;

		#if HSCRIPT_ALLOWED
		if (hscript != null) {
			hscript.call('onDestroy');
			hscript.destroy();
		}
		#end
	}	
}