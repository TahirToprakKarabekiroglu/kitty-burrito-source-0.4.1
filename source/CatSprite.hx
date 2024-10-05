package;

import flixel.FlxSprite;

class CatSprite extends FlxSprite 
{
    static var randoms:Array<Int> = [];

    public function new()
    {
        super();

        if (randoms.length >= 16)
            randoms = [];

        var random = FlxG.random.int(0, 15, randoms);
        loadGraphic(Paths.image("cats/" + random));
        setGraphicSize(FlxG.width, FlxG.height);
        updateHitbox();
        screenCenter();
        randoms.push(random);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        alpha -= elapsed / FlxG.random.float(1.1, 1.3);
    }
}