package;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.util.FlxColor;

class StoryCompleted extends MusicBeatSubstate 
{
    var unlockText:FlxText;

    public function new() 
    {
        super();    

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        bg.screenCenter();
        add(bg);

        var newt:FlxText = new FlxText();
        newt.setFormat(Paths.font('vcr.ttf'), 96, CENTER);
        newt.text = "You completed story mode!\nWhat's NEW?";
        newt.screenCenter();
        newt.y -= FlxG.height / 4;
        add(newt);

        unlockText = new FlxText();
        unlockText.setFormat(Paths.font('vcr.ttf'), 54, LEFT);
        var text = "- You unlocked (extra( songs in freeplay!\n- You unlocked *Burrito Kitty* as a playable character!\n- You can now press )8) to play old versions of songs!";
        unlockText.applyMarkup(text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.fromRGB(125, 73, 43)), '*'),
        new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.fromRGB(60, 255, 34)), '('), new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), ')')]);
        unlockText.screenCenter();
        add(unlockText);

        var newText = new FlxText();
        newText.setFormat(Paths.font('vcr.ttf'), 48, CENTER);
        var text = "Finish )Insanity), )Warmth Without Insanity) and\n)Insanity on Earth) as ?BurritoFriend? to unlock )Original) songs.";
        newText.applyMarkup(text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), ')'),
            new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.CYAN), '?')]);
        newText.screenCenter();
        newText.y += FlxG.height / 4;
        add(newText);

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.screenCenter();
        add(bg);
        
        FlxTween.tween(bg, {alpha: 0});

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    override function update(elapsed:Float) 
    {
        super.update(elapsed);
        
        if (controls.BACK || controls.ACCEPT)
        {
            close();

            FlxG.sound.playMusic(Paths.music('loop'));
            MusicBeatState.switchState(new MainMenuState());
        }
    }
}