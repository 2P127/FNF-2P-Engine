package util;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class ScriptCache {
	static var cache:Map<String, String> = new Map();
	#if sys
	static var cacheMtime:Map<String, Float> = new Map();
	#end

	public static function clear():Void {
		cache = new Map();
		#if sys
		cacheMtime = new Map();
		#end
	}

	public static function get(path:String):String {
		#if sys
		if (path != null && cache.exists(path) && FileSystem.exists(path)) {
			try {
				var stat = FileSystem.stat(path);
				var mt:Float = (stat != null && stat.mtime != null) ? stat.mtime.getTime() : 0;
				var cachedMt = cacheMtime.get(path);
				if (cachedMt == null || cachedMt != mt) {
					var s = File.getContent(path);
					cache.set(path, s);
					cacheMtime.set(path, mt);
				}
			} catch (_:Dynamic) {}
		}
		#end
		return cache.get(path);
	}

	public static function preload(paths:Array<String>):Void {
		#if sys
		for (p in paths) {
			if (p == null) continue;
			try {
				if (sys.FileSystem.exists(p)) {
					var stat = FileSystem.stat(p);
					var mt:Float = (stat != null && stat.mtime != null) ? stat.mtime.getTime() : 0;
					var cachedMt = cacheMtime.get(p);
					if (!cache.exists(p) || cachedMt == null || cachedMt != mt) {
						var s = sys.io.File.getContent(p);
						cache.set(p, s);
						cacheMtime.set(p, mt);
					}
				}
			} catch (e:Dynamic) {
				// ignore individual failures
			}
		}
		#end
	}
}
