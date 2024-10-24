package;

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

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var kitty:FlxSprite;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;

	var stageSuffix:String = "";

	var lePlayState:PlayState;

	var heyPos:Bool;
	public static var characterName:String = 'bf';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'over';
	public static var endSoundName:String = 'confirmMenu';

	public static function resetVariables() {
		characterName = 'bf';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'over';
		endSoundName = 'confirmMenu';
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float, state:PlayState)
	{
		lePlayState = state;
		super();

		FlxTween.tween(FlxG.camera, {zoom: 0.7}, 1.6, {ease: FlxEase.expoIn});

		Conductor.songPosition = 0;

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
		Conductor.changeBPM(180);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');

		var exclude:Array<Int> = [];

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
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

		if (controls.ACCEPT)
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
			FlxG.camera.follow(camFollowPos, LOCKON, 1);
			updateCamera = true;
		}

		if (controls.BACK)
		{
			isEnding = true;
			canAccept = true;

			FlxTween.cancelTweensOf(kitty);
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new MainMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());
			if (bf.animation.curAnim != null && !bf.animation.curAnim.finished)
				FlxG.sound.playMusic(Paths.music("loop"));
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
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
			//FlxG.sound.music.stop();
			FlxG.sound.music.fadeOut(2.7);
			FlxG.sound.play(Paths.sound(endSoundName));
			canAccept = true;
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

				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
		}
	}
}
