package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.util.FlxColor;

/**
    NOT AN ACTUAL SUBSTATE BUT WHATEVER!!!
**/
class CoolKittenSubstate extends FlxGroup 
{
    public var onDestroy:Void -> Void;
    var kittyNotes:FlxTypedGroup<Note> = new FlxTypedGroup();

    public function new()
    {
        super();

        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = .6;
        add(bg);

        add(kittyNotes);

        for (i in 0...4) 
        {
            var note:Note = new Note(0, i);
            note.noteType = 'Kitty Note';
            note.y = -FlxG.height;
            note.screenCenter(X);
            note.x -= Note.swagWidth;
            note.x += Note.swagWidth * i - 60;
            kittyNotes.add(note);

            var text:FlxText = new FlxText();
            text.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
            text.borderSize = 2;
            text.text = '^';
            text.x = note.x + note.width / 2 - 10;
            text.y = note.y + note.height;
            add(text);

            var supposedY:Float = (FlxG.height - note.height) / 2;
            FlxTween.tween(note, {y: supposedY}, 2.4, {onUpdate: (twn) -> {
                text.y = note.y + note.height + 5;
            }, ease: FlxEase.expoInOut});
        }

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        text.borderSize = 2;
        text.text = "KITTY NOTES: \nWhen hit, the strum you hit the note will disappear.\nYou cannot hit notes that have the same direction\nas the strum until the strum is fully visible!\n\n(Strums will reappear over time)";
        text.text += "\nThey are quite hard to hit, but deadly.";
        text.screenCenter();
        text.y -= 210;
        add(text);

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT);
        text.text = "Hit ENTER twice to exit";
        text.y = FlxG.height - text.height - 6;
        text.x = FlxG.width - text.width - 10;
        add(text);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    var hitEnter:Int;
    override function update(elapsed:Float) 
    {
        super.update(elapsed);   
        
        if (FlxG.keys.justPressed.ENTER)
            hitEnter++;

        if (hitEnter > 1)
        {
            kill();
            destroy();
        }
    }

    override function destroy()
    {
        super.destroy();

        if (onDestroy != null)
            onDestroy();
    }
}