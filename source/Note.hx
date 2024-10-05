package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var willMiss:Bool;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	
	public var yMult:Float = 0.45;

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	public var earlyHitMult:Float = 0.5;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public static var earlyHitMultMinus(default, set):Float = 0;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = false;
	public var copyAlpha:Bool = true;

	public var noteLength:Int = 0;

	public var angleMult:Float = FlxG.random.bool() ? -1 : 1;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
		colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
		colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
				case 'Kitty Note':
					if (!isSustainNote)
					{
						ignoreNote = true;
						copyAlpha = false;
						earlyHitMult = 0.25;
						reloadNote('kity', 'Notes');
						noteSplashTexture = null;
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
						earlyHitMult = 0.2;
					}
				case 'Middle Note':
					ignoreNote = mustPress;
					copyAlpha = false;
					reloadNote('burrito', 'Note');
					noteSplashTexture = null;
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
				case 'Higher Note': 
					ignoreNote = false;
					var alt = "";
					if (ClientPrefs.downScroll)
						alt = "_downscroll";
					reloadNote("HIGH_", "assets", alt);
					noteSplashTexture = null;
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					copyAlpha = false;
					//earlyHitMult = 0.5;
			}
			noteType = value;
		}
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		if (PlayState.SONG != null && Paths.formatToSongPath(PlayState.SONG.song) == "cats!!")
			offsetX = 5;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % 4);
			if(!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				switch (noteData % 4)
				{
					case 0:
						animToPlay = 'red';
					case 1:
						animToPlay = 'green';
					case 2:
						animToPlay = 'blue';
					case 3:
						animToPlay = 'yellow';
				}
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			/*alpha = 0.6;
			multAlpha = 0.6;*/
			if(ClientPrefs.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			switch (noteData)
			{
				case 0:
					animation.play('redholdend');
				case 1:
					animation.play('greenholdend');
				case 2:
					animation.play('blueholdend');
				case 3:
					animation.play('yellowholdend');
			}

			updateHitbox();
			offsetX -= width / 2;

			if (PlayState.SONG != null && Paths.formatToSongPath(PlayState.SONG.song) == "cats!!")
			{
				scale.x *= 4;
				offsetX += width / 2 + 40;
			}

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('redhold');
					case 1:
						prevNote.animation.play('greenhold');
					case 2:
						prevNote.animation.play('bluehold');
					case 3:
						prevNote.animation.play('yellowhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05 * PlayState.SONG.speed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
				if (PlayState.SONG != null && Paths.formatToSongPath(PlayState.SONG.song) == "cats!!")
					prevNote.offsetX -= prevNote.width / 4 + 25;
			}

			if(PlayState.isPixelStage) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		} else if(!isSustainNote) {
			earlyHitMult = 1;
			if (PlayState.leftSide)
				earlyHitMult -= FlxG.random.float(0.4, 0.5);
		}
	}

	var lastScaleY:Float;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';
		
		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}
		if (PlayState.SONG != null && Paths.formatToSongPath(PlayState.SONG.song) == "cats!!")
			skin = "CATS!!";

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		lastScaleY = scale.y;
		var blahblah:String = arraySkin.join('/');
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('weeb/pixelUI/' + blahblah + 'ENDS'));
				width = width / 4;
				height = height / 2;
				loadGraphic(Paths.image('weeb/pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('weeb/pixelUI/' + blahblah));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('weeb/pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = ClientPrefs.globalAntialiasing;
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);
	}

	function loadNoteAnims() {
		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('yellowScroll', 'yellow0');

		if (isSustainNote)
		{
			animation.addByPrefix('yellowholdend', 'yellow hold end0');
			animation.addByPrefix('greenholdend', 'green hold end0');
			animation.addByPrefix('redholdend', 'red hold end0');
			animation.addByPrefix('blueholdend', 'blue hold end0');

			animation.addByPrefix('yellowhold', 'yellow hold piece0');
			animation.addByPrefix('greenhold', 'green hold piece0');
			animation.addByPrefix('redhold', 'red hold piece0');
			animation.addByPrefix('bluehold', 'blue hold piece0');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		if (PlayState.curStage == 'resonance')
		{
			scale.scale(0.5, 0.5);
		//	updateHitbox();
		}
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add('yellowholdend', [PURP_NOTE + 4]);
			animation.add('greenholdend', [GREEN_NOTE + 4]);
			animation.add('redholdend', [RED_NOTE + 4]);
			animation.add('blueholdend', [BLUE_NOTE + 4]);

			animation.add('yellowhold', [PURP_NOTE]);
			animation.add('greenhold', [GREEN_NOTE]);
			animation.add('redhold', [RED_NOTE]);
			animation.add('bluehold', [BLUE_NOTE]);
		} else {
			animation.add('greenScroll', [GREEN_NOTE + 4]);
			animation.add('redScroll', [RED_NOTE + 4]);
			animation.add('blueScroll', [BLUE_NOTE + 4]);
			animation.add('yellowScroll', [PURP_NOTE + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PlayState.SONG != null && Paths.formatToSongPath(PlayState.SONG.song) == "warmth-without-insanity" && !isSustainNote)
		{
			earlyHitMult = switch PlayState.instance.warmnessLevel {
				case "Warm": 1;
				case "Moderate": 0.7;
				case "Cold": 0.4;
				case _: 0;
			}
		}

		if (alpha < 1)
			canBeHit = false;
		else
		{
			if (mustPress && noteType != "Bah!")
			{
				var earlyHitMultMinus = Note.earlyHitMultMinus;
				if (isSustainNote)
					earlyHitMultMinus = 0;
				else if (noteType == 'Middle Note')
					earlyHitMultMinus = 0;

				// ok river
				if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * (earlyHitMult - earlyHitMultMinus)))
					canBeHit = true;
				else
					canBeHit = false;

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			}
			else
			{
				canBeHit = false;
			}
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	static function set_earlyHitMultMinus(value:Float):Float 
	{
		if (value < 0)
			value = 0;
		else if (value > 1)
			value = 1;

		return earlyHitMultMinus = value;
	}
}
