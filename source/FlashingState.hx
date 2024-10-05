package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	override function create()
	{
		super.create();

		var dialogue:FirstDialogue = new FirstDialogue(["This is a joke mod.",
		"This mod contains remixes of my favourite songs.",
		"Their original can be found at credits menu.",
		"You can also access the originals at the box that appears at start.",
		"Enjoy Burrito Kitty PERFECTED CUT. =)"]);
		dialogue.onClose = () -> {
			leftState = true;
			FlxG.save.data.sawCat = true;
			FlxG.save.flush();
			MusicBeatState.switchState(new TitleState());
		}
		add(dialogue);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
