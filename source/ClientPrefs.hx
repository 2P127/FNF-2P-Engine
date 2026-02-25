package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import Paths;
#if sys
import util.ThreadPool;
import util.DisplayUtil;
import openfl.Lib;
#end

class ClientPrefs
{
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var showRAM:Bool = true;
	public static var showOS:Bool = true;
	public static var showVideos:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var shaders:Bool = true;
	public static var framerate:Int = 63;
	// If enabled, keep the game's framerate synced to the current display refresh rate.
	public static var autoFramerate:Bool = true;
	// Synchronize buffer swaps to display refresh to reduce tearing
	public static var vsync:Bool = true;
	// Experimental: Prefer FlxAnimate for Animate atlas assets where available
	public static var useFlxAnimate:Bool = false;
	// Performance preferences
	// 0 means Auto (we'll pick a sensible default based on platform/CPU)
	public static var workerThreads:Int = 0;
	// Size of the text cache (KB) used for JSON/Lua/mod text files. 0 disables.
	public static var textCacheKB:Int = 1024;
	// Cache directory listings for mods/* to speed up script discovery
	public static var modsDirCache:Bool = true;
	// Keep frequently used graphics persisted in GPU/bitmap cache for faster renders
	public static var gpuPrecache:Bool = true;
	// Wait for Inst/Voices to be preloaded before finishing LoadingState
	public static var waitAudioPreload:Bool = true;
	// Expand GPU prewarm to include pixel UI assets
	public static var prewarmPixelAssets:Bool = true;
	// Expand GPU prewarm to include current stage graphic(s)
	public static var prewarmStageAssets:Bool = true;
	// Run a boot-time preload state (Cache) before Title to warm images/audio (and optionally videos)
	public static var bootPreloadAtBoot:Bool = true;
	// Also warm video files at boot by reading headers (no decoding)
	public static var bootPreloadVideos:Bool = true;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var autoPauseSet:Bool = true;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var checkForUpdates:Bool = true;
	public static var comboStacking = true;
	public static var comboCamSet:String = 'camHUD'; // custom
	public static var pauseStatePreferDebug = false;
	public static var noteHoldSplashes:Bool = true;
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [W, UP],
		'note_right' => [D, RIGHT],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_up' => [W, UP],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R, NONE],
		'volume_mute' => [ZERO, NONE],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN, NONE],
		'debug_2' => [EIGHT, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		// trace(defaultKeys);
	}

	public static function saveSettings()
	{
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.showRAM = showRAM;
		FlxG.save.data.showOS = showOS;
		FlxG.save.data.showVideos = showVideos;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.autoFramerate = autoFramerate;
		FlxG.save.data.useFlxAnimate = useFlxAnimate;
		FlxG.save.data.vsync = vsync;
		FlxG.save.data.workerThreads = workerThreads;
		FlxG.save.data.textCacheKB = textCacheKB;
		FlxG.save.data.modsDirCache = modsDirCache;
		FlxG.save.data.gpuPrecache = gpuPrecache;
		FlxG.save.data.waitAudioPreload = waitAudioPreload;
		FlxG.save.data.prewarmPixelAssets = prewarmPixelAssets;
		FlxG.save.data.prewarmStageAssets = prewarmStageAssets;
		FlxG.save.data.bootPreloadAtBoot = bootPreloadAtBoot;
		FlxG.save.data.bootPreloadVideos = bootPreloadVideos;
		// FlxG.save.data.cursing = cursing;
		// FlxG.save.data.violence = violence;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.autoPauseSet = autoPauseSet;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.comboStacking = comboStacking;
		FlxG.save.data.comboCamSet = comboCamSet;
		FlxG.save.data.pauseStatePreferDebug = pauseStatePreferDebug;
		FlxG.save.data.noteHoldSplashes = noteHoldSplashes;

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'haryulovescat'); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		// FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		if (FlxG.save.data.noteHoldSplashes != null)
		{
			noteHoldSplashes = FlxG.save.data.noteHoldSplashes;
		}
		if (FlxG.save.data.pauseStatePreferDebug != null)
		{
			pauseStatePreferDebug = FlxG.save.data.pauseStatePreferDebug;
		}
		if (FlxG.save.data.autoPauseSet != null)
		{
			autoPauseSet = FlxG.save.data.autoPauseSet;			
		}
		if (FlxG.save.data.downScroll != null)
		{
			downScroll = FlxG.save.data.downScroll;
		}
		if (FlxG.save.data.middleScroll != null)
		{
			middleScroll = FlxG.save.data.middleScroll;
		}
		if (FlxG.save.data.opponentStrums != null)
		{
			opponentStrums = FlxG.save.data.opponentStrums;
		}
		if (FlxG.save.data.showFPS != null)
		{
			showFPS = FlxG.save.data.showFPS;
			if (Main.fpsVar != null)
			{
				Main.fpsVar.visible = showFPS;
			}
		}
		if (FlxG.save.data.showRAM != null)
		{
			showRAM = FlxG.save.data.showRAM;
		}
		if (FlxG.save.data.showOS != null)
		{
			showOS = FlxG.save.data.showOS;
		}
		if (FlxG.save.data.showVideos != null)
		{
			showVideos = FlxG.save.data.showVideos;
		}
		if (FlxG.save.data.flashing != null)
		{
			flashing = FlxG.save.data.flashing;
		}
		if (FlxG.save.data.globalAntialiasing != null)
		{
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if (FlxG.save.data.noteSplashes != null)
		{
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if (FlxG.save.data.lowQuality != null)
		{
			lowQuality = FlxG.save.data.lowQuality;
		}
		if (FlxG.save.data.shaders != null)
		{
			shaders = FlxG.save.data.shaders;
		}
		if (FlxG.save.data.workerThreads != null)
		{
			workerThreads = FlxG.save.data.workerThreads;
		}
		if (FlxG.save.data.autoFramerate != null)
		{
			autoFramerate = FlxG.save.data.autoFramerate;
		}
        if (FlxG.save.data.vsync != null)
        {
            vsync = FlxG.save.data.vsync;
        }
		if (FlxG.save.data.textCacheKB != null)
		{
			textCacheKB = FlxG.save.data.textCacheKB;
		}
		if (FlxG.save.data.modsDirCache != null)
		{
			modsDirCache = FlxG.save.data.modsDirCache;
		}
		if (FlxG.save.data.gpuPrecache != null)
		{
			gpuPrecache = FlxG.save.data.gpuPrecache;
		}
		if (FlxG.save.data.waitAudioPreload != null)
		{
			waitAudioPreload = FlxG.save.data.waitAudioPreload;
		}
		if (FlxG.save.data.prewarmPixelAssets != null)
		{
			prewarmPixelAssets = FlxG.save.data.prewarmPixelAssets;
		}
		if (FlxG.save.data.prewarmStageAssets != null)
		{
			prewarmStageAssets = FlxG.save.data.prewarmStageAssets;
		}
		if (FlxG.save.data.bootPreloadAtBoot != null)
		{
			bootPreloadAtBoot = FlxG.save.data.bootPreloadAtBoot;
		}
		if (FlxG.save.data.bootPreloadVideos != null)
		{
			bootPreloadVideos = FlxG.save.data.bootPreloadVideos;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
		} else {
			// First run: pick a sensible framerate based on the monitor refresh rate.
			#if sys
			framerate = DisplayUtil.getRefreshRate(60);
			#else
			framerate = 60;
			#end
		}
		applyFramerateSettings(true);
		if (FlxG.save.data.useFlxAnimate != null) {
			useFlxAnimate = FlxG.save.data.useFlxAnimate;
		}
		/*if(FlxG.save.data.cursing != null) {
				cursing = FlxG.save.data.cursing;
			}
			if(FlxG.save.data.violence != null) {
				violence = FlxG.save.data.violence;
		}*/
		if (FlxG.save.data.camZooms != null)
		{
			camZooms = FlxG.save.data.camZooms;
		}
		if (FlxG.save.data.hideHud != null)
		{
			hideHud = FlxG.save.data.hideHud;
		}
		if (FlxG.save.data.noteOffset != null)
		{
			noteOffset = FlxG.save.data.noteOffset;
		}
		if (FlxG.save.data.arrowHSV != null)
		{
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if (FlxG.save.data.ghostTapping != null)
		{
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if (FlxG.save.data.timeBarType != null)
		{
			timeBarType = FlxG.save.data.timeBarType;
		}
		if (FlxG.save.data.scoreZoom != null)
		{
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if (FlxG.save.data.noReset != null)
		{
			noReset = FlxG.save.data.noReset;
		}
		if (FlxG.save.data.healthBarAlpha != null)
		{
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if (FlxG.save.data.comboOffset != null)
		{
			comboOffset = FlxG.save.data.comboOffset;
		}

		if (FlxG.save.data.ratingOffset != null)
		{
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if (FlxG.save.data.sickWindow != null)
		{
			sickWindow = FlxG.save.data.sickWindow;
		}
		if (FlxG.save.data.goodWindow != null)
		{
			goodWindow = FlxG.save.data.goodWindow;
		}
		if (FlxG.save.data.badWindow != null)
		{
			badWindow = FlxG.save.data.badWindow;
		}
		if (FlxG.save.data.safeFrames != null)
		{
			safeFrames = FlxG.save.data.safeFrames;
		}
		if (FlxG.save.data.controllerMode != null)
		{
			controllerMode = FlxG.save.data.controllerMode;
		}
		if (FlxG.save.data.hitsoundVolume != null)
		{
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if (FlxG.save.data.pauseMusic != null)
		{
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if (FlxG.save.data.comboCamSet != null)
		{
			comboCamSet = FlxG.save.data.comboCamSet;
		}
		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}

		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}
		if (FlxG.save.data.checkForUpdates != null)
		{
			checkForUpdates = FlxG.save.data.checkForUpdates;
		}
		if (FlxG.save.data.comboStacking != null)
			comboStacking = FlxG.save.data.comboStacking;

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'haryulovescat');
		if (save != null && save.data.customControls != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls)
			{
				keyBinds.set(control, keys);
			}
			reloadControls();
		}

		// Apply runtime tuning knobs after all prefs are loaded
		applyRuntimeTuning();
	}

	static var _refreshProbeCooldown:Float = 0;
	static var _lastRefreshRate:Int = 0;

	public static function tickDisplayRefreshSync(elapsed:Float):Void
	{
		if (!autoFramerate) return;
		_refreshProbeCooldown -= elapsed;
		if (_refreshProbeCooldown > 0) return;
		_refreshProbeCooldown = 1.0; // probe about once per second

		#if sys
		var rr:Int = DisplayUtil.getRefreshRate(framerate);
		if (rr > 0 && rr != _lastRefreshRate)
		{
			_lastRefreshRate = rr;
			if (framerate != rr)
			{
				framerate = rr;
				applyFramerateSettings(false);
			}
		}
		#end
	}

	public static function applyFramerateSettings(fromLoad:Bool):Void
	{
		#if !html5
		var target:Int = framerate;
		#if sys
		if (autoFramerate)
		{
			target = DisplayUtil.getRefreshRate(target);
		}
		#end
		if (target <= 0) target = 60;

		// Keep prefs in sync when auto mode is on
		if (autoFramerate) framerate = target;

		// Avoid redundant assignments
		if (FlxG.drawFramerate == target && FlxG.updateFramerate == target) return;
		if (target > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = target;
			FlxG.drawFramerate = target;
		}
		else
		{
			FlxG.drawFramerate = target;
			FlxG.updateFramerate = target;
		}
		#end
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls()
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	// Apply runtime configuration to subsystems that expose tuning knobs.
	static function applyRuntimeTuning():Void
	{
		// Configure text and directory caches used by Paths utilities
		Paths.setTextCacheMaxKB(textCacheKB);
		Paths.setDirCacheEnabled(modsDirCache);
		Paths.setPersistGraphics(gpuPrecache);

		// Initialize thread pool according to preference (no-op on targets without threads)
		#if sys
		ThreadPool.init(workerThreads);
		// Apply V-Sync to the native window when available
		try {
			var win:Dynamic = Lib.application.window;
			if (win != null && Reflect.hasField(win, "vsync")) {
				Reflect.setProperty(win, "vsync", vsync);
			}
		} catch (_:Dynamic) {}
		#end
	}
}
