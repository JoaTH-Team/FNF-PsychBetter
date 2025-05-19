package psychlua;

import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;

class ScriptTraceHandler extends Sprite
{
	private var MAX_TRACES:Int = 39; // good for overlaps the screen
    private var DISPLAY_TIME:Float = 5000;
    private var FADE_TIME:Float = 2000;
    
    private var traces:Array<TraceDisplay>;
    private var yOffset:Float = 0;
    
    public function new() {
        super();
        traces = [];
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
    }
    
    private function onEnterFrame(e:Event):Void {
        var dt:Float = 1000 / openfl.Lib.current.stage.frameRate;
        
        // update trace
        var i:Int = 0;
        while (i < traces.length) {
            var trace = traces[i];
            trace.update(dt);
            
            if (!trace.visible) {
                removeChild(trace);
                traces.remove(trace);
                
                reposTrace();
            }
            i++;
        }
    }
    
    public function scriptTrace(text:String, ?color:FlxColor = FlxColor.WHITE):Void {
        var traceDisplay = new TraceDisplay();
        traceDisplay.text = text;
        traceDisplay.x = 10;
        traceDisplay.y = yOffset;
        traceDisplay.defaultTextFormat.color = color;
        traceDisplay.alpha = 1;
        traceDisplay.visible = true;
        traceDisplay.aliveTime = 0;
        
        Lib.current.stage.addChild(traceDisplay);
        traces.push(traceDisplay);
        
        yOffset += traceDisplay.textHeight + 5;
        
        if (traces.length > MAX_TRACES) {
            var oldest = traces.shift();
            if (Lib.current.stage.contains(oldest))
                Lib.current.stage.removeChild(oldest);
            
            reposTrace();
        }
        trace(text); // display text on terminal also
    }
    
    private function reposTrace():Void {
        yOffset = 0;
        for (trace in traces) {
            trace.y = yOffset;
            yOffset += trace.textHeight + 5;
        }
    }
    
    public function destroy():Void {
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        for (trace in traces) {
            if (contains(trace))
                removeChild(trace);
        }
        traces = null;
    }
}