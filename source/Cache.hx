#if sys
package;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import lime.app.Application;
#if windows
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Cache extends MusicBeatState
{
	public static var bitmapData:Map<String,FlxGraphic>;
	public static var bitmapData2:Map<String,FlxGraphic>;

	var queueImages:Array<String> = [];
	var queueSongs:Array<String> = [];
	var queueVideos:Array<String> = [];

	var shitz:FlxText;
	var total:Int = 0;
	var processed:Int = 0;
	var started:Bool = false;

	override function create()
	{
		FlxG.mouse.visible = false;
	FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

	// Ensure input/player settings exist before we load prefs (reloadControls needs this)
	PlayerSettings.init();
	// Ensure we can read user preferences to decide whether to actually preload
		FlxG.save.bind('funkin', 'haryulovescat');
		ClientPrefs.loadPrefs();

		// Always initialize maps to prevent null-access crashes even when preloading is skipped
		bitmapData = new Map<String,FlxGraphic>();
		bitmapData2 = new Map<String,FlxGraphic>();

		// If boot-time preload is disabled, hand off immediately to TitleState
		if (!ClientPrefs.bootPreloadAtBoot)
		{
			super.create();
			MusicBeatState.switchState(new TitleState());
			return;
		}

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('loadingBG'));
		menuBG.screenCenter();
		menuBG.antialiasing = ClientPrefs.globalAntialiasing;
		menuBG.scale.set(1.0, 1.0);
		add(menuBG);

	shitz = new FlxText(60, 12, FlxG.width - 70, "Preparing boot preload...", 12);
	shitz.scrollFactor.set(0, 0);
		shitz.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
		shitz.alignment = RIGHT;
		untyped shitz.borderStyle = FlxTextBorderStyle.OUTLINE;
		untyped shitz.borderColor = FlxColor.BLACK;
		add(shitz);

		// Build work queues on main thread
		buildQueues();
		total = queueImages.length + (queueSongs.length * 2) + queueVideos.length;
		started = true;
		shitz.text = 'Preloading 0/' + total + '...';

		// Processing happens in update() to keep UI responsive

		super.create();
	}

	override function update(elapsed)
	{
		if (started)
		{
			var perFrame = 6; // do a few items per frame
			while (perFrame-- > 0 && processNext()) {}
			shitz.text = 'Preloading ' + processed + '/' + total + '...';
			if (processed >= total)
			{
				started = false;
				MusicBeatState.switchState(new TitleState());
			}
		}
		super.update(elapsed);
	}

	function buildQueues():Void
	{
		#if cpp
		// Images
		enqueuePngsIfDirExists('assets/shared/images/characters');
		enqueuePngsIfDirExists('assets/images');
		enqueuePngsIfDirExists('mods/images');
		enqueuePngsIfDirExists('mods/characters');

		// Songs (folder names)
		enqueueSongsIfDirExists('assets/songs');
		enqueueSongsIfDirExists('mods/songs');

		// Videos (warm headers only)
		if (ClientPrefs.bootPreloadVideos)
		{
			enqueueVideosIfDirExists('assets/videos');
			enqueueVideosIfDirExists('mods/videos');
		}
		#end
	}

	inline function enqueuePngsIfDirExists(dir:String)
	{
		try {
			if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return;
			for (i in FileSystem.readDirectory(dir))
			{
				if (i.toLowerCase().endsWith('.png'))
					queueImages.push(dir + '/' + i);
			}
		} catch (e:Dynamic) {}
	}

	inline function enqueueSongsIfDirExists(dir:String)
	{
		try {
			if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return;
			for (i in FileSystem.readDirectory(dir))
			{
				var full = dir + '/' + i;
				if (FileSystem.isDirectory(full))
					queueSongs.push(i); // song key (folder name)
			}
		} catch (e:Dynamic) {}
	}

	inline function enqueueVideosIfDirExists(dir:String)
	{
		try {
			if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return;
			for (i in FileSystem.readDirectory(dir))
			{
				var lower = i.toLowerCase();
				if (lower.endsWith('.mp4') || lower.endsWith('.webm') || lower.endsWith('.mkv') || lower.endsWith('.mov'))
					queueVideos.push(dir + '/' + i);
			}
		} catch (e:Dynamic) {}
	}

	// Processes one work item; returns true if any item was processed
	function processNext():Bool
	{
		// Prioritize images -> audio -> videos
		if (queueImages.length > 0)
		{
			var path = queueImages.shift();
			try {
				var data:BitmapData = BitmapData.fromFile(path);
				var graph = FlxGraphic.fromBitmapData(data);
				graph.persist = ClientPrefs.gpuPrecache;
				graph.destroyOnNoUse = !ClientPrefs.gpuPrecache;
			} catch (e:Dynamic) {
				// Ignore file-specific errors
			}
			processed++;
			return true;
		}
		else if (queueSongs.length > 0)
		{
			var song = queueSongs.shift();
			// Warm Inst/Voices by trying common extensions and reading a small header
			warmAudioHeader(song, true);
			warmAudioHeader(song, false);
			processed += 2;
			return true;
		}
		else if (queueVideos.length > 0)
		{
			var v = queueVideos.shift();
			warmFileHead(v);
			processed++;
			return true;
		}
		return false;
	}

	function warmAudioHeader(song:String, isInst:Bool)
	{
		#if cpp
		var bases = [
			'mods/songs/' + song + '/' + (isInst ? 'Inst' : 'Voices'),
			'assets/songs/' + song + '/' + (isInst ? 'Inst' : 'Voices')
		];
		var exts = ['.ogg', '.mp3', '.wav'];
		for (b in bases)
		{
			for (e in exts)
			{
				var p = b + e;
				if (FileSystem.exists(p) && !FileSystem.isDirectory(p))
				{
					warmFileHead(p);
					return;
				}
			}
		}
		#end
	}

	function warmFileHead(path:String)
	{
		#if cpp
		try {
			var f = sys.io.File.read(path, true);
			// Read first 64KB to let OS cache fetch inode + some data
			var _ = f.read(65536);
			f.close();
		} catch (e:Dynamic) {}
		#end
	}
}
#end