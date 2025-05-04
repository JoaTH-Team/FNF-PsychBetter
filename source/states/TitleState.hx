package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import openfl.Assets;
import shaders.ColorSwap;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Float
}

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	public var blackScreen:FlxSprite;
	public var credGroup:FlxGroup;
	public var credTextShit:Alphabet;
	public var textGroup:FlxGroup;
	public var ngSpr:FlxSprite;
	
	public var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	public var titleTextAlphas:Array<Float> = [1, .64];

	public var curWacky:Array<String> = [];
	public var wackyImage:FlxSprite;
	public var skippedIntro:Bool = false;
	public var titleJSON:TitleData;

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

	override public function create()
	{
		#if HSCRIPT_ALLOWED
		super.create();
		callOnScripts("onCreate", []);
		#end

		curWacky = FlxG.random.getObject(getIntroTextShit());
		titleJSON = tjson.TJSON.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		if(!initialized)
		{
			persistentUpdate = true;
			persistentDraw = true;
		}

		FlxG.mouse.visible = false;

		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			if (initialized)
				startIntro();
			else
				new FlxTimer().start(1, function(tmr:FlxTimer) startIntro());
		}

		#if HSCRIPT_ALLOWED
		callOnScripts("onCreatePost", []);
		#end
	}

	public var logoBl:FlxSprite;
	public var gfDance:FlxSprite;
	public var danceLeft:Bool = false;
	public var titleText:FlxSprite;
	public var swagShader:ColorSwap = null;

	function startIntro()
	{
		if (!initialized)
			if(FlxG.sound.music == null)
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		bg.antialiasing = ClientPrefs.data.antialiasing;

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}
		add(bg);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		if(ClientPrefs.data.shaders) swagShader = new ColorSwap();
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		add(gfDance);
		add(logoBl);
		if(swagShader != null)
		{
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		if (initialized)
			skipIntro();
		else
			initialized = true;

		Paths.clearUnusedMemory();
		#if HSCRIPT_ALLOWED
		callOnScripts("onStartIntro", []);
		#end
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt', Paths.getSharedPath());
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		return [for (i in firstArray) i.split('--')];
	}

	public var transitioning:Bool = false;
	public var newTitle:Bool = false;
	public var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		#if HSCRIPT_ALLOWED
		callOnScripts("onUpdate", [elapsed]);
		#end

		var pressedEnter:Bool = controls.ACCEPT;
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;

				if(titleText != null) titleText.animation.play('press');
				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				transitioning = true;
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		callOnScripts("onUpdatePost", [elapsed]);
		#end
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					//FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['The', 'Funkin Crew Inc']);
				case 4:
					addMoreText('presents');
				case 5:
					deleteCoolText();
				case 6:
					createCoolText(['In association', 'with'], -40);
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Friday');
				case 15:
					// from vslice/base game:
					// easter egg for when the game is trending with the wrong spelling
					// the random intro text would be "trending--only on x"
					if (curWacky[0] == "trending") addMoreText('Nigth');
					else addMoreText('Night');
				case 16:
					addMoreText('Funkin');
				case 17:
					skipIntro();
			}
		}

		#if HSCRIPT_ALLOWED
		callOnScripts("onBeatHit", []);
		setOnScripts("curBeat", curBeat);
		setOnScripts("curDecBeat", curDecBeat);
		setOnScripts("sickBeats", sickBeats);
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

    override function destroy() {
        #if HSCRIPT_ALLOWED
        callOnScripts('onDestroy', []);
        super.destroy();
        #else
        super.destroy();
        #end
    }

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);
			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}
