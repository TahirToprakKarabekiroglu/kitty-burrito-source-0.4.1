package;

import flixel.group.FlxSpriteGroup;
import openfl.filters.ColorMatrixFilter;
import flixel.group.FlxGroup;
import openfl.display.Shader;
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.flixel.FlxVideo;
import PCShader.PCEffect;
import openfl.filters.ShaderFilter;
import flixel.input.keyboard.FlxKey;
import openfl.filters.BitmapFilterQuality;
import haxe.macro.Expr.Case;
import lime.app.Application;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import StageData;

#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;

	public static var instance:PlayState;

	public var keys:Array<Int> = {
		var key = [];
		for (i in FlxKey.fromStringMap)
		{
			key.push(cast (i, Int));

			key.remove(-2); // ANY 
			key.remove(-1); // NONE

			if (Paths.formatToSongPath(SONG.song) == "please-don't")
				key.remove(56); // EIGHT

			key.remove(107); // NUMPAD -
			key.remove(109); // NUMPAD +
		}
		key;
	}

	static var infuseBeats:Array<Null<Int>> = [
		188,
		256,
		576,
		640,
		704,
		832,
		960,
		1088,
		1216,
		1344,
	];

	var infuse:Int = 0;
	var infuse2:Int = 0;
	var infuseText:FlxText;

	var resynced:Bool;
	var resynced2:Bool;

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;

	public var boyfriendGroup:FlxTypedGroup<Boyfriend>;
	public var dadGroup:FlxTypedGroup<Character>;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 0;

	public var vocals:FlxSound;

	public var dad:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	var holdNotes:FlxTypedGroup<FlxSprite>;
	var holdNotesOpponent:FlxTypedGroup<FlxSprite>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var health:Float = 0.25;
	public var combo:Int = 0;

	var monitor:FlxSprite;

	var songPercent:Float = 0;

	var dontText:FlxText;

	var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;
	public static var leftSide:Bool = true;
	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camXP:FlxCamera;

	var alphaSine:Float = 0;

	var bg:BGSprite;
	var nightBG:BGSprite;
	var nyanBG:FlxVideoSprite;

	var earth:FlxSprite;
	private var angle1:Float = 0;
    private var angle2:Float = Math.PI; // 180 degrees offset for the second satellite

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	var burritoStrum:StrumNote;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var effectTxt:FlxText;
	var frozenTxt:FlxText;
	var timeTxt:FlxText;
	var lifeTxt:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end
	var healthHurtValue:Float = 0.01;

	var windowsXP:Bool;
	var xpShader:PCEffect;

	var click:ClickHere;

	var taskbar:FlxSprite = new FlxSprite();
	var startButtonPressed:FlxGroup;
	var startMenu:FlxSprite;
	var bin:FlxSprite;
	var lc:Float;
	var lcM:Float = 5;

	var resonanceBG:FlxSprite;

	override public function create()
	{
		#if MODS_ALLOWED
		Paths.destroyLoadedImages();
		#end
		
		Paths.sound("startup");
		instance = this;

		for (i in 0...ClientPrefs.lastControls.length)
		{
			if (i > 16 && i < 23)
				continue;
			
			var i:Null<Int> = cast ClientPrefs.lastControls[i];
			if (i != null)
			{
				for (e in keys)
					if (e == i)
					{
						keys.remove(e);
					}
			}
		}
		if (SONG.song.trim() == 'title.wma')
			windowsXP = true;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		practiceMode = false;
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camXP = new FlxCamera();
		camXP.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camXP);
		FlxG.cameras.add(camOther);

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		if (windowsXP)
		{
			xpShader = new PCEffect();
			camGame.filters = [new ShaderFilter(xpShader.shader)];
			camHUD.filters = [new ShaderFilter(xpShader.shader)];
			camXP.filters = [new ShaderFilter(xpShader.shader)];
		}

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		if (windowsXP)
		{
			startButtonPressed = new FlxGroup();

			taskbar.loadGraphic(Paths.image('taskbar'));
			taskbar.cameras = [camHUD];
			taskbar.screenCenter(X);
			taskbar.scale.x = 0.95;

			if (!ClientPrefs.downScroll)
				taskbar.y = FlxG.height - taskbar.height;

			var off = 17;
			if (ClientPrefs.downScroll)
				off = -off;

			taskbar.y -= off;

			var startButtonPressed = new FlxSprite();
			startButtonPressed.loadGraphic(Paths.image('start_pressed'));
			startButtonPressed.scale.x = 0.95;
			startButtonPressed.cameras = [camHUD];
			startButtonPressed.setPosition(taskbar.x, taskbar.y);
			startButtonPressed.visible = false;
			startButtonPressed.y -= off / 6 - (ClientPrefs.downScroll ? -3 : 3);
			this.startButtonPressed.add(startButtonPressed);
 
			startMenu = new FlxSprite();
			startMenu.loadGraphic(Paths.image('start'));
			startMenu.cameras = [camHUD];
			startMenu.visible = false;
			startMenu.x += 32;

			if (!ClientPrefs.downScroll)
				startMenu.y = taskbar.y - startMenu.height;
			else
				startMenu.y = taskbar.y + taskbar.height;

			bin = new FlxSprite().loadGraphic(Paths.image("trash"));
			bin.y = !ClientPrefs.downScroll ? FlxG.height - 160 : 80;
			bin.x = FlxG.width - 130;
			bin.cameras = [camHUD];

			var binText = new FlxText();
			binText.setFormat(Paths.font("tahoma.ttf"), 20, FlxColor.WHITE, CENTER, SHADOW, FlxColor.BLACK);
			binText.borderSize = 1.25;
			binText.cameras = [camHUD];
			binText.text = "Recycle Bin";
			binText.x = bin.x - 5;
			binText.y = bin.y + bin.height + 10;

			this.startButtonPressed.add(bin);
			this.startButtonPressed.add(binText);

			inCutscene = true;
			FlxG.mouse.visible = true;
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "";
		}
		else
		{
			detailsText = "";

			if (leftSide)
				detailsText += "Playing as Burrito Kitty";
			else
				detailsText += "Playing as BurritoFriend";
		}

		// String for when the game is paused
		detailsPausedText = "Paused, " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;
		trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = {
			directory: "",
			defaultZoom: 1,
			isPixelStage: false,
		
			boyfriend: [770, 300],
			opponent: [50, 300],
			girlfriend: null
		};
		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxTypedGroup<Boyfriend>();
		dadGroup = new FlxTypedGroup<Character>();

		switch (curStage)
		{
			case 'resonance':
				defaultCamZoom = 0.2;
				bg = new BGSprite("resonance_bg");
				bg.scale.scale(5, 5);
				bg.scrollFactor.set();
				add(bg);
			case 'end':
				defaultCamZoom = 0.4;

				bg = new BGSprite("8");
				bg.scale.scale(2.25);
				bg.updateHitbox();
				bg.screenCenter();
				bg.y -= 200;
				bg.scrollFactor.set();
				add(bg);

				Application.current.window.alert(
					'In the end, it\'s all fine.\nJust relax, there are no punishments for losing.\nPlay as you desire, or don\'t. See you, ${Sys.getEnv("USERNAME")}.',
					' '
				);
			case 'earth':
				earth = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image("earth"));
				earth.screenCenter();
				earth.scrollFactor.set();
				//earth.origin.set(earth.width / 2, earth.height / 2);
        		add(earth);

				defaultCamZoom = 0.25;
			default: //Week 1
				if (Paths.formatToSongPath(SONG.song) == 'insanity')
				{
					nightBG = new BGSprite("bg_night");
					nightBG.screenCenter();
					add(nightBG);
				}

				if (SONG.song == "nyan")
				{		
					defaultCamZoom = 0.4;

					nyanBG = new FlxVideoSprite();
					nyanBG.load("assets/videos/bg.mp4", [':input-repeat=65536']);
					nyanBG.scrollFactor.set();
					nyanBG.cameras = [camHUD];
					nyanBG.antialiasing = false;
					//bg.screenCenter();
					nyanBG.play();

					add(nyanBG);
				}
				else if (Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity"))
				{
					defaultCamZoom = 0.1;
					bg = new BGSprite('ocean');
					bg.scale.set(8, 7);
					bg.scrollFactor.set();
					bg.screenCenter();
					bg.y -= 150;
					add(bg);
				}
				else if (!windowsXP)
				{
					bg = new BGSprite('bg', -600, -200);
					bg.screenCenter();
					bg.x -= 50;
					bg.y += 250;
					add(bg);
				}
				else if (windowsXP)
				{
					defaultCamZoom = 0.4;
					bg = new BGSprite('bliss');
					bg.screenCenter();
					bg.y += 200;
					bg.x += 200;
					add(bg);
				}
		}

		if (Paths.formatToSongPath(SONG.song) == "we're-landing-at-last")
			lc = FlxG.random.int(50, 70);

		add(dadGroup);
		add(boyfriendGroup);

		dad = new Character(DAD_X, DAD_Y, SONG.player2, false);
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
		if (curStage == "earth")
		{
			dad.scrollFactor.set();
			//dad.origin.set(dad.width / 2, dad.height / 2);
		}
		dadGroup.add(dad);

		boyfriend = new Boyfriend(BF_X, BF_Y, SONG.player1);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		if (curStage == "earth")
		{
			boyfriend.scrollFactor.set();
			//boyfriend.origin.set(boyfriend.width / 2, boyfriend.height / 2);
		}
		boyfriendGroup.add(boyfriend);
		if (SONG.song == "nyan")
		{
			boyfriend.cameras = [camHUD];
			dad.cameras = [camHUD];

			dad.scale.set(1, 1);
			boyfriend.scale.set(1, 1);

			dad.updateHitbox();
			boyfriend.updateHitbox();

			boyfriend.screenCenter();
			dad.screenCenter();

			
			boyfriend.x += 100;
			
			boyfriend.y += 20;
			dad.y += 20;

			boyfriend.flipX = !boyfriend.flipX;

			dad.x -= FlxG.width / 4;
			boyfriend.x += FlxG.width / 4;
		}
		if (Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity"))
		{
			dad.y += FlxG.height * 3.3;
			boyfriend.y += FlxG.height * 3.3;

			boyfriend.x -= FlxG.width * 4.5;
			dad.x -= FlxG.width * 4.5;
		}

		if (Paths.formatToSongPath(SONG.song) == "in-the-end,-it's-all-fine")
		{
			dad.x -= 700;
			dad.y -= 550;

			boyfriend.x -= 600;
			boyfriend.y -= 550;

			remove(boyfriendGroup);
			remove(dadGroup);

			var reflection:Reflection = new Reflection(boyfriend, -boyfriend.height / 4 + 40);
			add(reflection);

			var reflection:Reflection = new Reflection(dad);
			add(reflection);
		}

		numScore = new FlxSpriteGroup();
		add(numScore);

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 240, 0, 400, "", 32);
		timeTxt.y = 85;
		timeTxt.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = !ClientPrefs.hideTime && !windowsXP && curStage != 'resonance' && !Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity") && SONG.song != "nyan" && Paths.formatToSongPath(SONG.song) != "insanity-infusion" && curStage != 'earth' && curStage != "end";
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 100;

		add(timeTxt);

		timeTxt.y += 25;

		lifeTxt = new FlxText(timeTxt.x, timeTxt.y - timeTxt.height - 10);
		lifeTxt.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		lifeTxt.scrollFactor.set();
		lifeTxt.alpha = 0;
		lifeTxt.visible = timeTxt.visible;
		lifeTxt.borderSize = 2;
		add(lifeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		holdNotes = new FlxTypedGroup();
		for (i in 0...4)
		{
			var sprite:FlxSprite = new FlxSprite();
			sprite.frames = Paths.getSparrowAtlas('${i + 1}');
			sprite.animation.addByPrefix('$i', 'sustain cover OG0', 12, false);
			sprite.animation.play('$i');
			sprite.visible = false;
			holdNotes.add(sprite);

			if (curStage == "resonance")
				sprite.scale.scale(0.5);
		}
		add(holdNotes);

		holdNotesOpponent = new FlxTypedGroup();
		for (i in 0...4)
		{
			var sprite:FlxSprite = new FlxSprite();
			sprite.frames = Paths.getSparrowAtlas('${i + 1}');
			sprite.animation.addByPrefix('$i', 'sustain cover OG0', 12, false);
			sprite.animation.play('$i');
			sprite.visible = false;
			holdNotesOpponent.add(sprite);

			if (curStage == "resonance")
				sprite.scale.scale(0.5);
		}
		add(holdNotesOpponent);

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys()) {
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(luaToLoad));
			}
		}
		for (event in eventPushedMap.keys()) {
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(luaToLoad));
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		if (!Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity")
			&& curStage != 'resonance' && curStage != 'earth' && curStage != "end")
			moveCameraSection(0);
		
		if (curStage == 'resonance')
		{
			dad.x -= FlxG.width * 1.5;
			dad.y -= FlxG.height;

			boyfriend.y -= FlxG.height;
			boyfriend.x -= FlxG.width * 1;
		}

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		var scorey = FlxG.height * 0.89;
		if (ClientPrefs.downScroll)
			scorey = 0.02 * FlxG.height;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.visible = !ClientPrefs.hideHud;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.visible = !ClientPrefs.hideHud;
		add(iconP2);

		scoreTxt = new FlxText(0, scorey + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity") ? Paths.font('digi.ttf') : Paths.font("vcr.ttf"), Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity") ? 40 : 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.5;
		scoreTxt.visible = !ClientPrefs.hideHud && !windowsXP && SONG.song != "nyan" && curStage != 'earth' && curStage != "end" && curStage != "end";
		scoreTxt.antialiasing = false;
		add(scoreTxt);

		effectTxt = new FlxText(scoreTxt.x, scoreTxt.y - scoreTxt.height - 10);
		effectTxt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		effectTxt.scrollFactor.set();
		effectTxt.borderSize = 1.25;
		effectTxt.visible = Paths.formatToSongPath(SONG.song) == "insanity-infusion" || Paths.formatToSongPath(SONG.song) == "please-don't";
		add(effectTxt);
		
		frozenTxt = new FlxText(scoreTxt.x, scoreTxt.y - scoreTxt.height, FlxG.width, "", 20);
		frozenTxt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		frozenTxt.scrollFactor.set();
		frozenTxt.text = "FROZEN! CAN'T HIT NOTES!";
		frozenTxt.screenCenter(X);
		frozenTxt.color = FlxColor.CYAN;
		frozenTxt.y = scoreTxt.y - scoreTxt.height;
		frozenTxt.borderSize = 1.25;
		frozenTxt.visible = false;
		add(frozenTxt);

		dontText = new FlxText();
		dontText.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
		dontText.text = "DON'T press any keys except your keybinds!";
		dontText.scrollFactor.set();
		dontText.screenCenter(X);
		dontText.y = FlxG.height * 2;
		dontText.borderSize = 1.25;
		dontText.visible = Paths.formatToSongPath(SONG.song) == "please-don't";
		add(dontText);

		strumLineNotes.cameras = [camHUD];
		holdNotes.cameras = [camHUD];
		holdNotesOpponent.cameras = [camHUD];
		notes.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		effectTxt.cameras = [camHUD];
		frozenTxt.cameras = [camHUD];
		dontText.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		lifeTxt.cameras = [camHUD];

		if (Paths.formatToSongPath(SONG.song) == "ascending-insanity"
			|| Paths.formatToSongPath(SONG.song) == "warmth-without-insanity"
			|| curStage == 'resonance'
			|| Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity")
			|| SONG.song == "nyan"
			|| curStage == 'earth'
			|| windowsXP)
		{
			if (ClientPrefs.downScroll)
				scoreTxt.y = 30;
		}
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		updateTime = true;

		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'data/' + Paths.formatToSongPath(SONG.song) + '/script.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		if (curStage == "resonance")
		{
			resonanceBG = new FlxSprite();
			resonanceBG.loadGraphic(Paths.image("resonance_bg_trans"));
			resonanceBG.scrollFactor.set();
			resonanceBG.cameras = [camHUD];
			add(resonanceBG);

			Note.swagWidth = 160 * 0.35;
		}
		
		var daSong:String = Paths.formatToSongPath(curSong);
		switch daSong
		{
			case "beginning-of-a-new-insanity" if (isStoryMode):
				inCutscene = true;
				canPause = false;
				moveCamera(true);
				snapCamPosToFollow();
				/*intro = new FlxVideo();
				intro.load("assets/videos/intro.mp4");
				var end = () -> {
					if (intro == null)
						return;
					inCutscene = false;
					intro.dispose();
					intro = null;
					startCountdown();
				}
				intro.onEndReached.add(end);
				intro.onStopped.add(end);
				intro.play();*/
				var sub = new Dialogue(["[BurritoFriend feels uneasy.]"]);
				sub.onClose = () -> {
					new FlxTimer().start(0.2, (tmr) -> {
						remove(sub);	
						inCutscene = false;
						startCountdown();
						canPause = true;
					});
				}
				add(sub);
			case "title.wma":
				generateStaticArrows(0);
				generateStaticArrows(1);

				bootUp = new FlxVideoSprite();
				bootUp.load("assets/videos/bootup.mp4");
				bootUp.cameras = [camXP];

				bootOff = new FlxVideoSprite();
				bootOff.load("assets/videos/bootoff.mp4");
				bootOff.cameras = [camXP];

				var end = () -> {
					if (bootUp != null)
					{
						Conductor.songPosition = -1000.;
						startedCountdown = true;

						inCutscene = false;
						remove(bootUp);
						bootUp.kill();
						bootUp.destroy();
						bootUp = null;
					}
				}
				bootUp.bitmap.onStopped.add(end);
				bootUp.bitmap.onEndReached.add(end);
				bootUp.play();
				add(bootUp);
			case "kitty's-insanity" if (!leftSide && FlxG.save.data.explainedPussy != true):
				canPause = false;

				FlxTween.tween(camHUD, {alpha: 0}, 0.5);
				var substate = new CoolKittenSubstate();
				substate.onDestroy = function()
				{
					FlxTween.tween(camHUD, {alpha: 1}, 0.8, {onComplete: (twn) -> {
						startCountdown();
					}});
					remove(substate);
					canPause = true;
				}
				add(substate);
			case "warmth-without-insanity" if (FlxG.save.data.explainedWarm != true):
				canPause = false;
				FlxTween.tween(camHUD, {alpha: 0}, 0.5);

				var substate = new WarmSubstate();
				substate.onDestroy = function()
				{
					canPause = true;
					FlxTween.tween(camHUD, {alpha: 1}, 0.4, {onComplete: (twn) -> {
						startCountdown();
					}});
					remove(substate);
				}
				add(substate);
			case "we're-landing-at-last" if (FlxG.save.data.explainedLand != true):
				canPause = false;
				FlxTween.tween(camHUD, {alpha: 0}, 0.5);

				var substate = new LandSubstate();
				substate.onDestroy = function()
				{
					canPause = true;
					FlxTween.tween(camHUD, {alpha: 1}, 0.4, {onComplete: (twn) -> {
						startCountdown();
					}});
					remove(substate);
				}
				add(substate);
			case "ascending-insanity":
				FlxG.autoPause = false;
				canPause = false;
				if (FlxG.save.data.ascendingPerm != true)
				{	
					FlxTween.tween(camHUD, {alpha: 0}, 0.5);
					var substate = new AscendingInsanitySubstate();
					substate.onDestroy = function()
					{
						FlxTween.tween(camHUD, {alpha: 1}, 0.8, {onComplete: (twn) -> {
							startCountdown();
						}});
						remove(substate);
					}
					add(substate);
				}
				else
					startCountdown();
			case "unholy-insanity-resonance" | "unholy-insanity-resonance-old":
				Conductor.songPosition = -(1000);
				startedCountdown = true;

				generateStaticArrows(0);
				generateStaticArrows(1);
			default:
				startCountdown();
		}

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter());
		#end

		oldDadY = dad.y;
		oldBfY = boyfriend.y;
		if (Paths.formatToSongPath(SONG.song) == "hold-your-insanity")
			health = 1.5;
		if (leftSide)
			health = 1.75;

		click = new ClickHere();
		click.y = FlxG.height;
		click.x = 30;
		click.cameras = [camOther];
		if (Songs.songs.exists(Paths.formatToSongPath(SONG.song)))
		{
			add(click);
			FlxTween.tween(click, {y: FlxG.height - click.height}, 2.5, {ease: FlxEase.expoInOut, onUpdate: (tmr) -> {
			}, onComplete: (tmr) -> {
				new FlxTimer().start(5, function(tmr) 
				{
					FlxTween.tween(click, {y: FlxG.height + click.height + 20}, 2.5, {ease: FlxEase.expoInOut, onComplete: (tmr) -> {
						click.active = false;
						remove(click);
						click.kill();
						click.destroy();
						click = null;
						if (!windowsXP)
							FlxG.mouse.visible = false;
					}});
				});
			}});
		}
		super.create();

		if (Paths.formatToSongPath(SONG.song) == "please-don't")
			FlxTween.tween(dontText, {y: scoreTxt.y - scoreTxt.height - 10}, 1, {ease: FlxEase.expoInOut, onComplete: function(twn)
			{
				new FlxTimer().start(15, function(tmr)
				{
					FlxTween.tween(dontText, {y: FlxG.height * 2}, 2, {ease: FlxEase.expoInOut, onComplete: function(twn)
					{	
						dontText.visible = false;
					}});
				});
			}});

		if (curStage == "earth")
		{
			var bg = new BGSprite("space");
			bg.cameras = [camHUD];
			bg.scrollFactor.set();
			bg.screenCenter();
			add(bg);	
		}
		if (Paths.formatToSongPath(SONG.song) == "insanity-infusion")
		{
			infuseText = new FlxText();
			infuseText.setFormat(Paths.font("vcr.ttf"), 75, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
			infuseText.borderSize = 2;
			infuseText.borderQuality = 2;
			infuseText.text = "Switching sides...";
			infuseText.cameras = [camHUD];
			infuseText.screenCenter(X);
			infuseText.y = FlxG.height * 2;
			infuseText.alpha = 0;
			add(infuseText);
		}

		if (Paths.formatToSongPath(SONG.song) == "silly-but-sad-cat-song")
			camZooming = true;
	}
	var healthString = "0.00000001";
	var bootUp:FlxVideoSprite;
	var bootOff:FlxVideoSprite;
	var intro:FlxVideo;

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(BF_X, BF_Y, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.visible = false;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(DAD_X, DAD_Y, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad);
					newDad.visible = false;
				}
		}
	}
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			return;
		}

		inCutscene = false;
		//if(ret != FunkinLua.Function_Stop) 
		
			generateStaticArrows(0);
			generateStaticArrows(1);

			var crochet = Conductor.crochet + 0;
			if (Paths.formatToSongPath(SONG.song) == "insanity")
				crochet = crochet * 2;
			Conductor.songPosition = 0;
			Conductor.songPosition -= crochet * 5;

			var swagCounter:Int = 0;

			var ready:FlxSprite = null;

			startTimer = new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				if(tmr.loopsLeft % 2 == 0) {
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.specialAnim)
					{
						//boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.specialAnim)
					{
						//dad.dance();
					}
				}
				else if(dad.danceIdle && dad.animation.curAnim != null && !dad.specialAnim && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing"))
				{
					//dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['poweron', 'booting', 'welcome']);
		
				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				var altSuffix:String = "";

				switch (swagCounter)
				{
					case 0: 
						var startUp:FlxSound = new FlxSound().loadEmbedded(Paths.sound("startup"));
						startUp.play(true);

						ready = new FlxSprite().loadGraphic(Paths.image("welcome"));
						ready.scrollFactor.set();
						ready.screenCenter();
						ready.antialiasing = false;
						add(ready);
					case 1:
						
					case 2:
						//FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
					case 3:
						startedCountdown = true;

						boyfriend.playAnim("hey");
						boyfriend.specialAnim = true;

						//FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
					case 4:

						remove(ready);
				}

				if (generatedMusic)
				{
					notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				}

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(lifeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		if (curStage == 'resonance')
		{
			timeBar = new FlxBar(175, FlxG.height / 1.8 + 35, 600, 3, FlxG.sound.music, "time", 0, songLength);
			timeBar.createFilledBar(FlxColor.GRAY, FlxColor.RED);
			timeBar.numDivisions = 3200;
			timeBar.cameras = [camHUD];
			timeBar.alpha = 0;
			add(timeBar);
			
			if (ClientPrefs.downScroll)
				timeBar.y = 100;

			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter(), true, songLength);
		#end

		if (Paths.formatToSongPath(SONG.song) == "insanity-infusion")
		{
			for (i in 0...(leftSide ? playerStrums : opponentStrums).length)
			{
				var strum = (leftSide ? playerStrums : opponentStrums).members[i];
				if (strum != null)
				{
					strum.ID += 4;
					(!leftSide ? playerStrums : opponentStrums).add(strum);
				}
			}
		}
	}

	var sBurritos:Int;
	var burritos:Int;
	var burritod:Int;
	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);
		if (windowsXP)
		{
			add(taskbar);
			add(startMenu);
			add(startButtonPressed);
		}

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if(songNotes[1] < 0) {
						eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);
					if (Paths.formatToSongPath(SONG.song) == "insanity-infusion")
						daNoteData = Std.int(songNotes[1]);

					var gottaHitNote:Bool = section.mustHitSection;

					var notel = Paths.formatToSongPath(SONG.song) == "insanity-infusion" ? 7 : 3;
					if (songNotes[1] > notel && !leftSide)
					{
						gottaHitNote = !section.mustHitSection;
					}
					else if (songNotes[1] <= notel && leftSide)
					{
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType = songNotes[3];
					if (swagNote.noteType == 'Middle Note')
					{
						swagNote.noteData = 4;
						swagNote.mustPress = true;
					}
					swagNote.scrollFactor.set();
					if (SONG.song == "nyan")
						swagNote.yMult = FlxG.random.float(0.44, 0.48);

					var susLength:Float = swagNote.sustainLength;

					if (Paths.formatToSongPath(SONG.song) == "insanity-infusion")
					{
						if (leftSide && !gottaHitNote)
							swagNote.visible = false;
						else if (!leftSide && !gottaHitNote)
							swagNote.visible = false;
					}

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.round(susLength);
					var len:Int = 0;
					if(floorSus > 0 && songNotes[3] != "Kitty Note" && songNotes[3] != "Middle Note") {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(SONG.speed, 2)), daNoteData % 4, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.visible = swagNote.visible;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);

							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
							len++;
						}
					}

					swagNote.noteLength = len;
					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else {}

					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
				} else { //Event Notes
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			
		}
		for(i in unspawnNotes) {
			if(i.mustPress && !i.ignoreNote)
				burritos++;
			else if (i.mustPress && (i.noteType == 'Kitty Note' || i.noteType == 'Middle Note'))
				burritod++;
			if (i.mustPress && !i.ignoreNote && !i.isSustainNote)
				sBurritos++;
		}
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...(player == 1 && (Paths.formatToSongPath(SONG.song).contains("insanity-infusion")) ? 5 : 4))
		{
			// FlxG.log.add(i);
			var babyArrow:StrumNote = new StrumNote(STRUM_X, strumLine.y, i);

			var skin:String = 'NOTE_assets';
			if (i == 4)
				skin = 'burritoStrum';

			if(SONG.arrowSkin != null && SONG.arrowSkin.length > 1) skin = SONG.arrowSkin;
			if (true)
			{
				babyArrow.frames = Paths.getSparrowAtlas(skin);
				babyArrow.antialiasing = ClientPrefs.globalAntialiasing;
				babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
				if (curStage == "resonance")
				{
					babyArrow.scale.scale(0.5, 0.5);
					babyArrow.x += Note.swagWidth / (player + 1) + 20;
					if (player == 1)
						babyArrow.x -= Note.swagWidth * 4;

					if (ClientPrefs.downScroll)
						babyArrow.y -= Note.swagWidth * 4 - 25;
					else
						babyArrow.y += Note.swagWidth;
				}
				babyArrow.ogScale = babyArrow.scale.x;

				switch (i)
				{
					case 0:
						babyArrow.x += Note.swagWidth * 0;
						babyArrow.animation.addByPrefix('static', 'arrowLEFT');
						babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
					case 1:
						babyArrow.x += Note.swagWidth * 1;
						babyArrow.animation.addByPrefix('static', 'arrowDOWN');
						babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
					case 2:
						babyArrow.x += Note.swagWidth * 2;
						babyArrow.animation.addByPrefix('static', 'arrowUP');
						babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
					case 3:
						babyArrow.x += Note.swagWidth * 3;
						babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
						babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					case 4:
						babyArrow.animation.addByPrefix('static', 'middle static0');
						babyArrow.animation.addByPrefix('pressed', 'middle press0', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'middle confirm0', 24, false);

						babyArrow.screenCenter(X);
				}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				if (i == 4 && Paths.formatToSongPath(SONG.song).contains("insanity-infusion"))
					babyArrow.y -= 30;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
			{
				if (Paths.formatToSongPath(SONG.song).contains("insanity-infusion") && i == 4)
				{
					add(babyArrow);
				}
				else
					playerStrums.add(babyArrow);
				
			}
			else
			{
				opponentStrums.add(babyArrow);
			}

			
			babyArrow.playAnim('static');
			if (!(Paths.formatToSongPath(SONG.song).contains("insanity-infusion") && i == 4))
			{
				babyArrow.x += 50;
				babyArrow.x += ((FlxG.width / 2) * player);
				strumLineNotes.add(babyArrow);
			}

			if (i == 4 && Paths.formatToSongPath(SONG.song).contains("insanity-infusion"))
			{
				burritoStrum = babyArrow;
				babyArrow.x += 30;
				babyArrow.y -= 100;
			}
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			var chars:Array<Character> = [boyfriend, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (startTimer != null && finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			var chars:Array<Character> = [boyfriend, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}

			paused = false;

			for (i in [holdNotes, holdNotesOpponent])
			{
				for (i in i)
				{
					i.visible = false;
				}
			}

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter(), true, FlxG.sound.music.length - FlxG.sound.music.time);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song, iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	var warmness(default, set):Float = 100;
	public var warmnessLevel(get, never):String;
	var insanityHold:Float;
	var insanityIncrase:Float;
	var playedInsanity:Bool;
	var hpCount:Int = 7;
	override public function update(elapsed:Float)
	{
		switch currentEffect
		{
			case "stuck_down":
				var strum = (leftSide ? opponentStrums : playerStrums).members[1 + infuseCount];
				if (strum != null)
				{
					strum.playAnim("pressed");
				}
			case "randompos":
				Application.current.window.x = randomPosX;
				Application.current.window.y = randomPosY;
			case "hud_angle":
				camHUD.angle = FlxG.random.float(-4, 4);
			case "angle_180":
				camGame.angle += 2;
				camHUD.angle += 2;
		}

		if (intro != null && intro.time > 5000 && (controls.BACK || controls.ACCEPT))
		{
			intro.stop();
		}

		if (xpShader != null)
		{
       		//xpShader.update(elapsed);
		}
		if (bootUp != null && bootUp.bitmap.time >= 2500 && (controls.ACCEPT || controls.BACK))
		{
			bootUp.stop();
		}
		
		iconP1.x = boyfriend.x;
		iconP2.x = dad.x + dad.width + iconP2.width - 50;

		iconP1.y = boyfriend.y;
		iconP2.y = dad.y + dad.width;

		if (curStage == "earth")
		{
			angle1 += elapsed;
        	angle2 += elapsed;
			earth.angle += 0.3;

			var orbitRadius = 1500;
			dad.x = earth.x + Math.cos(angle1) * orbitRadius + dad.width / 2 + orbitRadius / 3;
			dad.y = earth.y + Math.sin(angle1) * orbitRadius + dad.height / 2 + orbitRadius / 3;

			boyfriend.x = earth.x + Math.cos(angle2) * orbitRadius + boyfriend.width / 2 + orbitRadius / 3;
			boyfriend.y = earth.y + Math.sin(angle2) * orbitRadius + boyfriend.height / 2 + orbitRadius / 3;

			iconP1.x = boyfriend.x - iconP1.width - 50;
			iconP2.x = dad.x - iconP2.width - 50;

			iconP1.y = boyfriend.y - boyfriend.height;
			iconP2.y = dad.y - dad.height / 2;
		}

		if (SONG.song == "nyan")
		{
			FlxG.updateFramerate = 36;
			FlxG.drawFramerate = 36;
		}
		else if (Paths.formatToSongPath(SONG.song) == "please-don't")
		{
			for (i in keys)
			{
				if (FlxG.keys.checkStatus(cast (i, FlxKey), JUST_PRESSED))
				{
					randomEffect();
				}
			}
		}

		if (FlxG.keys.justPressed.EIGHT && FlxG.save.data.finishedStory == true && !isStoryMode)
		{
			var song:String = "" + SONG.song;
			song += "-old";

			var s = null;
			try 
			{ 
				s = Song.loadFromJson(song + '-burrito', song);
				if (s != null)
				{
					SONG = s;
					isStoryMode = false;
					storyDifficulty = 0;

					vocals.volume = 0;
					FlxG.sound.music.volume = 0;

					FlxG.sound.music.stop();
					vocals.stop();

					CustomFadeTransition.nextCamera = camOther;
					MusicBeatState.resetState();
				}
			}
			catch (e) {}
		}

		if (windowsXP && FlxG.mouse.justPressed && FlxG.mouse.x >= -815 && FlxG.mouse.x <= -645)
		{
			var switchVisible = if (!ClientPrefs.downScroll && FlxG.mouse.y >= 1384 && FlxG.mouse.y <= 1441) true
			else if (ClientPrefs.downScroll && FlxG.mouse.y <= -30 && FlxG.mouse.y >= -88) true
			else false;

			if (switchVisible)
			{
				startMenu.visible = !startMenu.visible;
				startButtonPressed.members[0].visible = startMenu.visible;
			}
		}
		if (lc < 0)
			lc = 0;
		else if (lc > 100)
			lc = 100;
		if (lcM < 0.25)
			lcM = 0.25;

		insanityIncrase += FlxG.elapsed / 25000;
		if (Paths.formatToSongPath(SONG.song) == "hold-your-insanity" && !controls.NOTE_MIDDLE && insanityHold < 180 && !startingSong)
			health -= elapsed / 4.5 + insanityIncrase;

		var l = Songs.songs.get(Paths.formatToSongPath(PlayState.SONG.song));
		if (l != null && click != null && click.active) 
		{
			FlxG.mouse.visible = true;
			if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(click, camHUD)) 
			{
				CoolUtil.browserLoad(l);
			}
		}

		if(!inCutscene || windowsXP) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		super.update(elapsed);

		if (!startingSong)
			warmness -= 0.0326;
		
		if (Paths.formatToSongPath(SONG.song) == "warmth-without-insanity")
		{
			var text = 'Warmness Level: ' + warmnessLevel;
			if (warmness <= 25)
				frozenTxt.visible = true;
			scoreTxt.text = text;
		}
		else if (Paths.formatToSongPath(SONG.song) == "unholy-insanity-resonance")
		{
			if (songMisses > 17)
				health = 0;

			scoreTxt.text = 'Resonances: $songScore | Misses: $songMisses/17';
		}
		else if (Paths.formatToSongPath(SONG.song) == "hold-your-insanity")
		{
			if (insanityHold >= 180 && !playedInsanity)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				playedInsanity = true;
			}
			
			if (controls.NOTE_MIDDLE || insanityHold >= 180)
			{
				insanityHold += elapsed;
				scoreTxt.color = FlxColor.WHITE;
				scoreTxt.text = "HOLDING INSANITY";
				if (insanityHold >= 180)
					scoreTxt.text += " COMPLETE";
			}
			else
			{
				scoreTxt.color = FlxColor.RED;
				@:privateAccess scoreTxt.text = 'NOT HOLDING INSANITY (HOLD ${FlxKey.toStringMap.get(cast controls._note_middle.inputs[0].inputID)})';
			}
		}
		else if (Paths.formatToSongPath(SONG.song) == "silly-but-sad-cat-song")
			scoreTxt.text = "CATS!!";
		else
			scoreTxt.text = 'Burritos: $songScore/$burritos($sBurritos) | Misses: ' + songMisses;

		if (Paths.formatToSongPath(SONG.song) == "we're-landing-at-last")
			scoreTxt.text += ' | Landing Chance: %${FlxMath.roundDecimal(lc, 2)}';
		else if (Paths.formatToSongPath(SONG.song) == "insanity-infusion-old")
		{
			if (!leftSide)
				scoreTxt.text += ' | Collected Burritos: %${FlxMath.roundDecimal((1 - Note.earlyHitMultMinus) * 100, 2)}';
		}
		effectTxt.text = "CURRENT EFFECT: " + currentEffectText;
		effectTxt.screenCenter(X);

		function pause()
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			if(FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
			if (!windowsXP)
			{
				PauseSubState.transCamera = camOther;
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}
			else 
			{
				openSubState(new PauseXPSubState(camXP, camHUD, camGame, xpShader.shader));
			}
			
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song, iconP2.getCharacter());
			#end
		}

		if ((FlxG.keys.justPressed.ENTER || (FlxG.keys.justPressed.ESCAPE && windowsXP)) && startedCountdown && canPause)
		{
			pause();	
		}
		if (windowsXP && startMenu.visible && FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.x >= -255 && FlxG.mouse.x <= 9 
				&& FlxG.mouse.y >= 1316 && FlxG.mouse.y <= 1381)
				pause();
		}

		if (health > 2)
			health = 2;
		
		var playerIcon:HealthIcon = (leftSide ? iconP2 : iconP1);
		var opponentIcon:HealthIcon = (!leftSide ? iconP2 : iconP1);

		if (playerIcon.visible)
		{
			if (health <= 0.6)
				playerIcon.animation.curAnim.curFrame = 1;
			else if (health >= 1.2 && leftSide)
				playerIcon.animation.curAnim.curFrame = 2;
			else
				playerIcon.animation.curAnim.curFrame = 0;
		}
		if (opponentIcon.visible)
		{
			if (health >= 1.2)
				opponentIcon.animation.curAnim.curFrame = 1;
			else if (health > 0.6)
				opponentIcon.animation.curAnim.curFrame = 0;
			else if (!leftSide)
				opponentIcon.animation.curAnim.curFrame = 2;
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = FlxG.sound.music.time - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					var minutesRemaining:Int = Math.floor(secondsTotal / 60);
					var secondsRemaining:String = '' + secondsTotal % 60;
					if(secondsRemaining.length < 2) secondsRemaining = '0' + secondsRemaining; //Dunno how to make it display a zero first in Haxe lol
					timeTxt.text = minutesRemaining + ':' + secondsRemaining;
					if (Paths.formatToSongPath(SONG.song) == "silly-but-sad-cat-song")
						timeTxt.text = "CATS!!";
				}

				lifeTxt.x = timeTxt.x + timeTxt.width / 4 + 35;
				var healthString = Std.string(FlxMath.roundDecimal(health * 100 / 2, 2));
				if (healthString.length == 1)
					healthString = "0" + healthString;
				if (!healthString.contains('.'))
					healthString += '.00';
				else if (healthString.split('.')[1].length < 2)
					healthString += '0';
				if (healthString.split('.')[0].length < 2)
					healthString = "0" + healthString;
				if (health >= 2)
					healthString = "99.99";
				else if (healthString == "00.00")
					healthString = "00.01";

				lifeTxt.text = "%" + healthString;
				if (Paths.formatToSongPath(SONG.song) == "silly-but-sad-cat-song")
					lifeTxt.text = "CATS!!";
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		
		if (controls.RESET && !inCutscene && !endingSong && Paths.formatToSongPath(SONG.song) != 'ascending-insanity' && curStage != "end")
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			//if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (Paths.formatToSongPath(SONG.song) != "adequate-insanity-old")
		{
			if (curStage == "earth")
				healthHurtValue += elapsed / 25000;
			else
			{
				if (Paths.formatToSongPath(SONG.song) != "silly-but-sad-cat-song")
					healthHurtValue += elapsed / (Paths.formatToSongPath(SONG.song) != "hold-your-insanity" ? (6000 * (Paths.formatToSongPath(SONG.song) == "we're-landing-at-last" ? 1.25 : 1)) : 15000);
				else
					healthHurtValue += elapsed / 75000;
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumX:Float = 0;
				var strumY:Float = 0;
				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
				if(daNote.mustPress) {
					var playerStrums = leftSide ? opponentStrums : playerStrums;
					if (daNote.noteType == "Middle Note")
					{
						strumX = burritoStrum.x;
						strumY = burritoStrum.y;
						strumAngle = burritoStrum.angle;
						strumAlpha = burritoStrum.alpha;
					}	
					else 
					{
						strumX = playerStrums.members[daNote.noteData].x;
						strumY = playerStrums.members[daNote.noteData].y;
						strumAngle = playerStrums.members[daNote.noteData].angle;
						strumAlpha = playerStrums.members[daNote.noteData].alpha;
						
						if (Paths.formatToSongPath(SONG.song) == "insanity-infusion" && daNote.isSustainNote)
							strumX = playerStrums.members[daNote.noteData + infuseCount].x;
					}
				} else {
					var opponentStrums = !leftSide ? opponentStrums : playerStrums;
					if (Paths.formatToSongPath(SONG.song) != "insanity-infusion")
					{
						strumX = opponentStrums.members[daNote.noteData].x;
						strumY = opponentStrums.members[daNote.noteData].y;
						strumAngle = opponentStrums.members[daNote.noteData].angle;
						strumAlpha = opponentStrums.members[daNote.noteData].alpha;
					}
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				//strumAlpha *= daNote.multAlpha;
				var center:Float = strumY + Note.swagWidth / 2;

				if(daNote.copyX) {
					daNote.x = strumX;
				}
				if(daNote.copyAngle) {
					daNote.angle = strumAngle;
				}
				else if (curStage == "earth" && !daNote.isSustainNote)
					daNote.angle += daNote.angleMult * 3;
				else if (currentEffect == "spin" && !daNote.isSustainNote)
					daNote.angle += daNote.angleMult * 10;
				if(daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}
				if (daNote.mustPress && currentEffect == "no_hit" && !daNote.isSustainNote)
					daNote.earlyHitMult = 0.25;
				if (warmness <= 25 && daNote.mustPress && Paths.formatToSongPath(SONG.song) == "warmth-without-insanity")
				{
					daNote.canBeHit = false;
					for (i in 0...4)
						(leftSide ? opponentStrums : playerStrums).members[i].alpha = 0.4;
				}
				if(daNote.copyY) {
					if (ClientPrefs.downScroll) 
					{
						daNote.y = (strumY + daNote.yMult * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote) {
							//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end')) {
								if (curStage == 'resonance')
								{
									daNote.scale.y = 0.35;
									daNote.updateHitbox();
								}
							
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8;
								} else {
									daNote.y -= 19;
								}

								if (curStage == 'resonance')
									daNote.y += 45;
							} 
							daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							if (Paths.formatToSongPath(SONG.song) != 'beginning-of-a-new-insanity-old')
								daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1); 

							if((daNote.mustPress || !daNote.ignoreNote))
							{
								if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
						}
					} else {
						daNote.y = (strumY - daNote.yMult * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if (daNote.isSustainNote && curStage == 'resonance') {
							if (daNote.animation.curAnim != null && daNote.animation.curAnim.name.endsWith('end'))
							{
								daNote.scale.y = 0.35;
								daNote.updateHitbox();

								daNote.y -= 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
							}

							daNote.y -= (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
						}
						if((daNote.mustPress || !daNote.ignoreNote))
						{
							if (daNote.isSustainNote
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				function miss(missed:Bool)
				{
					var dad = leftSide ? boyfriend : dad;
					var opponentStrums = leftSide ? playerStrums : opponentStrums;
					if(daNote.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = 0.6;
					} else {
						var altAnim:String = "";

						if (SONG.notes[Math.floor(curStep / 16)] != null)
						{
							
						}

						var animToPlay:String = '';
						switch (Paths.formatToSongPath(SONG.song) == "insanity-infusion" ? Math.abs(daNote.noteData % 4) : Math.abs(daNote.noteData))
						{
							case 0:
								animToPlay = 'singLEFT';
							case 1:
								animToPlay = 'singDOWN';
							case 2:
								animToPlay = 'singUP';
							case 3:
								animToPlay = 'singRIGHT';
							case 4: 
								animToPlay = 'singMIDDLE';
						}
						if (missed)
							animToPlay += 'miss';
						dad.playAnim(animToPlay + altAnim, (leftSide && !daNote.isSustainNote) || !leftSide);
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = missed ? 0 : 1;

					var time:Float = !leftSide ? 0.22 : FlxG.random.float(0.05, 0.3);
					if(daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
						time += !leftSide ? 0.22 : FlxG.random.float(0.05, 0.3);
					}
					if (!missed)
					{
						if (Paths.formatToSongPath(SONG.song) != "insanity-infusion")
							StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)), time);
					}
					
					if (leftSide && !daNote.isSustainNote && daNote.noteType != 'Middle Note')
					{
						if (missed)
							combo = 0;
						else
							combo++;
						
						popUpScore(daNote);
					}
					daNote.hitByOpponent = true;
					if (!missed)
					{
						if (!leftSide)
						{
							if (health > healthHurtValue &&
								Paths.formatToSongPath(SONG.song) != "insanity"
								&& curStage != 'resonance'
								&& (Paths.formatToSongPath(SONG.song) != "hold-your-insanity" || insanityHold >= 180)
								&& !windowsXP
								&& curStage != "end")
							{
								if (daNote.isSustainNote && (Paths.formatToSongPath(SONG.song) == "insanity-infusion" || Paths.formatToSongPath(SONG.song) == "insanity-infusion-old"))
									health -= (healthHurtValue / 3) * (currentEffect == "miss_triple" ? 3 : 1);
								else
									health -= healthHurtValue;
							}
						}
						else if (health > daNote.hitHealth && daNote.noteType != 'Middle Note')
							health -= daNote.hitHealth;
					}
					else 
						health += daNote.missHealth;

					daNote.wasGoodHit = true;
					if ((!daNote.isSustainNote) && !missed)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}

					if (Paths.formatToSongPath(SONG.song) != "insanity-infusion")
					{
						if (daNote.isSustainNote || daNote.noteLength > 0)
						{
							var sprite = holdNotesOpponent.members[daNote.noteData % 4];
							var strum = (!leftSide ? opponentStrums : playerStrums).members[daNote.noteData % 4];
							sprite.visible = (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) || daNote.noteLength > 0;
							sprite.animation.play('${daNote.noteData % 4}');
							sprite.x = strum.x - 22;
							sprite.y = strum.y - 8;

							if (curStage == "resonance")
							{
								sprite.x -= 30;
								sprite.y -= 27;
							}
						}
						else 
							holdNotesOpponent.members[daNote.noteData % 4].visible = false;
					}

					if (!resynced)
					{
						resyncVocals();
						resynced = true;
					}
				}

				var i:Float = 0;
				if (leftSide)
					if (!daNote.isSustainNote)
						i = FlxG.random.int(-45, 45);

				if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition + i)
				{
					var missed:Bool = false;
					if (leftSide && !daNote.ignoreNote && !daNote.isSustainNote && daNote.noteType != 'Middle Note')
					{
						missed = FlxG.random.bool(Paths.formatToSongPath(SONG.song) == "insanity" ? -1 : 0.25);
					}
					if (!missed)
						miss(false);
					else
						daNote.hitByOpponent = true;
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				var doKill:Bool = daNote.y < -daNote.height;
				if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;
				if (curStage == 'resonance' && doKill)
				{
					doKill = daNote.animation.curAnim != null && !daNote.animation.curAnim.name.endsWith('end');
				}

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled)
					{
						if (daNote.tooLate || !daNote.wasGoodHit)
						{
							if(!endingSong) {
								//Dupe note remove
								notes.forEachAlive(function(note:Note) {
									if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10) {
										note.kill();
										//noteMiss(note.noteData);
										notes.remove(note, true);
										note.destroy();
									}
								});

								if(!daNote.ignoreNote) {
									var boyfriend = leftSide ? dad : boyfriend;
									if (!leftSide)
									{
										if (curStage != "end")
										{
											if (Paths.formatToSongPath(SONG.song) == "warmth-without-insanity")
												health -= 0.02;
											else if (Paths.formatToSongPath(SONG.song) == "ascending-insanity")
												health -= daNote.missHealth * 4;
											else
												health -= daNote.missHealth * (currentEffect == "miss_triple" ? 3 : 1); //For testing purposes
										}
									}
									else
										health -= daNote.missHealth * 1.5;
									warmness -= 5;
									songMisses++;
									if (!leftSide)
									{
										combo = 0;
										popUpScore(daNote);
									}
									vocals.volume = 0;

									switch (daNote.noteData % 4)
									{
										case 0:
											boyfriend.playAnim('singLEFTmiss', true);
										case 1:
											boyfriend.playAnim('singDOWNmiss', true);
										case 2:
											boyfriend.playAnim('singUPmiss', true);
										case 3:
											boyfriend.playAnim('singRIGHTmiss', true);
									}
									lc -= lcM;
									lcM -= 0.25;
								} else if (daNote.noteType == 'Middle Note')
								{
									randomEffect();
								}
							}
						}
					}

					if (leftSide && !daNote.mustPress && !daNote.ignoreNote && !daNote.isSustainNote && !daNote.wasGoodHit)
						miss(true);

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});

			strumLineNotes.forEachAlive(function(spr:StrumNote)
			{
				if (curStage == "earth")
				{
					spr.angle += spr.randomOne * 1.5;
					holdNotes.members[spr.ID % 4].angle = spr.angle;
					holdNotesOpponent.members[spr.ID % 4].angle = spr.angle;
				}	
			});
		}

		if (!inCutscene) {
			var boyfriend = leftSide ? dad : boyfriend;
			if(!cpuControlled) {
				keyShit();
			} 
			else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				(leftSide ? dad : boyfriend).dance();
			}
		}
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', PlayState.cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		#end

		if (Paths.formatToSongPath(SONG.song) == "insanity")
		{
			if (curStep >= 2368 && curStep < 2816)
			{
				boyfriend.y -= elapsed * 30;
				moveCamera(false);
			}
			else if (!tweened && curStep >= 4352 && !paused)
			{
				FlxTween.tween(boyfriend, {y: oldBfY}, 1.6, {ease: FlxEase.expoInOut});
				tweened = true;
			}
			if (curStep >= 2368 && curStep < 4352)
			{
				boyfriend.y += Math.sin(elapsedVal);
			}

			if (curStep >= 2368 && curStep < 2816)
			{
				bg.alpha -= elapsed / 6;
			}
			else if (curStep >= 4352 && !tweenedBG)
			{
				FlxTween.tween(bg, {alpha: 1}, 1.6);
				tweenedBG = true;
			}
		}

		elapsedVal += elapsed * 2;
	}
	var elapsedVal:Float = 0;
	var oldDadY:Float;
	var oldBfY:Float;
	var tweened:Bool;
	var tweenedBG:Bool;

	var isDead:Bool = false;
	function doDeathCheck() 
	{
		if (curStage == "end")
			return false;
		if ((health <= 0 && !practiceMode && !isDead))
		{
			if (!windowsXP)
			{
				boyfriend.stunned = true;
				deathCounter++;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y, this));

					// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
					
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song, iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
			else 
			{
				finishSong();
				return true;
			}
		}
		return false;
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = Std.parseInt(value1);
				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}
			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				trace('Anim to play: ' + value1);
				var val2:Int = Std.parseInt(value2);
				if(Math.isNaN(val2)) val2 = 0;

				var char:Character = dad;
				switch(val2) {
					case 1: char = boyfriend;
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var val:Int = Std.parseInt(value1);
				if(Math.isNaN(val)) val = 0;

				var char:Character = dad;
				switch(val) {
					case 1: char = boyfriend;
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = Std.parseInt(value1);
				if(Math.isNaN(charType)) charType = 0;

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}
				}
		}
	}

	var initialCam:Bool = !!!false;
	var tweenCam:FlxTween;
	var tweenCam2:FlxTween;
	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
		}
		else
		{
			moveCamera(false);
		}
	}

	public function moveCamera(isDad:Bool) {
		var songName:String = Paths.formatToSongPath(SONG.song);
		if(isDad) {
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];

			if (songName == 'tutorial')
			{
				tweenCamIn();
			}
		} else {
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (songName == 'tutorial')
			{
				FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
			}
		}
	}

	function snapCamPosToFollow() {
		camFollowPos.setPosition(camFollow.x, camFollow.y);
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		if (Paths.formatToSongPath(SONG.song) == "we're-landing-at-last")
		{
			var b = FlxG.random.bool(lc);
			trace(b);
			if (!b)
			{
				health = 0;
				doDeathCheck();
				return;
			}
		}
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.
		if (Paths.formatToSongPath(SONG.song) == "post-insanity" && isStoryMode)
		{
			inCutscene = true;
			canPause = false;

			updateTime = false;
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			vocals.pause();

			var dialogue:Array<String> = ["[BurritoFriend doesn't feel uneasy anymore.]",
			"[The time he spent with Burrito Kitty\nmade him realize in the end it's all fine.]",
			"[Maybe you, " + Sys.getEnv("USERNAME") + ", can also realize it's fine too.]",
			"[After all, in the end it's all fine.]"];
			var sub = new Dialogue(dialogue);
			sub.onClose = () -> {
				new FlxTimer().start(0.2, (tmr) -> {
					remove(sub);	
					inCutscene = false;
					endSong();
				});
			}
			add(sub);
			return;
		}
		if (windowsXP)
			finishCallback = () -> {
				if (bootOff != null)
				{
					add(bootOff);
					bootOff.play();

					bootOff.bitmap.onEndReached.add(() -> {
						if (bootOff != null)
						{
							bootOff.kill();
							remove(bootOff);
							bootOff.destroy();
							bootOff = null;

							if (health <= 0)
								FlxG.resetState();
							else
							{
								if (SONG.validScore)
								{
									#if !switch
									var percent:Float = songScore / burritos;
									if(Math.isNaN(percent)) percent = 0;
									Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
									#end
								}

								FlxG.sound.playMusic(Paths.music('loop'));
								FlxG.switchState(new FreeplayState());
							}
						}
					});
				}
				transitioning = true;
			};
		if (Paths.formatToSongPath(SONG.song) == "in-the-end,-it's-all-fine" && FlxG.save.data.kitty == null)
		{
			Application.current.window.alert(
				'In the end, it\'s all fine.\nCheck your desktop for a little surprise, ${Sys.getEnv("USERNAME")}.',
				' '
			);

			var path = Sys.getEnv("USERPROFILE") + "\\Desktop\\kitty.txt";

			sys.io.File.saveContent(path, Kitty.kitty + '\n\nkitty burrito');
			FlxG.save.data.kitty = true;
			FlxG.save.flush();
		}

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	var transitioning = false;
	public function endSong():Void
	{		
		if (windowsXP)
			FlxG.mouse.visible = false;

		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:Int = checkForAchievement([1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15]);
			if(achieve > -1) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		if(!transitioning) 
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = songScore / burritos;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				var song = Paths.formatToSongPath(SONG.song);
				if (song == "post-insanity")
				{
					if (FlxG.save.data.finishedStory != true)
					{
						FlxG.save.data.finishedStory = true;
						FlxG.save.flush();
						add(new StoryCompleted());
						WeekData.setKittenExtra();
						return;
					}
				}

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('loop'));

					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					MusicBeatState.switchState(new MainMenuState());

					// if ()
					if(!usedPractice) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					usedPractice = false;
					changedDifficulty = false;
					cpuControlled = false;
				}
				else
				{
					var difficulty:String = '' + CoolUtil.difficultyStuff[storyDifficulty][1];

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				if (!leftSide)
				{
					if (Paths.formatToSongPath(SONG.song) == "insanity")
					{
						FlxG.save.data.finishedFirstSong = true;
						FlxG.save.flush();
					}
					else if (Paths.formatToSongPath(SONG.song) == "warmth-without-insanity")
					{
						FlxG.save.data.finishedSecondSong = true;
						FlxG.save.flush();
					}
					else if (Paths.formatToSongPath(SONG.song) == "insanity-on-earth")
					{
						FlxG.save.data.finishedThirdSong = true;
						FlxG.save.flush();
					}
				}
			
				if (FlxG.save.data.finishedFirstSong && FlxG.save.data.finishedSecondSong 
					&& FlxG.save.data.finishedThirdSong && FlxG.save.data.gaveWarning == null)
				{
					for (i in Application.current.windows)
						i.alert("You unlocked original songs!\nThey are now available in freeplay.", "New Unlock");

					FlxG.save.data.gaveWarning = true;
					FlxG.save.flush();
				}
				trace('WENT BACK TO FREEPLAY??');
				cancelFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('loop'));
				usedPractice = false;
				changedDifficulty = false;
				cpuControlled = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:Int) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	var numScore:FlxSpriteGroup;
	private function popUpScore(note:Note = null):Void
	{
		if (curStage == "earth" || curStage == "end" || curStage == "resonance")
			return;

		numScore.clear();
		
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + 8); 

		// boyfriend.playAnim('hey');
		var coolText:FlxText = new FlxText(0, 0, 0, combo + "", 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		if(!practiceMode && !cpuControlled) {
			songHits++;
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000)
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		if(combo >= 100)
			seperatedScore.push(Math.floor(combo / 100) % 10);
		if(combo >= 10)
			seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite();
			numScore.loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y = boyfriend.y - 20;

			if (!curStage.startsWith('school'))
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(250, 350);
			numScore.velocity.y -= FlxG.random.int(200, 220);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (!Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity"))
				this.numScore.add(numScore);

			daLoop++;
		}

		curSection += 1;
	}

	private function keyShit():Void
	{
		var song:Bool = false;
		if (currentEffect == "song")
			song = true;

		// HOLDING
		var up = song ? controls.NOTE_DOWN : controls.NOTE_UP;
		var right = song ? controls.NOTE_LEFT : controls.NOTE_RIGHT;
		var down = song ? controls.NOTE_UP : controls.NOTE_DOWN;
		var left = song ? controls.NOTE_RIGHT : controls.NOTE_LEFT;

		var upP = song ? controls.NOTE_DOWN_P : controls.NOTE_UP_P;
		var rightP = song ? controls.NOTE_LEFT_P : controls.NOTE_RIGHT_P;
		var downP = song ? controls.NOTE_UP_P : controls.NOTE_DOWN_P;
		var leftP = song ? controls.NOTE_RIGHT_P : controls.NOTE_LEFT_P;

		var upR = song ? controls.NOTE_DOWN_R : controls.NOTE_UP_R;
		var rightR = song ? controls.NOTE_LEFT_R : controls.NOTE_RIGHT_R;
		var downR = song ? controls.NOTE_UP_R : controls.NOTE_DOWN_R;
		var leftR = song ? controls.NOTE_RIGHT_R : controls.NOTE_LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
		var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		if (currentEffect == "up_key")
		{
			controlArray = [upP, upP, upP, upP];
			controlReleaseArray = [upR, upR, upR, upR];
			controlHoldArray = [up, up, up, up];
		}

		var burritoArray:Array<Bool> = [];
		if (Paths.formatToSongPath(SONG.song).contains("insanity-infusion"))
		{
			burritoArray.push(controls.NOTE_MIDDLE_P);
			//burritoArray.push(controls.NOTE_MIDDLE_R);
			burritoArray.push(controls.NOTE_MIDDLE);
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!(leftSide ? dad : boyfriend).stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				var data = daNote.noteData;
				if (Paths.formatToSongPath(SONG.song) == "insanity-infusion" && data > 3)
					data -= infuseCount;
				
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[data] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			var char:Character = (leftSide ? dad : boyfriend);
			if ((controlHoldArray.contains(true) || controlArray.contains(true) || burritoArray.contains(true)) && !endingSong) {
				var canMiss:Bool = !ClientPrefs.ghostTapping;
				if (controlArray.contains(true) || controls.NOTE_MIDDLE_P) {
					for (i in 0...controlArray.length) {
						// heavily based on my own code LOL if it aint broke dont fix it
						var pressNotes:Array<Note> = [];
						var notesDatas:Array<Int> = [];
						var notesStopped:Bool = false;

						var sortedNotesList:Array<Note> = [];
						notes.forEachAlive(function(daNote:Note)
						{
							var data = i;
							if (Paths.formatToSongPath(SONG.song) == "insanity-infusion" && data > 3 && daNote.noteType != "Middle Note")
								data -= infuseCount;
							
							if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate 
							&& !daNote.wasGoodHit && (daNote.noteData == data + infuseCount || daNote.noteType == "Middle Note")) {
								sortedNotesList.push(daNote);
								notesDatas.push(daNote.noteData);
							}
						});
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							for (epicNote in sortedNotesList)
							{
								for (doubleNote in pressNotes) {
									if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10) {
										doubleNote.kill();
										notes.remove(doubleNote, true);
										doubleNote.destroy();
									} else
										notesStopped = true;
								}
									
								var pressed:Bool = false;
								if (epicNote.noteType == "Middle Note")
									pressed = controls.NOTE_MIDDLE_P;
								else
									pressed = controlArray[epicNote.noteData - infuseCount];
								// eee jack detection before was not super good
								if (pressed && !notesStopped) {
									goodNoteHit(epicNote);
									pressNotes.push(epicNote);
								}
							}
						}
						else if (canMiss)
							noteMiss(i);
					}
				}

				#if ACHIEVEMENTS_ALLOWED
				var achieve:Int = checkForAchievement([11]);
				if (achieve > -1) {
					startAchievement(achieve);
				}
				#end
			} 
			else if (char.holdTimer > Conductor.stepCrochet * 0.001 * char.singDuration
				&& char.animation.curAnim.name.startsWith('sing')
				&& !char.animation.curAnim.name.endsWith('miss')
				&& !controlHoldArray.contains(true))
			{
				char.dance();
			}
		}

		(!leftSide ? playerStrums : opponentStrums).forEach(function(spr:StrumNote)
		{
			var data = spr.ID;
			data -= infuseCount;
			//trace(infuseCount);

			if(controlArray[data] && spr.animation.curAnim.name != 'confirm') {
				spr.playAnim('pressed');
				spr.resetAnim = 0;

				if (data < 4)
					holdNotes.members[data].visible = false;
			}
			if(controlReleaseArray[data]) {
				if (data < 4)
					holdNotes.members[data].visible = false;
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		});

		if (Paths.formatToSongPath(SONG.song).contains("insanity-infusion"))
		{
			if (controls.NOTE_MIDDLE_P && burritoStrum.animation.curAnim.name != "confirm")
			{
				burritoStrum.playAnim('pressed');
				burritoStrum.resetAnim = 0;
			}
			if (controls.NOTE_MIDDLE_R)
			{
				burritoStrum.playAnim('static');
				burritoStrum.resetAnim = 0;
			}
		}
	}

	function noteMiss(direction:Int = 1):Void
	{
		var boyfriend = leftSide ? dad : boyfriend;
		if (!boyfriend.stunned)
		{
			health -= (leftSide ? 0.06 : 0.04) * (currentEffect == "miss_triple" ? 3 : 1);
			if (!leftSide)
				combo = 0;

			//if(!practiceMode) songScore--;
			if(!endingSong) {
				songMisses++;
			}
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}
			vocals.volume = 0;
			lc -= lcM;
			lcM -= 0.25;
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			var playerStrums = leftSide ? opponentStrums : playerStrums;
			switch(note.noteType) {
				case 'Hurt Note': //Hurt note
					if(cpuControlled) return;

					if(!boyfriend.stunned)
					{
						noteMiss(note.noteData);
						if(!endingSong)
						{
							--songMisses;
							if(!note.isSustainNote) {
								health -= 0.26; //0.26 + 0.04 = -0.3 (-15%) of HP if you hit a hurt note
							}
							else health -= 0.06; //0.06 + 0.04 = -0.1 (-5%) of HP if you hit a hurt sustain note
	
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
						}

						note.wasGoodHit = true;
						vocals.volume = 0;

						if (!note.isSustainNote)
						{
							note.kill();
							notes.remove(note, true);
							note.destroy();
						}
					}
					return;

				case 'Kitty Note':
					if(cpuControlled) return;
					songScore--;
				
					noteMiss(note.noteData);
					health -= 1 / 3;

					boyfriend.playAnim('hurt', true);
					boyfriend.specialAnim = true;

					playerStrums.members[note.noteData % 4].multAlpha = 0;

					note.wasGoodHit = true;
					vocals.volume = 0;

					if (!note.isSustainNote)
					{
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
					return;
				case 'Middle Note':
					if (currentEffect == "Lag")
					{
						FlxG.maxElapsed = oldElapsed;
						currentEffect = null;
					}
					Note.earlyHitMultMinus -= 0.05;
			}

			var boyfriend = leftSide ? dad : boyfriend;
			if (hpCount > 0)
				hpCount--;

			if (note.noteType != 'Middle Note' && note.noteType != 'Middle Note')
				songScore++;
			if (!note.isSustainNote && note.noteType != 'Middle Note' && !leftSide)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
	
			if (note.noteType != 'Middle Note')
			{
				if (leftSide)
				{
					if (health + healthHurtValue * 1.5 <= 2)
						health += healthHurtValue * 1.5;
					else
						health = 2;
				}
				else
				{
					if (health + note.hitHealth <= 2)
						health += note.hitHealth;
					else
						health = 2;
				}
			}
		
			warmness += 0.5 / (note.isSustainNote ? 2 : 1);
			var daAlt = '';

			var animToPlay:String = '';
			switch (Std.int(Math.abs(note.noteData % 4)))
			{
				case 0:
					animToPlay = 'singLEFT';
				case 1:
					animToPlay = 'singDOWN';
				case 2:
					animToPlay = 'singUP';
				case 3:
					animToPlay = 'singRIGHT';
			}
			if (note.noteType == "Middle Note")
				animToPlay = "singMIDDLE";

			boyfriend.playAnim(animToPlay + daAlt, !note.isSustainNote || leftSide);
			if(note.noteType == 'Hey!') {
				if(boyfriend.animOffsets.exists('hey')) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = 0.6;
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				if (note.noteType != "Middle Note")
					playerStrums.forEach(function(spr:StrumNote)
					{
						if (Math.abs(note.noteData + ((note.isSustainNote && Paths.formatToSongPath(SONG.song) == "insanity-infusion") ? infuseCount : 0)) == spr.ID)
						{
							spr.playAnim('confirm', true);
						}
					});
				else 
					burritoStrum.playAnim('confirm', true);
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			var oldlc = lc;
			if (!note.isSustainNote)
			{
				lc += FlxG.random.float(0.095, 0.125);
				boyfriend.holdTimer = 0;

				note.kill();
				notes.remove(note, true);
				note.destroy();
			} 
			else if(cpuControlled) {
				var targetHold:Float = Conductor.stepCrochet * 0.001 * boyfriend.singDuration;
				if(boyfriend.holdTimer + 0.2 > targetHold) {
					boyfriend.holdTimer = targetHold - 0.2;
				}
			}
			else 
			{
				lc += 0.004;
			}
			if (note.isSustainNote || note.noteLength > 0)
			{
				var sprite = holdNotes.members[note.noteData % 4];
				var strum = (leftSide ? opponentStrums : playerStrums).members[note.noteData % 4];
				if (Paths.formatToSongPath(SONG.song) == "insanity-infusion")
					strum = (leftSide ? opponentStrums : playerStrums).members[note.noteData % 4 + infuseCount];

				sprite.visible = (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) || note.noteLength > 0;
				sprite.animation.play('${note.noteData % 4}');
				sprite.x = strum.x - 22;
				sprite.y = strum.y - 8;

				if (curStage == "resonance")
				{
					sprite.x -= 30;
					sprite.y -= 27;
				}
			}
			else 
				holdNotes.members[note.noteData % 4].visible = false;

			if (FlxG.random.bool(.1))
			{
				lc = oldlc;
				lc += 10;
				trace('ff');
			}
		}

		if (!resynced2)
		{
			resyncVocals();
			resynced2 = true;
		}
	}

	override function destroy() {
		Note.earlyHitMultMinus = 0;
		if (Paths.formatToSongPath(SONG.song) == "ascending-insanity")
			FlxG.autoPause = true;
		if (SONG.song == "nyan")
		{
			FlxG.updateFramerate = 60;
			FlxG.drawFramerate = 60;
		}
		if (curStage == "resonance")
		{
			Note.swagWidth = 160 * 0.7;
			curStage = null;
		}
		if (windowsXP)
		{
			Application.current.window.resizable = true;
		}
		if (oldElapsed != 0)
			FlxG.maxElapsed = oldElapsed;
		if (effectTimer != null && effectTimer.onComplete != null)
		{
			effectTimer.onComplete(effectTimer);
			effectTimer.cancel();
		}

		super.destroy();
	}

	public function cancelFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		var song = false;
		if (song)
		{
			if (curStep % 32 == 0)
			{
				if (SONG.notes[curStep] != null && SONG.notes[curStep].mustHitSection)
				{
					moveCamera(false);
					if (tweenCam == null)
					{
						tweenCam = FlxTween.tween(camHUD, {angle: 180}, 0.8, {ease: FlxEase.expoInOut, onComplete: (twn) -> {
							tweenCam = null;
						}, onUpdate: (twn) -> {
							
						}});
					}
				}
				else if (SONG.notes[curStep] != null && !SONG.notes[curStep].mustHitSection)
				{
					moveCamera(true);
					if (tweenCam2 == null)
					{
						tweenCam2 = FlxTween.tween(camHUD, {angle: 0}, 0.8, {ease: FlxEase.expoInOut, onComplete: (twn) -> {
							tweenCam2 = null;
						}, onUpdate: (twn) -> {
							
						}});
					}
				}
			}
		}
		else
		{
			if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos && !windowsXP && curStage != 'resonance' && curStage != 'earth' && !Paths.formatToSongPath(SONG.song).contains("fireflies-tell-insanity")
				&& Paths.formatToSongPath(SONG.song) != "in-the-end,-it's-all-fine")
			{
				moveCameraSection(Std.int(curStep / 16));
			}
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	var boyfriendHeyed:Bool;
	var infuseCount:Int = 0;
	var infuseTimer:FlxTimer = new FlxTimer();
	override function beatHit()
	{
		super.beatHit();

		if (Paths.formatToSongPath(SONG.song) == "insanity-infusion")
		{
			if (curBeat >= infuseBeats[infuse] && infuseBeats[infuse] != null)
			{
				infuse++;
				infuseCount = infuseCount == 4 ? 0 : 4;
				for (i in (leftSide ? opponentStrums : playerStrums).members)
				{
					i.playAnim("static");
				}
			}
			else if ((curBeat + 16) >= infuseBeats[infuse2] && infuseBeats[infuse2] != null)
			{
				infuse2++;

				infuseTimer.cancel();
				FlxTween.cancelTweensOf(infuseText);
				infuseText.alpha = 1;
				FlxTween.tween(infuseText, {y: (FlxG.height - infuseText.height) / 2}, 1.5, {ease: FlxEase.expoInOut,
				onComplete: (twn) -> {
					infuseTimer.start(1.5, (tmr) -> {
						FlxTween.cancelTweensOf(infuseText);
						FlxTween.tween(infuseText, {y: FlxG.height * 2}, {ease: FlxEase.expoInOut});
					});
				}});
			}
		}

		if(lastBeatHit >= curBeat) {
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (curBeat >= 416 && Paths.formatToSongPath(SONG.song) == "post-insanity" && !boyfriendHeyed)
		{
			boyfriend.playAnim("hey");
			boyfriend.canPlay = false;
			boyfriendHeyed = true;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += FlxG.random.float(0.1, 0.15);
			camHUD.zoom += FlxG.random.float(0.075, 0.2);
		}

		var opponent:Character = dad;
		var boyfriend:Character = boyfriend;

		if (curBeat % 4 == 0)
		{
			if (!opponent.danceIdle
				&& !opponent.curCharacter.startsWith('gf')
				&& !opponent.specialAnim
				&& !opponent.animation.curAnim.name.startsWith('sing'))
				opponent.dance();
		}

		if (curBeat % 2 == 0)
		{
			if (!boyfriend.specialAnim
				&& !boyfriend.curCharacter.startsWith('gf')
				&& !boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.danceIdle)
				boyfriend.dance();
		}

		lastBeatHit = curBeat;
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		var opponentStrums = leftSide ? playerStrums : opponentStrums;
		var playerStrums = leftSide ? this.opponentStrums : this.playerStrums;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	var currentEffect:String = "";
	var currentEffectText:String = "NONE";
	var effectsPulled:Array<Int> = [];
	var effectTimer:FlxTimer;
	var oldElapsed:Float;
	var randomPosX:Int;
	var randomPosY:Int;
	function randomEffect()
	{
		if (effectTimer != null)
		{
			if (effectTimer.onComplete != null)
				effectTimer.onComplete(effectTimer);

			effectTimer.cancel();
		}

		if (currentEffect == "Lag")
		{
			FlxG.maxElapsed = oldElapsed;
		}

		currentEffect = null;
		effectTimer = new FlxTimer();

		var effect = () -> {}
		var random = FlxG.random.int(0, 15, effectsPulled);
		effectsPulled.push(random);
		if (Paths.formatToSongPath(SONG.song) == "please-don't" && effectsPulled.length >= 15)
			effectsPulled = [];

		var oldFullScreen = Application.current.window.fullscreen;
		switch random 
		{
			case 0:
				currentEffect = "stuck_down";
				currentEffectText = "Help My Down Key is Stuck!";
				PlayerSettings.enabledDown = false;
				effect = () -> {
					PlayerSettings.enabledDown = true;
				}
			case 1: 
				currentEffect = "randompos";
				var oldScreenX = Application.current.window.x;
				var oldScreenY = Application.current.window.y;

				randomPosX = FlxG.random.int(20, Std.int(Application.current.window.width / 1.25));
				randomPosY = FlxG.random.int(20, Std.int(Application.current.window.height / 1.25));
				
				currentEffectText = "Randomized Window Position";
				Application.current.window.fullscreen = false;
				effect = () -> {
					Application.current.window.fullscreen = oldFullScreen;
					Application.current.window.x = oldScreenX;
					Application.current.window.y = oldScreenY;

					randomPosX = oldScreenX;
					randomPosY = oldScreenY;
				}
			case 2:
				currentEffect = "no_hit";
				currentEffectText = "Notes are (Almost) Not Hittable!";
			case 3: 
				var oldWidth = Application.current.window.width;
				currentEffectText = "Randomized Width";

				Application.current.window.resizable = false;
				Application.current.window.fullscreen = false;
				Application.current.window.width = FlxG.random.int(20, oldWidth);
				
				effect = () -> {
					Application.current.window.fullscreen = oldFullScreen;
					Application.current.window.width = oldWidth;
					Application.current.window.resizable = true;
				}
			case 4: 
				var oldHeight = Application.current.window.height;
				currentEffectText = "Randomized Height";

				Application.current.window.resizable = false;
				Application.current.window.fullscreen = false;
				Application.current.window.height = FlxG.random.int(20, oldHeight);
				
				effect = () -> {
					Application.current.window.fullscreen = oldFullScreen;
					Application.current.window.height = oldHeight;
					Application.current.window.resizable = true;
				}
			case 5:
				currentEffectText = "HUD is Having a Stroke";
				currentEffect = "hud_angle";

				effect = () -> {
					camHUD.angle = 0;
				}
			case 6:
				currentEffect = "song";
				currentEffectText = "Controls are Reversed";
			case 7:
				currentEffectText = "Fake Crash";
				FakeCrash.crash("Null Object Reference");
			case 8:
				currentEffect = "miss_triple";
				currentEffectText = "Triple The Penalty";
			case 9:
				currentEffectText = "Fake Game Over";
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}

				var timer = (tmr) -> {
					currentEffect = null;
					currentEffectText = "NONE";
					if (effect != null)
						effect();
				}

				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				openSubState(new FakeGameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y, timer));
			case 10:
				currentEffect = "angle_180";
				currentEffectText = "Spinny Game";

				effect = () -> {
					if (camHUD != null && camGame != null)
					{
						camHUD.angle = 0;
						camGame.angle = 0;
					}
				}
			case 11:
				currentEffectText =  "Inverted Colors";
				var matrix:Array<Float> = [
					-1,  0,  0, 0, 255,
					0, -1,  0, 0, 255,
					0,  0, -1, 0, 255,
					0,  0,  0, 1,   0,
				];

				camGame.filters = [new ColorMatrixFilter(matrix)];
				camHUD.filters = [new ColorMatrixFilter(matrix)];
				effect = () -> {
					camHUD.filters = [];
					camGame.filters = [];
				}
			case 12:
				currentEffectText =  "Grayscale";
				var matrix:Array<Float> = [
					0.5, 0.5, 0.5, 0, 0,
					0.5, 0.5, 0.5, 0, 0,
					0.5, 0.5, 0.5, 0, 0,
					  0,   0,   0, 1, 0,
				];

				camGame.filters = [new ColorMatrixFilter(matrix)];
				camHUD.filters = [new ColorMatrixFilter(matrix)];
				effect = () -> {
					camHUD.filters = [];
					camGame.filters = [];
				}
			case 13:
				currentEffectText = currentEffect = "Lag";
				oldElapsed = FlxG.maxElapsed;
				FlxG.maxElapsed = 0.01;

				effect = () -> {
					FlxG.maxElapsed = oldElapsed;
				}
			case 14:
				currentEffect = "spin";
				currentEffectText = "Spinny Notes";
			case 15:
				currentEffect = "up_key";
				currentEffectText = "Help My Up Key Took Over the Game!";
			case _:
		}

		if (random != 9)
			effectTimer.start(16, (tmr) -> {
				currentEffect = null;
				currentEffectText = "NONE";
				if (effect != null)
					effect();
			});
	}

	function set_warmness(value:Float):Float 
	{
		if (value < 0)
			value = 0;
		else if (value > 100)
			value = 100;

		return warmness = value;
	}

	function get_warmnessLevel():String 
	{
		var warmnessLevel:String = "Warm";
		if (warmness <= 25)
			warmnessLevel = "Frozen";
		else if (warmness <= 50)
			warmnessLevel = "Cold";
		else if (warmness <= 75)
			warmnessLevel = "Moderate";

		return warmnessLevel;
	}
}