package backend;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import backend.PsychCamera;
import psychlua.StateScriptHandler;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	function setScriptState(fileName:String, instance:Dynamic)
		return StateScriptHandler.setStateScript(instance, fileName);

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		StateScriptHandler.callOnScripts("onCreate", []);

		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.6, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;

		StateScriptHandler.callOnScripts("onCreatePost", []);
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		StateScriptHandler.callOnScripts("onUpdate", [elapsed]);

		updateCurStep();
		updateBeat();
		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		
		stagesFunc(function(stage:BaseStage) {
			StateScriptHandler.callOnScripts("onStageUpdate", [elapsed]);

			stage.update(elapsed);

			StateScriptHandler.callOnScripts("onStageUpdatePost", [elapsed]);
		});

		super.update(elapsed);

		StateScriptHandler.callOnScripts("onUpdatePost", [elapsed]);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		StateScriptHandler.callOnScripts("onStepHit", []);

		stagesFunc(function(stage:BaseStage) {
			StateScriptHandler.callOnScripts("onStageStepHit", []);

			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();

			StateScriptHandler.callOnScripts("onStageStepHitPost", []);
		});

		StateScriptHandler.setOnScripts("curStep", curStep);
		StateScriptHandler.setOnScripts("curDecStep", curDecStep);

		if (curStep % 4 == 0)
			beatHit();

		StateScriptHandler.callOnScripts("onStepHitPost", []);
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		StateScriptHandler.callOnScripts("onBeatHit", []);
		stagesFunc(function(stage:BaseStage) {
			StateScriptHandler.callOnScripts("onStageBeatHit", []);

			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();

			StateScriptHandler.callOnScripts("onStageBeatHitPost", []);
		});

		StateScriptHandler.setOnScripts("curBeat", curBeat);
		StateScriptHandler.setOnScripts("curDecBeat", curDecBeat);

		StateScriptHandler.callOnScripts("onBeatHitPost", []);
	}

	public function sectionHit():Void
	{
		StateScriptHandler.callOnScripts("onSectionHit", []);
		stagesFunc(function(stage:BaseStage) {
			StateScriptHandler.callOnScripts("onStageSectionHit", []);
			stage.curSection = curSection;
			stage.sectionHit();
			StateScriptHandler.callOnScripts("onStageSectionHitPost", []);
		});

		StateScriptHandler.setOnScripts("curSection", curSection);

		StateScriptHandler.callOnScripts("onSectionHitPost", []);
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
