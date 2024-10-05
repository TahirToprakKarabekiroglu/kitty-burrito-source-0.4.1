package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
#end

import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	#if (haxe >= "4.0.0")
	public static var ignoreModFolders:Map<String, Bool> = new Map();
	public static var customImagesLoaded:Map<String, FlxGraphic> = new Map();
	public static var customSoundsLoaded:Map<String, Sound> = new Map();
	#else
	public static var ignoreModFolders:Map<String, Bool> = new Map<String, Bool>();
	public static var customImagesLoaded:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var customSoundsLoaded:Map<String, Sound> = new Map<String, Sound>();
	#end
	#end

	public static function destroyLoadedImages(ignoreCheck:Bool = false) {
		#if MODS_ALLOWED
		if(!ignoreCheck && ClientPrefs.imagesPersist) return; //If there's 20+ images loaded, do a cleanup just for preventing a crash

		for (key => graphic in customImagesLoaded) {
			graphic.bitmap.dispose();
			graphic.destroy();
		}
		Paths.customImagesLoaded.clear();
		#end
	}

	static public var currentModDirectory:String = null;
	static var currentLevel:String;
	static public function getModFolders()
	{
		#if MODS_ALLOWED
		ignoreModFolders.set('characters', true);
		ignoreModFolders.set('custom_events', true);
		ignoreModFolders.set('custom_notetypes', true);
		ignoreModFolders.set('data', true);
		ignoreModFolders.set('songs', true);
		ignoreModFolders.set('music', true);
		ignoreModFolders.set('sounds', true);
		ignoreModFolders.set('videos', true);
		ignoreModFolders.set('images', true);
		ignoreModFolders.set('stages', true);
		ignoreModFolders.set('weeks', true);
		#end
	}

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType, ?library:Null<String> = null)
	{
		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return getPreloadPath(file);
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var file:String = modsSounds(key);
		if (!FileSystem.exists(file))
			file = getPath('sounds/$key.$SOUND_EXT', SOUND, library);
		if(!customSoundsLoaded.exists(file)) 
			customSoundsLoaded.set(file, Sound.fromFile(file));
		
		return customSoundsLoaded.get(file);
	}
	
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:String = modsMusic(key);
		if (!FileSystem.exists(file))
			file = getPath('music/$key.$SOUND_EXT', SOUND, library);
		if(!customSoundsLoaded.exists(file)) {
			customSoundsLoaded.set(file, Sound.fromFile(file));
		}
		return customSoundsLoaded.get(file);
	}

	inline static public function voices(song:String):Sound
	{
		var file:Sound = returnSongFile(song, "Voices");
		return file;
	}

	inline static public function inst(song:String):Sound
	{
		var s = "Inst";
		if (song == "bgmusic00")
			s = "bgmusic00";
		var file:Sound = returnSongFile(song, s);
		return file;
	}

	static private function returnSongFile(key:String, song:String):Sound
	{
		var file = modsSongs(key.toLowerCase().replace(' ', '-') + "/" + song);
		if(!FileSystem.exists(file)) 
			file = 'assets/songs/${key.toLowerCase().replace(' ', '-')}/$song.$SOUND_EXT';
		if(!customSoundsLoaded.exists(file)) {
			customSoundsLoaded.set(file, Sound.fromFile(file));
		}
		return customSoundsLoaded.get(file);
		
		return null;
	}

	inline static public function image(key:String, ?library:String):Dynamic
	{
		var imageToReturn:FlxGraphic = addCustomGraphic(key);
		return imageToReturn;
	}
	
	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		if (!ignoreMods && FileSystem.exists(mods(key)))
			return File.getContent(mods(key));

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		if (FileSystem.exists(Paths.getPath(key))) 
		{
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		var imageLoaded:FlxGraphic = addCustomGraphic(key);
		return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(getPath('images/$key.xml')));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = addCustomGraphic(key);
		var txtExists:Bool = false;
		if(FileSystem.exists(modsTxt(key))) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		if (path == null)
			return null;
		
		return path.toLowerCase().replace(' ', '-');
	}
	
	#if MODS_ALLOWED
	static public function addCustomGraphic(key:String):FlxGraphic {
		var path = getPath("images/" + key + ".png");
		if(FileSystem.exists(path)) {
			if(!customImagesLoaded.exists(key)) {
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, key, false);
				newGraphic.persist = true;
				customImagesLoaded.set(key, newGraphic);
			}
			return customImagesLoaded.get(key);
		}
		return null;
	}

	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsMusic(key:String) {
		return modFolders('music/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSounds(key:String) {
		return modFolders('sounds/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSongs(key:String) {
		return modFolders('songs/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}
		return 'mods/' + key;
	}
	#end
}
