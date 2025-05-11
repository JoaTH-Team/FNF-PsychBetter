package psychlua;

class StoreLuaVariable {
    #if LUA_ALLOWED
    public static var variables:Map<String, Dynamic>;
    public static var modchartSprites:Map<String, FlxSprite>;
    public static var modchartTexts:Map<String, FlxText>;
    public static var modchartSounds:Map<String, FlxSound>;
    public static var modchartTweens:Map<String, FlxTween>;
    public static var modchartTimers:Map<String, FlxTimer>;
    #end
}
