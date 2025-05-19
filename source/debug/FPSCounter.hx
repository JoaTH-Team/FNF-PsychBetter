package debug;

import flixel.FlxG;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

#if cpp
import cpp.vm.Gc;
#end

/**
 * Enhanced FPS counter with accurate metrics and detailed performance information
 */
class FPSCounter extends TextField
{
    public var currentFPS(default, null):Int;
    public var smoothedFPS(default, null):Float;
    public var frameTimeAvg(default, null):Float;
    public var frameTimeMax(default, null):Float;
    public var frameTimeMin(default, null):Float;
    
    public var memoryMegas(get, never):Float;
    
    // config
    public var smoothingFactor:Float = 0.9;
    
    @:noCompletion private var times:Array<Float>;
    @:noCompletion private var frameTimes:Array<Float>;
    @:noCompletion private var frameTimeSum:Float = 0;
    @:noCompletion private var deltaTimeout:Float = 0.0;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
    {
        super();

        this.x = x;
        this.y = y;

        currentFPS = 0;
        smoothedFPS = 0;
        frameTimeAvg = 0;
        frameTimeMax = 0;
        frameTimeMin = 0;
        
        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat(Paths.font("phantommuff.ttf"), 14, color);
        autoSize = LEFT;
        multiline = true;
        text = "FPS: ";

        times = [];
        frameTimes = [];
    }

    private override function __enterFrame(deltaTime:Float):Void
    {
        if (deltaTimeout > 1000) {
            deltaTimeout = 0.0;
            return;
        }

        final now:Float = haxe.Timer.stamp() * 1000;
        
        times.push(now);
        while (times[0] < now - 1000) {
            times.shift();
        }

        frameTimes.push(deltaTime);
        frameTimeSum += deltaTime;
        while (frameTimes.length > times.length) {
            frameTimeSum -= frameTimes.shift();
        }

        calculateMetrics(now, deltaTime);
        updateText();
        deltaTimeout += deltaTime;
    }

    private function calculateMetrics(now:Float, deltaTime:Float):Void
    {
        var rawFPS:Float = 0;
        if (times.length > 1) {
            var elapsed = now - times[0];
            rawFPS = times.length * 1000 / elapsed;
        }

        if (smoothedFPS == 0) {
            smoothedFPS = rawFPS;
        } else {
            smoothedFPS = smoothingFactor * smoothedFPS + (1 - smoothingFactor) * rawFPS;
        }

        currentFPS = Math.round(smoothedFPS);
        
        if (currentFPS > FlxG.updateFramerate) {
            currentFPS = FlxG.updateFramerate;
        }

        if (frameTimes.length > 0) {
            frameTimeAvg = frameTimeSum / frameTimes.length;
            frameTimeMax = Math.NEGATIVE_INFINITY;
            frameTimeMin = Math.POSITIVE_INFINITY;
            
            for (time in frameTimes) {
                if (time > frameTimeMax) frameTimeMax = time;
                if (time < frameTimeMin) frameTimeMin = time;
            }
        }
    }

    public dynamic function updateText():Void {
        var mem = flixel.util.FlxStringUtil.formatBytes(memoryMegas);
        text = 'FPS: ${currentFPS} (Max FPS: ${FlxG.updateFramerate})'
            + '\nFrame Time: ${Math.round(frameTimeAvg)}ms'
            + '\n(Min: ${Math.round(frameTimeMin)}ms, Max: ${Math.round(frameTimeMax)}ms)'
            + '\nMemory: ${mem}';

        textColor = 0xFFFFFFFF;
        if (currentFPS < FlxG.drawFramerate * 0.5) {
            textColor = 0xFFFF0000;
        }
        else if (frameTimeAvg > (1000 / FlxG.updateFramerate) * 1.2) {
            textColor = 0xFFFFFF00;
        }
    }

    inline function get_memoryMegas():Float {
        return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
    }
}