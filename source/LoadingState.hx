package;

import lime.app.Promise;
import lime.app.Future;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import haxe.io.Path;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
using StringTools;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 1.0;
	
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	function new(target:FlxState, stopMusic:Bool, directory:String)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	var funkay:FlxSprite;
	var loadBar:FlxSprite;
	override function create()
	{
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d);
		add(bg);
		funkay = new FlxSprite(0, 0).loadGraphic(Paths.getPath('images/funkay.png', IMAGE));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.antialiasing = ClientPrefs.globalAntialiasing;
		add(funkay);
		funkay.scrollFactor.set();
		funkay.screenCenter();

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xffff16d2);
		loadBar.screenCenter(X);
		loadBar.antialiasing = ClientPrefs.globalAntialiasing;
		add(loadBar);
		
		initSongsManifest().onComplete
		(
			function (lib)
			{
				callbacks = new MultiCallback(onLoad);
				var introComplete = callbacks.add("introComplete");
				/*if (PlayState.SONG != null) {
					checkLoadSong(getSongPath());
					if (PlayState.SONG.needsVoices)
						checkLoadSong(getVocalPath());
				}*/
				checkLibrary("shared");
				if(directory != null && directory.length > 0 && directory != 'shared') {
					checkLibrary(directory);
				}
				prewarmCoreGraphics();
				prefetchSongAssets();
				prewarmModsDiskCacheBackground();

				var fadeTime = 0.5;
				FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
				new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
			}
		);
	}

	function prewarmModsDiskCacheBackground():Void
	{
		#if sys
		#if MODS_ALLOWED
		try {
			if (!FileSystem.exists('mods') || FileSystem.isDirectory('mods') == false) return;
		} catch (_:Dynamic) {
			return;
		}

		final maxFiles:Int = 1500;
		final maxBytes:Int = 128 * 1024 * 1024;
		final roots:Array<String> = [
			'mods/stages',
			'mods/scripts',
			'mods/custom_events',
			'mods/custom_notetypes',
			'mods/data',
			'mods/images',
			'mods/videos',
			'mods/sounds',
			'mods/music',
			'mods/songs',
			'mods/shaders',
			'mods/fonts',
			'mods/characters',
			'mods/weeks',
			'mods'
		];

		sys.thread.Thread.create(function() {
			var warmedFiles:Int = 0;
			var warmedBytes:Int = 0;
			var seen:Map<String, Bool> = new Map();

			var shouldSkipDir = function(p:String):Bool {
				if (p == null) return true;
				var lp = p.toLowerCase();
				return lp.indexOf('/.git') != -1 || lp.indexOf('\\.git') != -1 || lp.indexOf('/.svn') != -1 || lp.indexOf('\\.svn') != -1;
			};

			var readHead = function(filePath:String, bytes:Int):Void {
				if (warmedFiles >= maxFiles || warmedBytes >= maxBytes) return;
				if (filePath == null || filePath.length < 1) return;
				if (seen.exists(filePath)) return;
				seen.set(filePath, true);
				try {
					if (!FileSystem.exists(filePath) || FileSystem.isDirectory(filePath)) return;
					var f = sys.io.File.read(filePath, true);
					var toRead = bytes;
					if (toRead < 1024) toRead = 1024;
					var _ = f.read(toRead);
					f.close();
					warmedFiles++;
					warmedBytes += toRead;
				} catch (_:Dynamic) {}
			};

			var bytesForExt = function(ext:String):Int {
				ext = (ext == null) ? '' : ext.toLowerCase();
				switch (ext) {
					case 'lua': return 8 * 1024;
					case 'json', 'xml', 'txt': return 8 * 1024;
					case 'png', 'jpg', 'jpeg', 'gif', 'webp': return 64 * 1024;
					case 'ogg', 'mp3', 'wav': return 64 * 1024;
					case 'mp4', 'webm', 'mov', 'avi': return 256 * 1024;
					case 'frag', 'vert', 'glsl': return 8 * 1024;
					default: return 0;
				}
			};

			var walk = null;
			walk = function(dir:String):Void {
				if (warmedFiles >= maxFiles || warmedBytes >= maxBytes) return;
				if (dir == null || dir.length < 1) return;
				if (shouldSkipDir(dir)) return;
				try {
					if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return;
					for (name in FileSystem.readDirectory(dir)) {
						if (warmedFiles >= maxFiles || warmedBytes >= maxBytes) return;
						var p = dir + '/' + name;
						try {
							if (FileSystem.isDirectory(p)) {
								if (!shouldSkipDir(p)) walk(p);
							} else {
								var ext = haxe.io.Path.extension(p);
								var b = bytesForExt(ext);
								if (b > 0) readHead(p, b);
							}
						} catch (_:Dynamic) {}
					}
				} catch (_:Dynamic) {}
			};

			for (r in roots) {
				if (warmedFiles >= maxFiles || warmedBytes >= maxBytes) break;
				walk(r);
			}
		});
		#end
		#end
	}

	function prewarmCoreGraphics():Void
	{
		if (!PlayState.gpuCahchingEnabled) return;
		var toCache:Array<{path:String, library:Null<String>}> = [
			{path: 'NOTE_assets', library: null},
			{path: 'combo', library: null},
			{path: 'sick', library: null},
			{path: 'good', library: null},
			{path: 'bad', library: null},
			{path: 'shit', library: null},
			{path: 'noteSplashes', library: null},
			{path: 'healthBar', library: 'shared'},
			{path: 'timeBar', library: 'shared'}
		];
		for (i in 0...10) toCache.push({path: 'num' + i, library: null});
		if (ClientPrefs.prewarmStageAssets && PlayState.SONG != null && PlayState.SONG.stage != null && PlayState.SONG.stage.length > 0) {
			var stage = PlayState.SONG.stage;
			var lowQ = ClientPrefs.lowQuality;
			switch (stage)
			{
				case 'stage':
					toCache.push({path: 'stageback', library: null});
					toCache.push({path: 'stagefront', library: null});
					if (!lowQ) {
						toCache.push({path: 'stage_light', library: null});
						toCache.push({path: 'stagecurtains', library: null});
					}
				default:
					// Unknown/custom stage: no explicit list. PlayState will load what it needs.
			}
		}
		for (asset in toCache) {
			var graphic = Paths.returnGraphic(asset.path, asset.library);
			if (graphic != null && FlxG.bitmap.get(graphic.key) == null) {
				FlxG.bitmap.add(graphic);
			}
		}
	}

	function prefetchSongAssets():Void
	{
		// Lightweight, safe prefetching while we are on the loading screen
		if (PlayState.SONG == null) return;
		var addStep = function(id:String, fn:Void->Void) {
			var cb = callbacks.add('prefetch:' + id);
			try {
				fn();
			} catch (e:Dynamic) {
				trace('prefetch ' + id + ' failed: ' + e);
			}
			cb();
		};

		// 1) Prime events.json parsed cache (if present)
		addStep('events', function() {
			var songName = Paths.formatToSongPath(PlayState.SONG.song);
			try {
				// Parsing will populate Song._parsedCache; ignore if missing
				Song.loadFromJson('events', songName);
			} catch (e:Dynamic) {}
		});

		// Prime dialogue.json text if present (Paths text cache)
		addStep('dialogue', function() {
			var songName = Paths.formatToSongPath(PlayState.SONG.song);
			var filePath = 'data/' + songName + '/dialogue.json';
			try { Paths.getTextFromFile(filePath); } catch (_:Dynamic) {}
		});

		addStep('lua-scripts', function() {
			#if sys
			var list:Array<String> = [];
			var songName = Paths.formatToSongPath(PlayState.SONG.song);
			// Keep this lightweight: only prefetch what this song is most likely to need.
			if (PlayState.SONG.stage != null && PlayState.SONG.stage.length > 0) {
				var stagePath = 'mods/stages/' + PlayState.SONG.stage + '.lua';
				if (FileSystem.exists(stagePath)) list.push(stagePath);
				// Also check built-in stage script (assets/stages/*.lua)
				var baseStagePath = Paths.getPreloadPath('stages/' + PlayState.SONG.stage + '.lua');
				if (FileSystem.exists(baseStagePath)) list.push(baseStagePath);
			}
			list = list.concat(util.FSUtil.listFilesWithExt('mods/data/' + songName, 'lua'));
			// Also check built-in song script dir (assets/data/<song>/*.lua)
			list = list.concat(util.FSUtil.listFilesWithExt(Paths.getPreloadPath('data/' + songName), 'lua'));
			if (list.length > 0) {
				try { util.ScriptCache.preload(list); } catch (_:Dynamic) {}
				try { util.LuaPool.prewarm(list.length); } catch (_:Dynamic) {}

				// Best-effort: warm assets referenced by these scripts without executing Lua.
				// This helps Lua-driven stages/sprites avoid first-frame disk IO + decode hitches.
				var warmed:Map<String, Bool> = new Map();
				var warmedCount:Int = 0;
				var maxWarm:Int = 250;

				var warmFileHead = function(path:String):Void {
					try {
						var f = sys.io.File.read(path, true);
						var _ = f.read(65536);
						f.close();
					} catch (_:Dynamic) {}
				};

				var warmFirstExisting = function(paths:Array<String>):Bool {
					if (paths == null) return false;
					for (p in paths) {
						if (p == null || p.length < 1) continue;
						try {
							if (FileSystem.exists(p) && !FileSystem.isDirectory(p)) {
								warmFileHead(p);
								return true;
							}
						} catch (_:Dynamic) {}
					}
					return false;
				};

				var normImageKey = function(k:String):String {
					if (k == null) return null;
					k = k.trim();
					if (k.length < 1) return null;
					// Strip common prefixes/extensions used by some mods
					if (k.startsWith('assets/images/')) k = k.substr('assets/images/'.length);
					if (k.startsWith('images/')) k = k.substr('images/'.length);
					if (k.toLowerCase().endsWith('.png')) k = k.substr(0, k.length - 4);
					return k;
				};

				var normSoundKey = function(k:String):String {
					if (k == null) return null;
					k = k.trim();
					if (k.length < 1) return null;
					if (k.startsWith('assets/sounds/')) k = k.substr('assets/sounds/'.length);
					if (k.startsWith('sounds/')) k = k.substr('sounds/'.length);
					var lower = k.toLowerCase();
					for (ext in ['.ogg', '.mp3', '.wav']) {
						if (lower.endsWith(ext)) {
							k = k.substr(0, k.length - ext.length);
							break;
						}
					}
					return k;
				};

				var normMusicKey = function(k:String):String {
					if (k == null) return null;
					k = k.trim();
					if (k.length < 1) return null;
					if (k.startsWith('assets/music/')) k = k.substr('assets/music/'.length);
					if (k.startsWith('music/')) k = k.substr('music/'.length);
					var lower = k.toLowerCase();
					for (ext in ['.ogg', '.mp3', '.wav']) {
						if (lower.endsWith(ext)) {
							k = k.substr(0, k.length - ext.length);
							break;
						}
					}
					return k;
				};

				var warmKeyOnce = function(prefix:String, raw:String, fn:String->Void) {
					if (warmedCount >= maxWarm) return;
					var key = raw;
					if (key == null || key.length < 1) return;
					var id = prefix + ':' + key;
					if (warmed.exists(id)) return;
					warmed.set(id, true);
					fn(key);
					warmedCount++;
				};

				var warmImage = function(raw:String) {
					var k = normImageKey(raw);
					if (k == null) return;
					warmKeyOnce('img', k, function(imgKey:String) {
						// Low-memory mode: only warm disk cache by reading file head.
						if (!ClientPrefs.gpuPrecache) {
							var candidates:Array<String> = [];
							#if MODS_ALLOWED
							try {
								var mp = Paths.modFolders('images/' + imgKey + '.png');
								if (mp != null) candidates.push(mp);
							} catch (_:Dynamic) {}
							#end
							candidates.push(Paths.getPreloadPath('images/' + imgKey + '.png'));
							candidates.push(Paths.getPreloadPath('shared/images/' + imgKey + '.png'));
							warmFirstExisting(candidates);
							return;
						}

						// Performance mode: decode + cache (may use more memory)
						var graphic = Paths.returnGraphic(imgKey);
						if (graphic != null && PlayState.gpuCahchingEnabled && FlxG.bitmap.get(graphic.key) == null) {
							FlxG.bitmap.add(graphic);
						}
					});
				};

				var warmSound = function(raw:String) {
					var k = normSoundKey(raw);
					if (k == null) return;
					warmKeyOnce('snd', k, function(sndKey:String) {
						if (!ClientPrefs.gpuPrecache) {
							var candidates:Array<String> = [];
							#if MODS_ALLOWED
							try {
								var mp = Paths.modFolders('sounds/' + sndKey + '.' + Paths.SOUND_EXT);
								if (mp != null) candidates.push(mp);
							} catch (_:Dynamic) {}
							#end
							candidates.push(Paths.getPreloadPath('sounds/' + sndKey + '.' + Paths.SOUND_EXT));
							candidates.push(Paths.getPreloadPath('shared/sounds/' + sndKey + '.' + Paths.SOUND_EXT));
							// Also try common alt extensions, in case mod uses mp3/wav
							for (ext in ['ogg','mp3','wav']) {
								#if MODS_ALLOWED
								try {
									var mp2 = Paths.modFolders('sounds/' + sndKey + '.' + ext);
									if (mp2 != null) candidates.push(mp2);
								} catch (_:Dynamic) {}
								#end
								candidates.push(Paths.getPreloadPath('sounds/' + sndKey + '.' + ext));
								candidates.push(Paths.getPreloadPath('shared/sounds/' + sndKey + '.' + ext));
							}
							warmFirstExisting(candidates);
							return;
						}
						Paths.sound(sndKey);
					});
				};

				var warmMusic = function(raw:String) {
					var k = normMusicKey(raw);
					if (k == null) return;
					warmKeyOnce('msc', k, function(mscKey:String) {
						if (!ClientPrefs.gpuPrecache) {
							var candidates:Array<String> = [];
							#if MODS_ALLOWED
							try {
								var mp = Paths.modFolders('music/' + mscKey + '.' + Paths.SOUND_EXT);
								if (mp != null) candidates.push(mp);
							} catch (_:Dynamic) {}
							#end
							candidates.push(Paths.getPreloadPath('music/' + mscKey + '.' + Paths.SOUND_EXT));
							candidates.push(Paths.getPreloadPath('shared/music/' + mscKey + '.' + Paths.SOUND_EXT));
							for (ext in ['ogg','mp3','wav']) {
								#if MODS_ALLOWED
								try {
									var mp2 = Paths.modFolders('music/' + mscKey + '.' + ext);
									if (mp2 != null) candidates.push(mp2);
								} catch (_:Dynamic) {}
								#end
								candidates.push(Paths.getPreloadPath('music/' + mscKey + '.' + ext));
								candidates.push(Paths.getPreloadPath('shared/music/' + mscKey + '.' + ext));
							}
							warmFirstExisting(candidates);
							return;
						}
						Paths.music(mscKey);
					});
				};

				var scan = function(re:EReg, s:String, cb:String->Void) {
					var pos = 0;
					while (warmedCount < maxWarm && s != null && re.matchSub(s, pos)) {
						var m = re.matched(1);
						if (m != null && m.length > 0) cb(m);
						var mp = re.matchedPos();
						pos = mp.pos + mp.len;
					}
				};

				var rePreImg:EReg = ~/precacheImage\\s*\\(\\s*['"]([^'"]+)['"]\\s*\\)/;
				var rePreSnd:EReg = ~/precacheSound\\s*\\(\\s*['"]([^'"]+)['"]\\s*\\)/;
				var rePreMsc:EReg = ~/precacheMusic\\s*\\(\\s*['"]([^'"]+)['"]\\s*\\)/;
				var reMakeSpr:EReg = ~/makeLuaSprite\\s*\\(\\s*['"][^'"]+['"]\\s*,\\s*['"]([^'"]+)['"]/;
				var reMakeAnim:EReg = ~/makeAnimatedLuaSprite\\s*\\(\\s*['"][^'"]+['"]\\s*,\\s*['"]([^'"]+)['"]/;
				var reLoadFrames:EReg = ~/loadFrames\\s*\\(\\s*[^,]+,\\s*['"]([^'"]+)['"]/;

				for (p in list)
				{
					var txt:String = null;
					try {
						txt = util.ScriptCache.get(p);
						if (txt == null) txt = File.getContent(p);
					} catch (_:Dynamic) {}
					if (txt == null || txt.length < 1) continue;
					scan(rePreImg, txt, warmImage);
					scan(reMakeSpr, txt, warmImage);
					scan(reMakeAnim, txt, warmImage);
					scan(reLoadFrames, txt, warmImage);
					scan(rePreSnd, txt, warmSound);
					scan(rePreMsc, txt, warmMusic);
					if (warmedCount >= maxWarm) break;
				}
			}
			#end
		});

		// Preload Inst/Voices; optionally gate countdown until done
		if (ClientPrefs.waitAudioPreload) {
			addStep('audio', function() {
				try {
					Paths.inst(PlayState.SONG.song);
					if (PlayState.SONG.needsVoices) Paths.voices(PlayState.SONG.song);
				} catch (e:Dynamic) {
					trace('prefetch audio failed: ' + e);
				}
			});
		} else {
			#if sys
			sys.thread.Thread.create(function() {
				try {
					Paths.inst(PlayState.SONG.song);
					if (PlayState.SONG.needsVoices) Paths.voices(PlayState.SONG.song);
				} catch (_:Dynamic) {}
			});
			#end
		}
	}
	
	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			// @:privateAccess
			// library.types.set(symbolPath, SOUND);
			// @:privateAccess
			// library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
			var callback = callbacks.add("song:" + path);
			Assets.loadSound(path).onComplete(function (_) { callback(); });
		}
	}
	
	function checkLibrary(library:String) {
		trace(Assets.hasLibrary(library));
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function (_) { callback(); });
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		funkay.setGraphicSize(Std.int(0.88 * FlxG.width + 0.9 * (funkay.width - 0.88 * FlxG.width)));
		funkay.updateHitbox();
		if(controls.ACCEPT)
		{
			funkay.setGraphicSize(Std.int(funkay.width + 60));
			funkay.updateHitbox();
		}

		if(callbacks != null) {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
		}
	}
	
	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		MusicBeatState.switchState(target);
	}
	
	static function getSongPath()
	{
		return Paths.inst(PlayState.SONG.song);
	}
	
	static function getVocalPath()
	{
		return Paths.voices(PlayState.SONG.song);
	}
	
	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) && isLibraryLoaded("shared") && isLibraryLoaded(directory);
		}
		
		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		return target;
	}
	
	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool
	{
		return Assets.cache.hasSound(path);
	}
	
	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}
	#end
	
	override function destroy()
	{
		super.destroy();
		
		callbacks = null;
	}
	
	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new (callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function ()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
			trace('$logId: $msg');
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}