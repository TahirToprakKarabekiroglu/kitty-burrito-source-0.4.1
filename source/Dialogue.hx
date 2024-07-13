package;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class Dialogue extends FlxSpriteGroup
{
    var dialogue:Array<String>;
    var dialogueText:FlxText;
    var currentDialogue:Int = 0;

    public var onClose:Void -> Void;
    
    public function new(dialogue:Array<String>) 
    {
        super();

        this.dialogue = dialogue;

        var bg:FlxSprite = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        add(bg);

        dialogueText = new FlxText();
        dialogueText.setFormat(Paths.font("one.ttf"), 32, CENTER);
        dialogueText.screenCenter();
        add(dialogueText);

        changeDialogue();
        FlxTween.tween(bg, {alpha: 0.6});

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    var dialogueTimer:FlxTimer;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER)
        {
            if (currentDialogue < dialogue.length)
            {
                if (dialogueTimer == null)
                    dialogueTimer = new FlxTimer().start(0.25, function(tmr)
                    {
                        changeDialogue();
                        dialogueTimer = null;
                    });
            }
            else 
            {
                close();
            }
        }
    }

    function changeDialogue()
    {
        dialogueText.alpha = 0;

        dialogueText.text = dialogue[currentDialogue];
        dialogueText.screenCenter();

        FlxTween.tween(dialogueText, {alpha: 1});
        currentDialogue++;

        FlxG.sound.play(Paths.sound("scrollMenu"));
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