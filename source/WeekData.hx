package;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Array<Dynamic>>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';
	
	// JSON variables
	public var songs:Array<Array<Dynamic>>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hideStoryMode: false,
			hideFreeplay: false
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile) {
		songs = weekFile.songs;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		storyName = weekFile.storyName;
		weekName = weekFile.weekName;
		freeplayColor = weekFile.freeplayColor;
		startUnlocked = weekFile.startUnlocked;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();

		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		if(FileSystem.exists(Paths.mods())) {
			for (folder in FileSystem.readDirectory(Paths.mods())) {
				var path = haxe.io.Path.join([Paths.mods(), folder]);
				if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.exists(folder)) {
					directories.push(path + '/');
					//trace('pushed Directory: ' + folder);
				}
			}
		}

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if(week != null) {
						var weekFile:WeekData = new WeekData(week);
						if(j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}

						if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'weeks/';
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var weekToCheck:String = file.substr(0, file.length - 5);
						if(!weeksLoaded.exists(weekToCheck)) {
							var week:WeekFile = getWeekFile(path);
							if(week != null) {
								var weekFile:WeekData = new WeekData(week);
								if(i >= originalLength) {
									weekFile.folder = directories[i].substring(Paths.mods().length, directories[i].length-1);
								}

								if((isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)) {
									weeksLoaded.set(weekToCheck, weekFile);
									weeksList.push(weekToCheck);
								}
							}
						}
					}
				}
			}
		}
		#end

		weeksList.push("kitten");

		var songs:Array<Array<Dynamic>> = [
			["Beginning of a New Insanity", "burito", [127, 82, 50]],
			["Kitty's Insanity", "burito", [127, 82, 50]],
			["Post Insanity", "burito", [127, 82, 50]]
		];
		var weekFile:WeekFile = {
			songs: songs,
			weekCharacters: ['', '', ''],
			weekBackground: '',
			weekBefore: '',
			storyName: 'Kitty Burrito',
			weekName: 'Kitty Burrito',
			freeplayColor: null,
			startUnlocked: true,
			hideStoryMode: false,
			hideFreeplay: false
		};
		weeksLoaded.set("kitten", new WeekData(weekFile));
		if (!isStoryMode)
			setKittenExtra();
	}

	public static function setKittenExtra()
	{
		if (FlxG.save.data.finishedStory)
		{
			var song:Array<Array<Dynamic>> = [
				["Insanity", "burito", [255, 255, 255]],
				["Sanity", "burito", [127, 82, 50]],
				["In the End, It's All Fine", "burito", [255, 255, 255]],
				["Warmth Without Insanity", "burito", [255, 255, 255]],
				["Insanity Infusion", "burito", [255, 255, 255]],
				["Insanity Likes Your Face", "burito", [255, 255, 255]],
				["Boys With Insanity", "bf", [255, 255, 255]],
				["Adequate Insanity", "burito", [255, 255, 255]],
				["Insanity On Earth", "burito", [255, 255, 255]],
				["We're Landing At Last", "burito", [255, 255, 255]],
				["CATS!!", "burito", [255, 255, 255]],
			];
			if (FlxG.save.data.finishedFirstSong && FlxG.save.data.finishedSecondSong && FlxG.save.data.finishedThirdSong)
			{
				song.push(["title.wma", "", [177, 255, 0]]);
				song.push(["bgmusic00", "", [255, 255, 255]]);
				song.push(["nyan", "", [255, 255, 255]]);
				song.push(["Unholy Insanity Resonance", "", [255, 255, 255]]);
				song.push(["Fireflies Tell Insanity", "", [3, 158, 240]]);
				song.push(["Hold Your Insanity", "", [51, 107, 104]]);
				song.push(["Higher", "", [255, 255, 255]]);
			}

			var weekFile:WeekFile = {
				songs: song,
				weekCharacters: ['', '', ''],
				weekBackground: '',
				weekBefore: '',
				storyName: '',
				weekName: '',
				freeplayColor: null,
				startUnlocked: true,
				hideStoryMode: true,
				hideFreeplay: false
			};

			weeksList.push("kittenextra");
			weeksLoaded.set("kittenextra", new WeekData(weekFile));
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Paths.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}
}