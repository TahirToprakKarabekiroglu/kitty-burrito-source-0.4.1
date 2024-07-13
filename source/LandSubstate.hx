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
class LandSubstate extends FlxGroup 
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
        var string:String = '${PlayState.leftSide ? "Burrito Kitty" : "BurritoFriend"} has entered the turbulence!\n\nMake him land safely with hitting notes.';
        string += "\nHis landing chance increases when you hit notes\nand decrease when you miss them.\nLong notes will give him less increase of landing chance.";
        string += "\n\nAt the end of this song, if his landing chance is low he will not land safely\nand will cause a game over!";
        text.applyMarkup(string, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.ORANGE), '$'),
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
            FlxG.save.data.explainedLand = true;
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