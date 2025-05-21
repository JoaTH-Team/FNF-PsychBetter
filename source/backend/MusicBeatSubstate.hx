package backend;

import psychlua.StateScriptHandler;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	function setScriptState(fileName:String, instance:Dynamic)
		return StateScriptHandler.setStateScript(instance, fileName);

	override function create()
	{
		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onCreate', []);
		#end

		super.create();

		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onCreatePost', []);
		#end
	}

	override function update(elapsed:Float)
	{
		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onUpdate', [elapsed]);
		#end

		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

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

		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onUpdatePost', [elapsed]);
		#end
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

	public function stepHit():Void
	{
		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onStepHit', []);
		StateScriptHandler.setOnScripts('curStep', curStep);
		StateScriptHandler.setOnScripts('curDecStep', curDecStep);
		#end

		if (curStep % 4 == 0)
			beatHit();

		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onStepHitPost', []);
		#end
	}

	public function beatHit():Void
	{
		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onBeatHit', []);
		StateScriptHandler.setOnScripts('curBeat', curBeat);
		StateScriptHandler.setOnScripts('curDecBeat', curDecBeat);
		StateScriptHandler.callOnScripts('onBeatHitPost', []);
		#end
	}
	
	public function sectionHit():Void
	{
		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnScripts('onSectionHit', []);
		StateScriptHandler.setOnScripts('curSection', curSection);
		StateScriptHandler.callOnScripts('onSectionHitPost', []);
		#end
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
