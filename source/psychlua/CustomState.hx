package psychlua;

class CustomState extends MusicBeatState {
    var fileName:String;
    
    public function new(fileName:String) {
        super();
        this.fileName = fileName;

        setScriptState(fileName, this);

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Custom States: " + fileName, null);
        #end
    }
}