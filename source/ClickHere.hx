package;

import flixel.text.FlxText;
import flixel.FlxSprite;

class ClickHere extends flixel.group.FlxSpriteGroup 
{
    public var text:FlxText;
    public function new() 
    {
        super();    

        var text = new FlxText();
        text.setFormat(Paths.font("vcr.ttf"), 48, CENTER);
        text.text = "Click here\nfor original";
        text.x += 12.5;
        text.y += 12.5;

        var bg = new FlxSprite();
        bg.makeGraphic(Std.int(text.width + 25), Std.int(text.height + 25), 0xFF000000);
        bg.alpha = 0.6;

        add(bg);
        add(text);
    } 
}