package;

import flixel.tweens.FlxEase;
import OptionsState.ControlsSubstate;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
import lime.app.Application;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	public static var character:String = "BurritoFriend";
	private static var curSelected:Int = 0;
	private static var curDifficulty:Int = 0;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var clockText:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var bliss:FlxSprite;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.destroyLoadedImages(true);
		#end
		WeekData.reloadWeekFiles(false);
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		Conductor.changeBPM(180);

		for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];
			for (j in 0...leWeek.songs.length) {
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs) {
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3) {
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.setDirectoryFromWeek();

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		bliss = new FlxSprite().loadGraphic(Paths.image("bliss"));
		bliss.antialiasing = ClientPrefs.globalAntialiasing;
		bliss.alpha = 0;
		add(bliss);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		songs.insert(0, new SongMetadata("STORY SONGS", 0, "", 0));
		songs.insert(4, new SongMetadata("BONUS SONGS", 0, "", 0));
		songs.insert(16, new SongMetadata("ORIGINAL SONGS", 0, "", 0));

		for (i in 0...songs.length)
		{
			if (songs[i].songName == "Beginning of a New Insanity")
				songs[i].songName = "B. of a New Insanity";

			var song = ["title.wma", "Unholy Insanity Resonance", "Fireflies Tell Insanity", "Hold Your Insanity", "Insanity Found in Ruins", "We're Landing At Last", "Warmth Without Insanity", "Higher", "Insanity", "CATS!!", "nyan", "Adequate Insanity", "Please Don't", "Insanity Infusion", "Insanity On Earth", "In the End, It's All Fine", "bgmusic00", "Sanity", "Insanity Likes Your Face"];
			var song2 = ["Insanity", "We're Landing At Last", "Warmth Without Insanity", "CATS!!", "Adequate Insanity", "Please Don't", "Insanity Infusion", "Insanity On Earth", "In the End, It's All Fine", "Sanity", "Insanity Likes Your Face"];
			var songText:Alphabet = new Alphabet(0, (70 * i) + (songs[i].songName != 'title.wma' ? 30 : -70), songs[i].songName, !song.contains(songs[i].songName));
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			if (songs[i].songName == 'title.wma')
				songText.color = FlxColor.fromRGB(177, 255, 0);

			if ([0, 4, 16].contains(i))
			{
				songText.scrollFactor.x = 0;
				songText.screenCenter(X);
				songText.xAdd += FlxG.width / 4;
				//songText.color = "FlxColor.RED";
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			if ((song.contains(songs[i].songName) && !song2.contains(songs[i].songName)) || [0, 4, 16].contains(i))
				icon.visible = false;

			if (icon.visible)
				icon.animation.curAnim.curFrame = 2;
			if (songs[i].songName == "Boys With Insanity")
				icon.animation.curAnim.curFrame = 0;
			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.size = Std.int(diffText.size * 1.5);
		add(diffText);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		changeSelection();
		changeDiff();

		var textBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image("taskbar"));
		textBG.y = FlxG.height - 25;
		add(textBG);
		#if PRELOAD_ALL
		#else
		var leText:String = "Press RESET to Reset your Score and Accuracy.";
		#end
		textT = new FlxText(textBG.x, textBG.y + 5, FlxG.width, leText, 18);
		textT.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		textT.scrollFactor.set();
		add(textT);

		clockText = new FlxText();
		clockText.setFormat(Paths.font("vcr.ttf"), 18); 
		clockText.y = FlxG.height - clockText.height - 3;
		clockText.text = "";
		add(clockText);

		super.create();
	}
	var leText:String = "Psych 0.4.1 / PRESS SPACE OR RESET";
	var textT:FlxText;

	override function closeSubState() {
		changeSelection();
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	private static var vocals:FlxSound = null;
	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		if (songs[curSelected].songName == "nyan")
		{
			Main.fpsVar.text = "nyan: nyan";
			textT.text = "nyan / nyan";
		}
		else 
		{
			textT.text = leText;
			Main.fpsVar.text = "Burritos: " + Main.fpsVar.currentFPS;
		}

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		if (songs[curSelected].songName == "nyan")
			scoreText.text = "nyan: nyan";
		else
			scoreText.text = 'PERSONAL BURRITO: ' + lerpScore + ' (' + Math.floor(lerpRating * 100) + '%)';

		if (FlxG.save.data.finishedStory)
		{
			var text:String = scoreText.text;
			text += '\n\nCURRENT CHARACTER: ';
			
			if (character == 'BurritoFriend')
			{
				if (songs[curSelected].songName == "nyan")
					text += "/nyan/";
				else
					text += '/$character/';
			}
			else
			{
				if (songs[curSelected].songName == "nyan")
					text += "\\nyan\\";
				else
					text += '\\$character\\';
			}
			if (songs[curSelected].songName == "nyan")
				text += "\nnyan";
			else
				text += '\nPRESS SHIFT TO SWITCH CHARACTER';

			scoreText.applyMarkup(text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.CYAN), '/'),
			new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.BROWN), '\\')]);
		}
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var shift = FlxG.keys.justPressed.SHIFT;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (upP)
		{
			changeSelection(-shiftMult);
		}
		if (downP)
		{
			changeSelection(shiftMult);
		}
		if (shift && FlxG.save.data.finishedStory && songs[curSelected].songName != "Insanity Infusion" && songs[curSelected].songName != "Sanity" && songs[curSelected].songName != "Boys With Insanity")
			character = character == "BurritoFriend" ? "Burrito Kitty" : "BurritoFriend";

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		#if PRELOAD_ALL
		if(space && instPlaying != curSelected)
		{
			var name:String = new String(songs[curSelected].songName);
			if (name == "B. of a New Insanity")
				name = "Beginning of a New Insanity";

			destroyFreeplayVocals();
			Paths.currentModDirectory = songs[curSelected].folder;
			var poop:String = Highscore.formatSong(name.toLowerCase(), curDifficulty);
			PlayState.SONG = Song.loadFromJson(poop, name.toLowerCase());
			if (PlayState.SONG.needsVoices)
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			else
				vocals = new FlxSound();

			FlxG.sound.list.add(vocals);
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
			vocals.play();
			vocals.persist = true;
			vocals.looped = true;
			vocals.volume = 0.7;
			instPlaying = curSelected;
		}
		else #end if (accepted)
		{
			if (songs[curSelected].songName == "Insanity Infusion" && FlxG.save.data.openedSub == null)
			{
				Application.current.window.alert("Please set your keybinds.", "");
				var sub = new ControlsSubstate();
				sub.insert(0, bg.clone());
				openSubState(sub);

				FlxG.save.data.openedSub = true;
				FlxG.save.flush();
			}
			else
			{
				if (songs[curSelected].songName == "B. of a New Insanity")
					songs[curSelected].songName = "Beginning of a New Insanity";

				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				#if MODS_ALLOWED
				if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
				#else
				if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
				#end
					poop = songLowercase;
					curDifficulty = 0;
					trace('Couldnt find file');
				}
				trace(poop);

				PlayState.leftSide = character == 'Burrito Kitty';
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				PlayState.storyWeek = songs[curSelected].week;
				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				if(colorTween != null) {
					colorTween.cancel();
				}
				LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;
						
				destroyFreeplayVocals();
			}
		}
		else if(controls.RESET)
		{
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficultyStuff.length-1;
		if (curDifficulty >= CoolUtil.difficultyStuff.length)
			curDifficulty = 0;

		var name:String = new String(songs[curSelected].songName);
		if (name == "B. of a New Insanity")
			name = "Beginning of a New Insanity";

		#if !switch
		intendedScore = Highscore.getScore(name, curDifficulty);
		intendedRating = Highscore.getRating(name, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + (name == "nyan" ? "nyan" : CoolUtil.difficultyString()) + ' >';
		positionHighscore();
	}

	override function beatHit()
	{
		super.beatHit();

		var date = Date.now();
		var hour = "" + date.getHours();
		var minute = "" + date.getMinutes();
		if (hour.length < 2)
			hour = "0" + hour;
		if (minute.length < 2)
			minute = "0" + minute;

		clockText.text = hour + ":" + minute;
		clockText.x = FlxG.width - 42;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		if ([0, 4, 16].contains(curSelected))
		{
			changeSelection(change == 0 ? 1 : change);
			return;
		}

		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		if (songs[curSelected].songName == "title.wma")
		{
			Application.current.window.resizable = false;
			Application.current.window.maximized = false;
			Application.current.window.width = 1280;
			Application.current.window.height = 720;
			Application.current.window.title = "";
			Application.current.window.borderless = true;
		}
		else if (!Application.current.window.resizable)
		{
			Application.current.window.resizable = true;
			Application.current.window.borderless = false;
		}

		FlxTween.cancelTweensOf(bliss);
		if (songs[curSelected].songName == "title.wma")
			FlxTween.tween(bliss, {alpha: 1}, 1.2);
		else
			FlxTween.tween(bliss, {alpha: 0}, 1.2);

		if (songs[curSelected].songName == "nyan")
		{
			Application.current.window.title = "nyan";
		}
		else 
			Application.current.window.title = "Burrito Kitty PERFECTED CUT";

		if (songs[curSelected].songName == "Insanity Infusion" || songs[curSelected].songName == "Sanity")
			character = "BurritoFriend";

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0 || [0, 4, 16].contains(grpSongs.members.indexOf(item)))
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		changeDiff();
		Paths.currentModDirectory = songs[curSelected].folder;
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.setGraphicSize(0, scoreText.height + diffText.height * 2 + 40);
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
