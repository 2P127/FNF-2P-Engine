package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var autoFpsOption:Option;
	var framerateOption:Option;
	var _framerateDisplayFormat:String = '%v FPS';

	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Shaders', //Name
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.', //Description
			'shaders', //Save data variable name
			'bool', //Variable type
			true); //Default value
		addOption(option);

		var optCacheOnGPU:Option = new Option('GPU Caching',
			'Uploads textures to GPU VRAM and frees CPU RAM. Saves memory at the cost of VRAM.\nTakes effect on newly loaded images.',
			'cacheOnGPU',
			'bool',
			false);
		addOption(optCacheOnGPU);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		autoFpsOption = new Option('Auto Framerate',
			'Keeps FPS synced to your monitor refresh rate (recommended).',
			'autoFramerate',
			'bool',
			true);
		autoFpsOption.onChange = function() {
			syncFramerateUI();
			ClientPrefs.applyFramerateSettings(false);
		};
		addOption(autoFpsOption);

		framerateOption = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(framerateOption);

		framerateOption.minValue = 60;
		framerateOption.maxValue = 360;
		framerateOption.displayFormat = _framerateDisplayFormat;
		framerateOption.onChange = onChangeFramerate;
		#end

		super();
		#if !html5
		syncFramerateUI();
		#end
	}

	function syncFramerateUI():Void
	{
		#if !html5
		if (framerateOption == null) return;
		var auto:Bool = ClientPrefs.autoFramerate;
		framerateOption.enabled = !auto;
		// When auto is enabled, show a non-interactive label so it doesn't look like a "real" slider.
		framerateOption.displayFormat = auto ? 'Auto (%v FPS)' : _framerateDisplayFormat;
		updateTextFrom(framerateOption);
		#end
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		ClientPrefs.applyFramerateSettings(false);
	}
}