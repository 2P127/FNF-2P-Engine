package options;

import flixel.FlxG;

class PerformanceSettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Performance';
		rpcTitle = 'Performance Settings';

		var hw = #if sys util.ThreadPool.getHardwareThreadCount() #else 1 #end;

		// CPU Worker threads (0 = Auto)
		var optThreads:Option = new Option('CPU Threads',
			'Sets background worker threads for file parsing/loading. 0 = Auto (recommended).',
			'workerThreads',
			'int',
			0);
		optThreads.minValue = 0;
		optThreads.maxValue = Math.max(1, hw);
		optThreads.displayFormat = '%v';
		optThreads.onChange = function() {
			#if sys
			util.ThreadPool.init(ClientPrefs.workerThreads);
			#end
		};
		addOption(optThreads);

		// GPU precache toggle
		var optGPU:Option = new Option('GPU Precache',
			'Keeps common graphics persisted to reduce stutter. Disable to save memory.',
			'gpuPrecache',
			'bool',
			true);
		optGPU.onChange = function() {
			Paths.setPersistGraphics(ClientPrefs.gpuPrecache);
		};
		addOption(optGPU);

		// Text cache size
		var optTextCache:Option = new Option('Text Cache Size (KB)',
			'Caches Lua/JSON text to reduce disk reads. Set to 0 to disable.',
			'textCacheKB',
			'int',
			1024);
		optTextCache.minValue = 0;
		optTextCache.maxValue = 8192;
		optTextCache.displayFormat = '%v KB';
		optTextCache.onChange = function() {
			Paths.setTextCacheMaxKB(ClientPrefs.textCacheKB);
		};
		addOption(optTextCache);

		// Mods directory cache
		var optDirCache:Option = new Option('Mods Dir Cache',
			'Caches mods/ directory listings to speed up Lua discovery. Disable if frequently editing files.',
			'modsDirCache',
			'bool',
			true);
		optDirCache.onChange = function() {
			Paths.setDirCacheEnabled(ClientPrefs.modsDirCache);
		};
		addOption(optDirCache);

		// Audio preload gating
		var optWaitAudio:Option = new Option('Wait Audio Preload',
			'If enabled, the loading screen waits for Inst/Voices to finish preloading before starting the song.',
			'waitAudioPreload',
			'bool',
			true);
		addOption(optWaitAudio);

		// Boot-time preload (Cache state before Title)
		var optBootPreload:Option = new Option('Boot Preload (Before Title)',
			'Run a short preloading step before the Title Screen to warm images and audio. Reduces first-hit stutters.',
			'bootPreloadAtBoot',
			'bool',
			true);
		addOption(optBootPreload);

		// Include video warm-up at boot (header read only)
		var optBootVideo:Option = new Option('Boot Preload: Warm Videos',
			'Also touch video files (read headers) during boot preload. No decoding, minor disk I/O.',
			'bootPreloadVideos',
			'bool',
			true);
		addOption(optBootVideo);

		// Pixel UI prewarm
		var optPixelPrewarm:Option = new Option('Prewarm Pixel UI',
			'Preload pixel UI graphics during loading to reduce first-hit stutters.',
			'prewarmPixelAssets',
			'bool',
			true);
		addOption(optPixelPrewarm);

		// Stage graphics prewarm
		var optStagePrewarm:Option = new Option('Prewarm Stage Graphics',
			'Preload current stage main graphics during loading. Slightly higher memory use.',
			'prewarmStageAssets',
			'bool',
			true);
		addOption(optStagePrewarm);

		super();
	}
}
