package;

import flixel.group.FlxSpriteGroup;

class Reflection extends FlxSpriteGroup {
    public var parent:Character;
    public var reflection:Character;
    public var reflectionDistance:Float;

    override public function new(spr1:Character, offY:Float = 0) 
    {
        super(x, y);
        parent = spr1;
        
        add(spr1);

        reflection = spr1.cloneCharacter();
        reflection.alpha = 0.5;
        reflection.flipY = true;
        reflection.flipX = parent.flipX;

        reflection.x = parent.x;
        reflection.y = parent.y + parent.frameHeight * parent.scale.y * 2 - parent.offset.y * 2;
        reflection.y += offY;

        add(reflection);
    }

    override public function update(elapsed:Float) 
    {
        super.update(elapsed);

        reflection.animation.addByPrefix("a", parent.animation.frameName, 1, true);
        reflection.playAnim("a", true);

        reflection.offset.x = parent.offset.x;
        reflection.offset.y = parent.frameHeight * parent.scale.y - parent.offset.y;
        //reflection.animation.play(parent.animation.curAnim.name);
    }
}
