package;

import flixel.FlxCamera;
import flixel.sound.FlxSound;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class FakeGameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var kitty:FlxSprite;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var timer:(tmr:FlxTimer) -> Void;

	var heyPos:Bool;
    var characterName:String = 'bf';
	var deathSoundName:String = 'fnf_loss_sfx';
	var loopSoundName:String = 'loop';
	var endSoundName:String = 'confirmMenu';
    var fakeCamera:FlxCamera = null;

	public function new(x:Float, y:Float, camX:Float, camY:Float, timer:(tmr:FlxTimer) -> Void)
	{
		super();

		this.timer = timer;

		fakeCamera = new FlxCamera();
		FlxG.cameras.add(fakeCamera);

		cameras = [fakeCamera];

		FlxTween.tween(camera, {zoom: 0.7}, 1.6, {ease: FlxEase.expoIn});

		kitty = new FlxSprite().loadGraphic(Paths.image('kitty-face'));
		kitty.scale.set(4, 4);
		kitty.alpha = PlayState.leftSide ? 1 : 0;
		add(kitty);

		bf = new Boyfriend(x, y, characterName);
		add(bf);

		kitty.setPosition(bf.x - bf.width, bf.y);

		camFollow = new FlxPoint(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y);
		camFollow.x -= 250;

		FlxG.sound.play(Paths.sound(deathSoundName));

		bf.playAnim('firstDeath');

		var exclude:Array<Int> = [];

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camera.scroll.x + (camera.width / 2), camera.scroll.y + (camera.height / 2));
		add(camFollowPos);
	}

	var canAccept:Bool;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 1.2, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT && canAccept)
		{
			endBullshit();
		}

		if (heyPos)
			bf.playAnim('hey');

		if (kitty.alpha == (PlayState.leftSide ? 1 : 0))
		{
			FlxTween.tween(kitty, {alpha: !PlayState.leftSide ? 1 : 0}, 3, {onUpdate: (twn) -> {
				if (!canAccept && !isEnding)
				{
					bf.playAnim('firstDeath');
				}
			}, onComplete: (twn) -> {
				if (!isEnding && !canAccept)
				{
					coolStartDeath();
					if (PlayState.leftSide)
					{
						heyPos = true;
						//bf.playAnim('hey');
					}
					else
						bf.playAnim('deathLoop');
					canAccept = true;
				}
			}});
		}

		if (bf.animation.curAnim.name == 'firstDeath')
		{
			camera.follow(camFollowPos, LOCKON, 1);
			updateCamera = true;
		}

		if (controls.BACK && canAccept)
		{
            endBullshit();
		}
	}

	override function close()
	{
		FlxG.cameras.remove(fakeCamera);
		new FlxTimer().start(16, timer);
		super.close();
		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	var music:FlxSound;
	function coolStartDeath(?volume:Float = 1):Void
	{
		music = FlxG.sound.play(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			heyPos = false;
			isEnding = true;
			if (PlayState.leftSide)
				bf.playAnim('deathLoop', true);
			else
				bf.playAnim('deathConfirm', true);
			canAccept = true;
			FlxG.sound.play(Paths.sound(endSoundName));
			music.fadeOut(2.7, (twn) -> close());
			camera.fade(FlxColor.BLACK, 2.7, false);
			if (PlayState.leftSide)
			{
				FlxTween.cancelTweensOf(kitty);
				FlxTween.tween(kitty, {alpha: PlayState.leftSide ? 1 : 0}, 2);
			}
			new FlxTimer().start(PlayState.leftSide ? 2.7 : 0.7, function(tmr:FlxTimer)
			{
				if (!PlayState.leftSide)
				{
					FlxTween.cancelTweensOf(kitty);
					FlxTween.tween(kitty, {alpha: PlayState.leftSide ? 1 : 0}, 2);
				}
			});
		}
	}
}
