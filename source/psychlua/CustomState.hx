package psychlua;

class CustomState extends MusicBeatState {
    var fileName:String;
    var instance:CustomState = null;
    
    public function new(fileName:String) {
        super();
        this.fileName = fileName;

        instance = this;

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Custom States: " + fileName, null);
        #end
    }

    override function create():Void {
        super.create();
    }
}