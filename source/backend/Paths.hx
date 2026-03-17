package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;

#if MODS_ALLOWED
import backend.Mods;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	#if android
	public static inline var BASE_PATH:String = "/storage/emulated/0/Android/data/com.shadowmario.psychengine/files/";
	#else
	public static inline var BASE_PATH:String = "";
	#end

	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [BASE_PATH + 'assets/shared/music/freakyMenu.$SOUND_EXT'];

	public static function clearUnusedMemory()
	{
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key));
				currentTrackedAssets.remove(key);
			}
		}
		System.gc();
	}

	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					for (member in grp)
						checkForGraphics(member);
					return;
				}
			} catch(e:Dynamic) {}

			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null) protectedGfx.push(gfx);
			} catch(e:Dynamic) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic);
					currentTrackedAssets.remove(key);
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			#if sys
			if (FileSystem.exists(levelPath)) return levelPath;
			#end
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}
		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return BASE_PATH + 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return BASE_PATH + 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return BASE_PATH + 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/$key') + '.png';
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, IMAGE, parentFolder, true);
			#if sys
			if (FileSystem.exists(file)) {
				try {
					bitmap = BitmapData.fromFile(file);
				} catch(e:Dynamic) {
					trace('Failed to read external bitmap data: $file - $e');
				}
			}
			else
			#end
			if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null)
			{
				trace('Bitmap not found: $file | key: $key');
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			try {
				bitmap.lock();
				if (bitmap.__texture == null)
				{
					bitmap.image.premultiplied = true;
					bitmap.getTexture(FlxG.stage.context3D);
				}
				bitmap.getSurface();
				bitmap.disposeImage();
				bitmap.image.data = null;
				bitmap.image = null;
				bitmap.readable = true;
			} catch(e:Dynamic) {
				trace('GPU Caching failed for: $key - $e');
			}
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, null, !ignoreMods);
		#if sys
		if(FileSystem.exists(path)) {
			try {
				return File.getContent(path);
			} catch(e:Dynamic) {
				trace('Failed to read text file: $path - $e');
				return null; 
			}
		}
		#end
		return (OpenFlAssets.exists(path, TEXT)) ? OpenFlAssets.getText(path) : null;
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return BASE_PATH + 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		
		var normalPath = getPath(key, type, parentFolder, false);
		#if sys
		if(FileSystem.exists(normalPath)) return true;
		#end
		
		return (OpenFlAssets.exists(normalPath, type));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null; 

		var myXml:String = getPath('images/$key.xml', TEXT, parentFolder, true);
		if(FileSystem.exists(myXml)) {
			var xmlText:String = File.getContent(myXml);
			if (xmlText != null && xmlText.trim().length > 0)
				return FlxAtlasFrames.fromSparrow(imageLoaded, xmlText);
		} else if(OpenFlAssets.exists(myXml, TEXT)) {
			return FlxAtlasFrames.fromSparrow(imageLoaded, OpenFlAssets.getText(myXml));
		}

		var myJson:String = getPath('images/$key.json', TEXT, parentFolder, true);
		if(FileSystem.exists(myJson)) {
			var jsonText:String = File.getContent(myJson);
			if (jsonText != null && jsonText.trim().length > 0)
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonText);
		} else if(OpenFlAssets.exists(myJson, TEXT)) {
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, OpenFlAssets.getText(myJson));
		}

		return getPackerAtlas(key, parentFolder, allowGPU);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null;

		var xmlContent:String = '';

		#if MODS_ALLOWED
		var xmlPath:String = modsXml(key);
		if(FileSystem.exists(xmlPath)) {
			xmlContent = File.getContent(xmlPath);
		} else
		#end
		{
			var path = getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder);
			if (FileSystem.exists(path)) xmlContent = File.getContent(path);
			else if (OpenFlAssets.exists(path, TEXT)) xmlContent = OpenFlAssets.getText(path);
		}

		if (xmlContent == null || xmlContent.trim().length == 0) return null;

		return FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null;

		var txtContent:String = '';

		#if MODS_ALLOWED
		var txtPath:String = modsTxt(key);
		if(FileSystem.exists(txtPath)) {
			txtContent = File.getContent(txtPath);
		} else
		#end
		{
			var path = getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder);
			if (FileSystem.exists(path)) txtContent = File.getContent(path);
			else if (OpenFlAssets.exists(path, TEXT)) txtContent = OpenFlAssets.getText(path);
		}

		if (txtContent == null || txtContent.trim().length == 0) return null;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, txtContent);
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null;

		var jsonContent:String = '';

		#if MODS_ALLOWED
		var jsonPath:String = modsImagesJson(key);
		if(FileSystem.exists(jsonPath)) {
			jsonContent = File.getContent(jsonPath);
		} else
		#end
		{
			var path = getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder);
			if (FileSystem.exists(path)) jsonContent = File.getContent(path);
			else if (OpenFlAssets.exists(path, TEXT)) jsonContent = OpenFlAssets.getText(path);
		}

		if (jsonContent == null || jsonContent.trim().length == 0) return null;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonContent);
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;
		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);
		if(!currentTrackedSounds.exists(file))
		{
			#if sys
			if(FileSystem.exists(file)) {
				try {
					currentTrackedSounds.set(file, Sound.fromFile(file));
				} catch(e:Dynamic) {
					trace('Failed to load external sound: $file - $e');
				}
			}
			else
			#end
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			else if(beepOnNull)
			{
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return BASE_PATH + 'mods/' + key;

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return BASE_PATH + 'mods/' + key;
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = getTextFromFile(spriteJson, true);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = getTextFromFile(animationJson, true);
		}

		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					changedImage = true;
					folderOrImg = image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if(!changedAnimJson)
			{
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}
