package;

import animateatlas.AtlasFrameMaker;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key)
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key)
			&& !dumpExclusions.contains(key) && key != null) {
				//trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");

		// Internal caches (text/dir/mod path) are useful for load-time speed.
		// Only clear them when explicitly requested.
		if (cleanUnused) {
			clearTextCache();
			clearDirCache();
			clearExistsCache();
			_clearModFoldersCache();
			clearNestedModsCache();
		}
	}

	static public var currentModDirectory:String = '';
	public static function setCurrentModDirectory(dir:String):Void {
		var next = (dir != null) ? dir : '';
		if (next == currentModDirectory) return;
		currentModDirectory = next;
		// Changing mod root affects path resolution and directory scans.
		_clearModFoldersCache();
		clearNestedModsCache();
		clearExistsCache();
		clearDirCache();
	}

	public static function invalidateModsCaches():Void {
		// Call this after enabling/disabling/reordering mods (modsList.txt changes)
		_clearModFoldersCache();
		clearNestedModsCache();
		clearExistsCache();
		clearDirCache();
		clearTextCache();
	}
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static var _modFoldersCache:Map<String, String> = new Map();
	static inline function _modFoldersCacheKey(key:String):String {
		return (currentModDirectory != null ? currentModDirectory : '') + '|' + key;
	}
	static function _clearModFoldersCache():Void {
		_modFoldersCache = new Map();
	}

	// Nested mod discovery cache (for mods inside other mod folders)
	static var _nestedModNames:Array<String> = null; // entries like "root/sub"
	static var _nestedModsKey:String = '';
	static function clearNestedModsCache():Void {
		_nestedModNames = null;
		_nestedModsKey = '';
	}

	#if MODS_ALLOWED
	static inline function buildNestedModsKey():String {
		var cur = currentModDirectory != null ? currentModDirectory : '';
		var globals = getGlobalMods();
		return cur + '|' + globals.join(',');
	}

	static function ensureNestedModsComputed():Void {
		#if sys
		var key = buildNestedModsKey();
		if (_nestedModNames != null && _nestedModsKey == key) return;
		_nestedModsKey = key;
		var names:Array<String> = [];
		var roots:Array<String> = [];
		if (currentModDirectory != null && currentModDirectory.length > 0) {
			roots.push(currentModDirectory);
		}
		for (mod in getGlobalMods()) roots.push(mod);
		for (root in roots) {
			var basePath = mods(root);
			if (!sysExists(basePath) || !FileSystem.isDirectory(basePath)) continue;
			var entries = cachedReadDirectory(basePath);
			for (sub in entries) {
				var subPath = basePath + '/' + sub;
				if (!FileSystem.isDirectory(subPath)) continue;
				// Treat only valid nested mods (those having a pack.json)
				var packPath = subPath + '/pack.json';
				if (sysExists(packPath)) {
					names.push(root + '/' + sub);
				}
			}
		}
		_nestedModNames = names;
		#else
		_nestedModNames = [];
		#end
	}
	#end

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	// Lightweight content caches (text and directory listings)
	static var _textCache:Map<String, String> = new Map();
	static var _textCacheOrder:Array<String> = [];
	static var _textCacheBytes:Int = 0;
	static var _textCacheMaxBytes:Int = 1024 * 1024; // default 1MB

	public static function setTextCacheMaxKB(kb:Int):Void {
		if (kb < 0) kb = 0;
		_textCacheMaxBytes = kb * 1024;
		// Shrink if necessary
		trimTextCache();
	}

	static function cacheText(path:String, content:String):Void {
		if (_textCacheMaxBytes <= 0) return;
		var size = content.length; // bytes-ish; fine for UTF-8 small files
		// If too big, skip caching
		if (size > _textCacheMaxBytes) return;
		if (_textCache.exists(path)) return; // don't double add
		_textCache.set(path, content);
		_textCacheOrder.push(path);
		_textCacheBytes += size;
		trimTextCache();
	}

	static function trimTextCache():Void {
		if (_textCacheMaxBytes <= 0) {
			clearTextCache();
			return;
		}
		while (_textCacheBytes > _textCacheMaxBytes && _textCacheOrder.length > 0) {
			var oldest = _textCacheOrder.shift();
			var val = _textCache.get(oldest);
			if (val != null) _textCacheBytes -= val.length;
			_textCache.remove(oldest);
		}
		if (_textCacheBytes < 0) _textCacheBytes = 0;
	}

	static function clearTextCache():Void {
		_textCache = new Map();
		_textCacheOrder = [];
		_textCacheBytes = 0;
	}

	#if sys
	static var _dirCacheEnabled:Bool = true;
	static var _dirCache:Map<String, Array<String>> = new Map();
	// File existence cache (speeds up repeated FileSystem.exists checks, especially negatives)
	static var _existsCacheEnabled:Bool = true;
	static var _existsCache:Map<String, Int> = new Map(); // 1=true, 0=false
	static var _existsCacheOrder:Array<String> = [];
	static var _existsCacheMax:Int = 40000;

	public static function setExistsCacheEnabled(enabled:Bool):Void {
		_existsCacheEnabled = enabled;
		if (!enabled) clearExistsCache();
	}

	public static function clearExistsCache():Void {
		_existsCache = new Map();
		_existsCacheOrder = [];
	}

	static inline function _putExistsCache(path:String, exists:Bool):Void {
		if (!_existsCacheEnabled) return;
		if (_existsCache.exists(path)) return;
		_existsCache.set(path, exists ? 1 : 0);
		_existsCacheOrder.push(path);
		while (_existsCacheOrder.length > _existsCacheMax) {
			var oldest = _existsCacheOrder.shift();
			_existsCache.remove(oldest);
		}
	}

	public static function sysExists(path:String):Bool {
		if (!_existsCacheEnabled) {
			return FileSystem.exists(path);
		}
		var cached = _existsCache.get(path);
		if (cached != null) return cached == 1;
		var exists = false;
		try {
			exists = FileSystem.exists(path);
		} catch (_:Dynamic) {}
		_putExistsCache(path, exists);
		return exists;
	}

	public static function setDirCacheEnabled(enabled:Bool):Void {
		_dirCacheEnabled = enabled;
		if (!enabled) clearDirCache();
	}
	static function clearDirCache():Void {
		_dirCache = new Map();
	}
	public static function cachedReadDirectory(path:String):Array<String> {
		if (!_dirCacheEnabled) {
			return FileSystem.readDirectory(path);
		}
		var cached = _dirCache.get(path);
		if (cached != null) return cached;
		var list = FileSystem.readDirectory(path);
		_dirCache.set(path, list);
		return list;
	}
	#else
	static inline function clearDirCache():Void {}
	public static inline function setDirCacheEnabled(enabled:Bool):Void {}
	public static inline function cachedReadDirectory(path:String):Array<String> { return []; }
	public static inline function setExistsCacheEnabled(enabled:Bool):Void {}
	public static inline function clearExistsCache():Void {}
	public static inline function sysExists(path:String):Bool { return false; }
	#end

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
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

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(sysExists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}

	inline static public function image(key:String, ?library:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key, library);
		return returnAsset;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && sysExists(modFolders(key))) {
			var p = modFolders(key);
			var cached = _textCache.get(p);
			if (cached != null) return cached;
			var txt = File.getContent(p);
			cacheText(p, txt);
			return txt;
		}
		#end

		if (sysExists(getPreloadPath(key))) {
			var p = getPreloadPath(key);
			var cached = _textCache.get(p);
			if (cached != null) return cached;
			var txt = File.getContent(p);
			cacheText(p, txt);
			return txt;
		}

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (sysExists(levelPath)) {
					var cached = _textCache.get(levelPath);
					if (cached != null) return cached;
					var txt = File.getContent(levelPath);
					cacheText(levelPath, txt);
					return txt;
				}
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (sysExists(levelPath)) {
				var cached = _textCache.get(levelPath);
				if (cached != null) return cached;
				var txt = File.getContent(levelPath);
				cacheText(levelPath, txt);
				return txt;
			}
		}
		#end
		var apath = getPath(key, TEXT);
		var cached = _textCache.get(apath);
		if (cached != null) return cached;
		var txt = Assets.getText(apath);
		cacheText(apath, txt);
		return txt;
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(sysExists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if(sysExists(mods(currentModDirectory + '/' + key)) || sysExists(mods(key))) {
			return true;
		}
		#end

		if(OpenFlAssets.exists(getPath(key, type))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;
		if(sysExists(modsXml(key))) {
			xmlExists = true;
		}

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}


	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = false;
		if(sysExists(modsTxt(key))) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String) {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if(sysExists(modKey)) {
			if(!currentTrackedAssets.exists(modKey)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);
				newGraphic.persist = _persistGraphics;
				currentTrackedAssets.set(modKey, newGraphic);
			}
			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		//trace(path);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = _persistGraphics;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no its returning null NOOOO');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(sysExists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			// Track by resolved file path so clearUnusedMemory/clearStoredMemory won't immediately evict it.
			localTrackedAssets.push(file);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
		#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		#else
		{
			var folder:String = '';
			if(path == 'songs') folder = 'songs:';

			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		#end
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

		// Toggle whether loaded graphics should persist in cache (GPU/bitmap)
		static var _persistGraphics:Bool = true;
		public static function setPersistGraphics(persist:Bool):Void {
			_persistGraphics = persist;
			// Already-cached graphics keep their flags; new loads will respect this.
		}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
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

	/* Goes unused for now

	inline static public function modsShaderFragment(key:String, ?library:String)
	{
		return modFolders('shaders/'+key+'.frag');
	}
	inline static public function modsShaderVertex(key:String, ?library:String)
	{
		return modFolders('shaders/'+key+'.vert');
	}
	inline static public function modsAchievements(key:String) {
		return modFolders('achievements/' + key + '.json');
	}*/

	static public function modFolders(key:String) {
		var cacheKey = _modFoldersCacheKey(key);
		var cached = _modFoldersCache.get(cacheKey);
		if (cached != null) return cached;

		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(sysExists(fileToCheck)) {
				_modFoldersCache.set(cacheKey, fileToCheck);
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(sysExists(fileToCheck)) {
				_modFoldersCache.set(cacheKey, fileToCheck);
				return fileToCheck;
			}
		}

		// Search nested mod folders one level deep (e.g., mods/Pack/SubMod/...)
		#if MODS_ALLOWED
		ensureNestedModsComputed();
		for (nested in (_nestedModNames == null ? [] : _nestedModNames)) {
			var nestedCheck = mods(nested + '/' + key);
			if (sysExists(nestedCheck)) {
				_modFoldersCache.set(cacheKey, nestedCheck);
				return nestedCheck;
			}
		}
		#end
		var def = 'mods/' + key;
		_modFoldersCache.set(cacheKey, def);
		return def;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		// modsList.txt and pack.json checks must reflect current disk state
		clearExistsCache();
		clearDirCache();
		_clearModFoldersCache();
		clearNestedModsCache();
		var path:String = 'modsList.txt';
		if(sysExists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(sysExists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(sysExists(modsFolder)) {
			// Use cached directory listing for performance on sys targets
			var entries:Array<String> = #if sys cachedReadDirectory(modsFolder) #else FileSystem.readDirectory(modsFolder) #end;
			for (folder in entries) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
