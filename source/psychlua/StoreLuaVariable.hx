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

	public static function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

    /**
     * This function gonna clear all variables of each Map
     */
    public static function clean() {
        #if LUA_ALLOWED
        if (variables != null) {
            variables.clear();
            variables = null;
        }

        if (modchartSprites != null) {
            for (sprite in modchartSprites) {
                if (sprite != null) sprite.destroy();
            }
            modchartSprites.clear();
            modchartSprites = null;
        }
        
        if (modchartTexts != null) {
            for (text in modchartTexts) {
                if (text != null) text.destroy();
            }
            modchartTexts.clear();
            modchartTexts = null;
        }

        if (modchartSounds != null) {
            for (sound in modchartSounds) {
                if (sound != null) {
                    sound.stop();
                    sound.destroy();
                }
            }
            modchartSounds.clear();
            modchartSounds = null;
        }

        if (modchartTweens != null) {
            for (tween in modchartTweens) {
                if (tween != null && !tween.finished) tween.cancel();
            }
            modchartTweens.clear();
            modchartTweens = null;
        }

        if (modchartTimers != null) {
            for (timer in modchartTimers) {
                if (timer != null && !timer.finished) timer.cancel();
            }
            modchartTimers.clear();
            modchartTimers = null;
        }
        #end
    }
}
