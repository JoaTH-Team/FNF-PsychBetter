class InitState extends flixel.FlxState
{
    override function create():Void
    {
        super.create();

        // Flixel

        FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 10;
		FlxG.keys.preventDefaultKeys = [TAB];
        FlxG.drawFramerate = FlxG.updateFramerate = ClientPrefs.data.framerate;
        FlxG.mouse.visible = false;

        // Settings - Controls

        FlxG.save.bind('funkin', CoolUtil.getSavePath());

        Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
        ClientPrefs.loadPrefs();

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
        #if DISCORD_ALLOWED DiscordClient.prepare();#end
        backend.Highscore.load();

        if (FlxG.save.data.weekCompleted != null)
			states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

        if(FlxG.save.data != null && FlxG.save.data.fullscreen)
            FlxG.fullscreen = FlxG.save.data.fullscreen;

        // Lua - Mods

        #if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

        // Cleanup

        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

        // Switch to your initial state
        
        @:privateAccess
            FlxG.switchState(Type.createInstance(Main.game.initialState, []));
    }
}