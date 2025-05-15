package backend;

import lime.app.Application;
import lime.system.Display;
import lime.system.System;

#if windows
@:buildXml('
    <target id="haxe">
        <lib name="dwmapi.lib" if="windows" />
        <lib name="gdi32.lib" if="windows" />
        <lib name="user32.lib" if="windows" />
    </target>
')
@:cppFileCode('
    #include <Windows.h>
    #include <cstdio>
    #include <iostream>
    #include <tchar.h>
    #include <dwmapi.h>
    #include <winuser.h>
    #include <wingdi.h>

    #ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
    #define DWMWA_USE_IMMERSIVE_DARK_MODE 20 // support for windows 11
    #endif

    struct HandleData {
        DWORD pid = 0;
        HWND handle = 0;
    };

    BOOL CALLBACK findByPID(HWND handle, LPARAM lParam) {
        DWORD targetPID = ((HandleData*)lParam)->pid;
        DWORD curPID = 0;

        GetWindowThreadProcessId(handle, &curPID);
        if (targetPID != curPID || GetWindow(handle, GW_OWNER) != (HWND)0 || !IsWindowVisible(handle)) {
            return TRUE;
        }

        ((HandleData*)lParam)->handle = handle;
        return FALSE;
    }

    HWND curHandle = 0;
    void getHandle() {
        if (curHandle == (HWND)0) {
            HandleData data;
            data.pid = GetCurrentProcessId();
            EnumWindows(findByPID, (LPARAM)&data);
            curHandle = data.handle;
        }
    }
')
#end
class Native
{
    public static function __init__():Void
    {
        registerDPIAware();
    }

    public static function registerDPIAware():Void
    {
        #if windows
        // DPI Scaling fix for windows 
        // this shouldn't be needed for other systems
        untyped __cpp__('
            SetProcessDPIAware();	
            #ifdef DPI_AWARENESS_CONTEXT
            SetProcessDpiAwarenessContext(
                #ifdef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
                DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
                #else
                DPI_AWARENESS_CONTEXT_SYSTEM_AWARE
                #endif
            );
            #endif
        ');
        #end
    }

    private static var fixedScaling:Bool = false;
    public static function fixScaling():Void
    {
        if (fixedScaling) return;
        fixedScaling = true;

        #if windows
        final display:Null<Display> = System.getDisplay(0);
        if (display != null)
        {
            final dpiScale:Float = display.dpi / 96;
            @:privateAccess Application.current.window.width = Std.int(Main.game.width * dpiScale);
            @:privateAccess Application.current.window.height = Std.int(Main.game.height * dpiScale);

            Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
            Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
        }

        untyped __cpp__('
            getHandle();
            if (curHandle != (HWND)0) {
                HDC curHDC = GetDC(curHandle);
                RECT curRect;
                GetClientRect(curHandle, &curRect);
                FillRect(curHDC, &curRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
                ReleaseDC(curHandle, curHDC);
            }
        ');
        #end
    }

    #if windows
    @:functionCode('
        int darkMode = enable ? 1 : 0;
        HWND window = GetActiveWindow();
        if (S_OK != DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, reinterpret_cast<LPCVOID>(&darkMode), sizeof(darkMode)))
            DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, reinterpret_cast<LPCVOID>(&darkMode), sizeof(darkMode));
    ')
    public static function setDarkMode(enable:Bool) {}

    public static function darkMode(enable:Bool) {
        setDarkMode(enable);
        Application.current.window.borderless = true;
        Application.current.window.borderless = false;
    }

    @:functionCode('
        int result = MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);
    ')
    public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {}

    public static function messageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {
        showMessageBox(caption, message, icon);
    }
    #end
}

#if windows
@:enum abstract MessageBoxIcon(Int) {
    var MSG_ERROR:MessageBoxIcon = 0x00000010;
    var MSG_QUESTION:MessageBoxIcon = 0x00000020;
    var MSG_WARNING:MessageBoxIcon = 0x00000030;
    var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}
#end