package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.util.FlxColor;

class AscendingInsanitySubstate extends FlxGroup 
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
        text.screenCenter();
        text.y -= FlxG.height;
        add(text);

        text.applyMarkup("This song is $HARD$!", [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED, FlxColor.BLACK), '$')]);
        text.screenCenter(X);
        FlxTween.tween(text, {y: text.y + FlxG.height - 20}, 2.6, {ease: FlxEase.expoInOut});
    
        var text2:FlxText = new FlxText();
        text2.setFormat(Paths.font("vcr.ttf"), 54, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        text2.screenCenter();
        text2.borderSize = 2;
        text2.y -= FlxG.height;
        add(text2);

        text2.applyMarkup("Make sure your hands are well rested\nbecause this song $CANNOT$ be paused!", [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED, FlxColor.BLACK), '$')]);
        text2.screenCenter(X);
        FlxTween.tween(text2, {y: text2.y + FlxG.height + text.height + 20}, 3.2, {ease: FlxEase.expoInOut});
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, RIGHT);
        text.text = "Hit ENTER to exit";
        text.y = FlxG.height - text.height - 6;
        text.x = FlxG.width - text.width - 10;
        add(text);

        var text:FlxText = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, RIGHT);
        text.text = "Hit BACKSPACE to never show this screen again";
        text.y = FlxG.height - text.height - 32;
        text.x = FlxG.width - text.width - 10;
        add(text);
    }

    var hitEnter:Int;
    override function update(elapsed:Float) 
    {
        super.update(elapsed);   
        
        if (FlxG.keys.justPressed.ENTER)
        {
            kill();
            destroy();
        }
        else if (FlxG.keys.justPressed.BACKSPACE)
        {
            FlxG.save.data.ascendingPerm = true;
            FlxG.save.flush();

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