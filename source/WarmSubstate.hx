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
class WarmSubstate extends FlxGroup 
{
    public var onDestroy:Void -> Void;

    public function new()
    {
        super();

        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = .6;
        add(bg);

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 54, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        text.borderSize = 2;
        var string:String = 'The weather is cold today!\n\nKeep ${PlayState.leftSide ? "Burrito Kitty" : "BurritoFriend"}\'s body temperature stable by\nhitting notes to increase his /warmness/ level.';
        string += "\nMissing notes will make him lose much /warmth/.\nThe less /warmth/ the less his input will hit notes.";
        string += "\n\nIf he loses too much /warmth/,\nhe will get *FROZEN*. When *FROZEN*, he won't be able to hit notes.";
        text.applyMarkup(string, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.ORANGE), '/'),
        new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.CYAN), '*')]);
        text.screenCenter();
        text.y -= 120;
        add(text);

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, RIGHT);
        text.text = "Hit BACKSPACE to never show this screen again";
        text.y = FlxG.height - text.height - 32;
        text.x = FlxG.width - text.width - 10;
        add(text);

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, RIGHT);
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

        if (FlxG.keys.justPressed.BACKSPACE)
        {
            FlxG.save.data.explainedWarm = true;
            FlxG.save.flush();

            kill();
            destroy();
        }
        
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