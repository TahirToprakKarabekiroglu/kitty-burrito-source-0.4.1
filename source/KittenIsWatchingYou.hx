package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxRainbowEffect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class KittenIsWatchingYou extends MusicBeatState
{
    var introSound:FlxSound;
    override function create()
    {
        super.create();

        FlxG.fixedTimestep = false;

        var sound = FlxAssets.getSound("flixel/sounds/flixel");

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image("menuBlack"));
        bg.screenCenter();
        add(bg);

        var skipText:FlxText = new FlxText();
        skipText.setFormat(Paths.font('muff.ttf'), 32, LEFT, OUTLINE, FlxColor.BLACK);
        skipText.borderSize = 2;
        skipText.borderQuality = 2;
        skipText.y = FlxG.height - 40;
        skipText.text = "Press ENTER to skip";
        //skipText.setPosition();
        add(skipText);

        var text:FlxText = new FlxText(0, 0, 900);
        text.setFormat(Paths.font('muff.ttf'), 96, CENTER, OUTLINE, FlxColor.BLACK);
        text.text = "";
        text.borderSize = 5;
        text.borderQuality = 5;
        text.screenCenter();
        text.y += 90;
        add(text);

        var flixelText:FlxText = new FlxText(0, 0, 900);
        flixelText.setFormat(Paths.font('muff.ttf'), 96, CENTER, OUTLINE, FlxColor.BLACK);
        flixelText.text = "";
        flixelText.screenCenter();

        var rainbowText:FlxEffectSprite = new FlxEffectSprite(flixelText);
        //rainbowText.effects = [new FlxRainbowEffect(1, 1, 3.7)];
        rainbowText.screenCenter();
        add(rainbowText);

        new FlxTimer().start(0.3, (tmr) -> {
            introSound = FlxG.sound.load(sound, 1, false, null, false, true, null, () -> {
                new FlxTimer().start(1.2, (tmr) -> {
                    remove(rainbowText);
                    remove(text);

                    FlxG.sound.play(Paths.sound("confirmMenu"));
                    var kitten:FlxSprite = new FlxSprite().loadGraphic(Paths.image("kitty-face"));
                    kitten.scale.set(2, 2);
                    kitten.updateHitbox();
                    kitten.screenCenter();
                    add(kitten);

                    new FlxTimer().start(1.2, (tmr) -> {
                        FlxTween.tween(skipText, {alpha: 0}, 1.3, {onComplete: (twn) -> {
                            bg.alpha = skipText.alpha = 0;
                            new FlxTimer().start(.1, (tmr) -> {
                                MusicBeatState.switchState(cast Type.createInstance(TitleState, []));
                            });
                        }, onUpdate: (twn) -> { 
                            bg.alpha = skipText.alpha;
                        }});
                    });
                });
            }, () -> {
                var _times:Array<Float> = [.04, .194, .344, .505, .646];
                var _texts:Array<String> = ["Burrito ", "Kitty ", "is ", "watching ", "you."];
                for (i in _times)
                {
                    new FlxTimer().start(i, (tmr) -> {
                        var _text:String = _texts[_times.indexOf(i)];
                        if (["Burrito ", "Kitty "].contains(_text))
                        {
                            flixelText.text += _text;
                            flixelText.screenCenter();
                            flixelText.y -= 45;
                            rainbowText.y -= 45;
                            rainbowText.screenCenter(X);
                        }
                        else
                        {
                            text.text += _text;
                            text.screenCenter();
                            text.y += 90;
                        }
                    });
                }
            });
        });
        //new FlxTimer().start(0.01, (tmr) -> introSound.play());
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER && introSound != null)
        {
            introSound.onComplete = null;
            introSound.stop();
            /*introSound.destroy();
            introSound = null;*/
            
            MusicBeatState.switchState(cast Type.createInstance(TitleState, []));
        }
    }
}