package;

import flixel.tweens.FlxEase;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class FirstDialogue extends FlxSpriteGroup
{
    var dialogue:Array<String>;
    var dialogueText:FlxText;
    var currentDialogue:Int = 0;
    var curText:String;

    public var onClose:Void -> Void;
    
    public function new(dialogue:Array<String>) 
    {
        super();

        this.dialogue = dialogue;

        var bg1:FlxSprite = new FlxSprite();
        bg1.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg1.alpha = 0;
        add(bg1);

        dialogueText = new FlxText();
        dialogueText.setFormat(Paths.font("one.ttf"), 32, CENTER);
        dialogueText.screenCenter();
        add(dialogueText);

        changeDialogue();
        FlxTween.tween(bg1, {alpha: 1}, 0.8);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    var canPress:Bool = true;
    var sayHi:Bool = false;
    var rapTimer:FlxTimer;
    var rap:Int = 0;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER && canPress && !sayHi)
        {
            if (currentDialogue < dialogue.length)
            {
                changeDialogue();
            }
            else 
            {
                close();
            }
        }
    }

    function changeDialogue()
    {
        canPress = false;
        FlxTween.tween(dialogueText, {alpha: 0}, 0.6, {onComplete: (twn) -> {
            dialogueText.text = "[" + dialogue[currentDialogue] + "]";
            curText = dialogue[currentDialogue];
            dialogueText.screenCenter();
    
            FlxTween.tween(dialogueText, {alpha: 1}, 0.6, {onComplete: (twn) -> {
                canPress = true;
            }});
            currentDialogue++;
    
            FlxG.sound.play(Paths.sound("scrollMenu"));
        }});
    }

    override function destroy()
    {
        super.destroy();
    }

    function close() 
    {   
        FlxTween.tween(this, {alpha: 0}, 0.4, {onComplete: (twn) ->
        {
            if (onClose != null)
                onClose();

            destroy();
        }});
    }
}