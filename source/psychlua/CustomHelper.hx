package psychlua;

class CustomHelper {
    public static function openScriptSubState(scriptName:String) {
        return MusicBeatState.getState().openSubState(new CustomSubstate(scriptName));
    }

    public static function closeScriptSubState() {
        return MusicBeatState.getState().closeSubState();
    }
}