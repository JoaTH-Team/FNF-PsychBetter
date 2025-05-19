package psychlua;

import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.text.TextField;
import openfl.text.TextFormat;

class TraceDisplay extends TextField
{
    public var format:TextFormat;
    public var aliveTime:Float = 0;
    public var alphaMult:Float = 1;
    public var curWidth:Float = 0;

    public function new() {
        super();

		format = new TextFormat(Paths.font("phantommuff.ttf"), 18, FlxColor.WHITE);

        defaultTextFormat = format;
        format.letterSpacing = -.5;
		format.leading = -2;
		multiline = true;
		wordWrap = true;
    }

	public function update(dt:Float) {
		if (!visible) return;
		
		aliveTime += dt;
		
		if (aliveTime >= 5000) {
			if (aliveTime < 5000 + 2000) {
				alpha = (1 - (aliveTime - 5000) / 2000) * alphaMult;
			} else {
				visible = false;
			}
		}
		
		updateWidth();
	}
	
	public function updateWidth():Void {
		var targetWidth:Float = FlxG.stage.window.width - x * 2;
		if (curWidth != targetWidth)
			curWidth = width = targetWidth;
	}
}