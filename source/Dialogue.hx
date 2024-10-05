package;

import flixel.tweens.FlxEase;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class Dialogue extends FlxSpriteGroup
{
    var bf:Boyfriend;
    var dad:Character;

    var bg:FlxSprite;
    var camera1:FlxCamera;
    var camera2:FlxCamera;
    var dialogue:Array<String>;
    var dialogueText:FlxText;
    var currentDialogue:Int = 0;
    var curText:String;

    public var onClose:Void -> Void;
    
    public function new(dialogue:Array<String>, ?cam:FlxCamera) 
    {
        super();

        this.dialogue = dialogue;

        camera1 = new FlxCamera();
        camera1.bgColor.alpha = 0;

        camera2 = new FlxCamera();
        camera2.bgColor.alpha = 0;

        FlxG.cameras.add(camera1);
        FlxG.cameras.add(camera2);

        var bg1:FlxSprite = new FlxSprite();
        bg1.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg1.cameras = [camera1];
        bg1.alpha = 0;
        add(bg1);

        bg = new FlxSprite();
        bg.loadGraphic(Paths.image("bg"));
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.cameras = [camera1];
        bg.alpha = 0;
        add(bg);

        bf = new Boyfriend(0, 0, "dialogue");
        bf.screenCenter();
        bf.x -= 150;
        bf.cameras = [camera2];
        bf.alpha = 0;
        add(bf);

        dad = new Character(0, 0, "burito");
        dad.screenCenter();
        dad.scale.scale(0.5);
        dad.x -= 100;
        dad.y += 10;
        dad.cameras = [camera2];
        dad.alpha = 0;
        add(dad);

        dialogueText = new FlxText();
        dialogueText.setFormat(Paths.font("one.ttf"), 32, CENTER);
        dialogueText.screenCenter();
        dialogueText.cameras = [camera1];
        add(dialogueText);

        changeDialogue();
        FlxTween.tween(bg1, {alpha: 1}, 0.8);

        if (cam != null)
            cameras = [cam];
        else 
            cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    var canPress:Bool = true;
    var sayHi:Bool = false;
    var rapTimer:FlxTimer;
    var rap:Int = 0;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (sayHi && FlxG.keys.justPressed.H)
        {
            sayHi = false;
            bf.playAnim("hey");
            bf.animation.finishCallback = (name:String) -> {
                bf.playAnim("idle");
                bf.animation.finishCallback = null;
            }
            changeDialogue();
        }

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
    
            if (curText != null)
                switch curText
                {
                    case "This is BurritoFriend.":
                        FlxTween.tween(bf, {alpha: 1});
                    case "Press H to say hi!":
                        sayHi = true;
                    case "And today he is in a forest.":
                        FlxTween.tween(bg, {alpha: 0.6}, 0.6);
                    case "He finds Burrito Kitty.":
                        FlxTween.tween(bf, {x: bf.x + 100}, 1, {ease: FlxEase.expoInOut});
                        FlxTween.tween(dad, {x: dad.x - 100}, 1, {ease: FlxEase.expoInOut});
                        FlxTween.tween(dad, {alpha: 1});
                    case 'He brings out his burrito\nand he challenges him to a rap battle.':
                        bf.playAnim("bring");
                        bf.animation.finishCallback = (name:String) -> {
                            bf.playAnim("idle2");
                        }
                    case "And he starts rapping...":
                        bf.animation.finishCallback = null;
                        rapTimer = new FlxTimer().start(0.05, (tmr) -> {
                            var anim = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
                            bf.playAnim(anim[rap % 4], true);
                            rap++;
                        }, 0);
                }
        }});
    }

    override function destroy()
    {
        FlxG.cameras.remove(camera1);
        FlxG.cameras.remove(camera2);
        if (rapTimer != null)
        {
            rapTimer.cancel();
            rapTimer = null;
        }

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