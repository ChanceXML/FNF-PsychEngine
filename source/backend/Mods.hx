package backend;

import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.Json;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	public static final ANDROID_BASE_PATH:String = "/storage/emulated/0/Android/data/com.shadowmario.psychengine/files/";

	static public var currentModDirectory:String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 
		'songs', 'music', 'sounds', 'shaders', 'videos', 'images', 
		'stages', 'weeks', 'fonts', 'scripts', 'achievements'
	];

	private static var globalMods:Array<String> = [];

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods()
	{
		globalMods = [];
		for(mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			if(pack != null && pack.runsGlobally) globalMods.push(mod);
		}
		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = ANDROID_BASE_PATH + "mods/"; 
		
		if(!FileSystem.exists(modsFolder)) {
			try {
				FileSystem.createDirectory(modsFolder);
			} catch(e:Dynamic) {
				trace("Failed to create mods directory: " + e);
			}
		}

		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}
	
	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if(defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		
		var cleanPath = path.startsWith(ANDROID_BASE_PATH) ? path : ANDROID_BASE_PATH + path;
		
		if(FileSystem.exists(cleanPath + fileToFind))
			foldersToCheck.push(cleanPath + fileToFind);

		if(Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			var cleanPth = pth.startsWith(ANDROID_BASE_PATH) ? pth : ANDROID_BASE_PATH + pth;
			if(!foldersToCheck.contains(cleanPth) && FileSystem.exists(cleanPth))
				foldersToCheck.push(cleanPth);
		}

		#if MODS_ALLOWED
		if(mods)
		{
			for(mod in Mods.getGlobalMods())
			{
				var folder:String = ANDROID_BASE_PATH + Paths.mods(mod + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}

			var folder:String = ANDROID_BASE_PATH + Paths.mods(fileToFind);
			if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);

			if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = ANDROID_BASE_PATH + Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic
	{
		#if MODS_ALLOWED
		if(folder == null) folder = Mods.currentModDirectory;

		var path = ANDROID_BASE_PATH + Paths.mods(folder + '/pack.json');
		if(FileSystem.exists(path)) {
			try {
				#if sys
				var rawJson:String = File.getContent(path);
				#else
				var rawJson:String = Assets.getText(path);
				#end
				if(rawJson != null && rawJson.length > 0) return tjson.TJSON.parse(rawJson);
			} catch(e:Dynamic) {
				trace(e);
			}
		}
		#end
		return null;
	}

	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList {
		if(!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		var modsListPath:String = ANDROID_BASE_PATH + 'modsList.txt';
		if (FileSystem.exists(modsListPath)) {
			try {
				for (mod in CoolUtil.coolTextFile(modsListPath))
				{
					if(mod.trim().length < 1) continue;

					var dat = mod.split("|");
					list.all.push(dat[0]);
					if (dat[1] == "1")
						list.enabled.push(dat[0]);
					else
						list.disabled.push(dat[0]);
				}
			} catch(e) {
				trace(e);
			}
		}
		#end
		return list;
	}
	
	private static function updateModList()
	{
		#if MODS_ALLOWED
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		var modsListPath:String = ANDROID_BASE_PATH + 'modsList.txt';

		if(!FileSystem.exists(ANDROID_BASE_PATH)) {
			try {
				FileSystem.createDirectory(ANDROID_BASE_PATH);
			} catch(e:Dynamic) {
				trace("Critical: Could not create Android base path! " + e);
				return;
			}
		}

		if (FileSystem.exists(modsListPath)) {
			try {
				for (mod in CoolUtil.coolTextFile(modsListPath))
				{
					var dat:Array<String> = mod.split("|");
					var folder:String = dat[0];
					var modDir:String = ANDROID_BASE_PATH + Paths.mods(folder);
					
					if(folder.trim().length > 0 && FileSystem.exists(modDir) && FileSystem.isDirectory(modDir) && !added.contains(folder))
					{
						added.push(folder);
						list.push([folder, (dat[1] == "1")]);
					}
				}
			} catch(e) {
				trace(e);
			}
		}
		
		for (folder in getModDirectories())
		{
			var modDir:String = ANDROID_BASE_PATH + Paths.mods(folder);
			if(folder.trim().length > 0 && FileSystem.exists(modDir) && FileSystem.isDirectory(modDir) &&
			!ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]);
			}
		}

		var fileStr:String = '';
		for (values in list)
		{
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		try {
			File.saveContent(modsListPath, fileStr);
			updatedOnState = true;
		} catch(e:Dynamic) {
			trace("Failed to save modsList.txt: " + e);
		}
		#end
	}

	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';
		
		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if(list != null && list.length > 0 && list[0] != null)
			Mods.currentModDirectory = list[0];
		#end
	}
}
