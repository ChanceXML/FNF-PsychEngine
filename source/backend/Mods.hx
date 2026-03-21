package backend;

import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.Json;

using StringTools;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	#if android
	public static final BASE_PATH:String = "/storage/emulated/0/Android/data/com.shadowmario.psychengine/files/";
	public static final MODS_PATH:String = "/storage/emulated/0/Android/data/com.shadowmario.psychengine/files/mods/";
	#else
	public static final BASE_PATH:String = "";
	public static final MODS_PATH:String = "mods/";
	#end

	static public var currentModDirectory:String = '';

	public static final ignoreModFolders:Array<String> = [
		'characters','custom_events','custom_notetypes','data',
		'songs','music','sounds','shaders','videos','images',
		'stages','weeks','fonts','scripts','achievements'
	];

	private static var globalMods:Array<String> = [];

	inline public static function luaSafe(path:String):String 
	{
		var safePath = path.replace("\\", "/");
		while (safePath.indexOf("//") != -1) {
			safePath = safePath.replace("//", "/");
		}
		return safePath;
	}

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods()
	{
		globalMods = [];

		for(mod in parseList().enabled)
		{
			try
			{
				var pack:Dynamic = getPack(mod);

				if(pack != null && pack.runsGlobally == true)
					globalMods.push(mod);
			}
			catch(e)
			{
				trace("Mod load error: " + mod);
			}
		}

		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];

		#if MODS_ALLOWED

		var modsFolder = luaSafe(MODS_PATH);

		if(!FileSystem.exists(modsFolder))
			FileSystem.createDirectory(modsFolder);

		for(folder in FileSystem.readDirectory(modsFolder))
		{
			var path = luaSafe(modsFolder + "/" + folder);

			if(FileSystem.isDirectory(path)
			&& !ignoreModFolders.contains(folder.toLowerCase())
			&& !list.contains(folder))
			{
				list.push(folder);
			}
		}

		#end

		return list;
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String=null, allowDuplicates:Bool=false)
	{
		if(defaultDirectory == null)
			defaultDirectory = Paths.getSharedPath();

		defaultDirectory = defaultDirectory.trim();

		if(!defaultDirectory.endsWith('/'))
			defaultDirectory += '/';

		if(!defaultDirectory.startsWith('assets/'))
			defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];

		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = luaSafe(defaultDirectory + path);

		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for(file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);

			for(value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}

		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool=true)
	{
		var foldersToCheck:Array<String> = [];

		var targetPath = luaSafe(BASE_PATH + path);

		if(FileSystem.exists(luaSafe(targetPath + "/" + fileToFind)))
			foldersToCheck.push(luaSafe(targetPath + "/" + fileToFind));

		if(Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);

			var full = luaSafe(BASE_PATH + pth);

			if(!foldersToCheck.contains(full) && FileSystem.exists(full))
				foldersToCheck.push(full);
		}

		#if MODS_ALLOWED
		if(mods)
		{
			for(mod in getGlobalMods())
			{
				var folder = luaSafe(MODS_PATH + "/" + mod + "/" + fileToFind);

				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}

			var folder = luaSafe(MODS_PATH + "/" + fileToFind);

			if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
				foldersToCheck.push(folder);

			if(currentModDirectory != null && currentModDirectory.length > 0)
			{
				var folder = luaSafe(MODS_PATH + "/" + currentModDirectory + "/" + fileToFind);

				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}
		}
		#end

		return foldersToCheck;
	}

	public static function getPack(?folder:String=null):Dynamic
	{
		#if MODS_ALLOWED

		if(folder == null)
			folder = currentModDirectory;

		var path = luaSafe(MODS_PATH + "/" + folder + "/pack.json");
		if(!FileSystem.exists(path)) return null;

		if(FileSystem.exists(path))
		{
			try
			{
				var rawJson:String = File.getContent(path);

				if(rawJson != null && rawJson.length > 0)
					return tjson.TJSON.parse(rawJson);
			}
			catch(e:Dynamic)
			{
				trace(e);
			}
		}

		#end

		return null;
	}

	public static var updatedOnState:Bool = false;

	inline public static function parseList():ModsList
	{
		if(!updatedOnState)
			updateModList();

		var list:ModsList = {
			enabled:[],
			disabled:[],
			all:[]
		};

		#if MODS_ALLOWED

		var modsListPath = luaSafe(BASE_PATH + "/modsList.txt");

		if(FileSystem.exists(modsListPath))
		{
			for(mod in CoolUtil.coolTextFile(modsListPath))
			{
				if(mod.trim().length < 1)
					continue;

				var dat = mod.split("|");

				list.all.push(dat[0]);

				if(dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
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

		var modsListPath = luaSafe(BASE_PATH + "/modsList.txt");

		if(FileSystem.exists(modsListPath))
		{
			for(mod in CoolUtil.coolTextFile(modsListPath))
			{
				var dat = mod.split("|");

				var folder = dat[0];

				var modDir = luaSafe(MODS_PATH + "/" + folder);

				if(folder.trim().length > 0
				&& FileSystem.exists(modDir)
				&& FileSystem.isDirectory(modDir)
				&& !added.contains(folder))
				{
					added.push(folder);

					list.push([folder,(dat[1]=="1")]);
				}
			}
		}

		for(folder in getModDirectories())
		{
			var modDir = luaSafe(MODS_PATH + "/" + folder);

			if(folder.trim().length > 0
			&& FileSystem.exists(modDir)
			&& FileSystem.isDirectory(modDir)
			&& !ignoreModFolders.contains(folder.toLowerCase())
			&& !added.contains(folder))
			{
				added.push(folder);

				list.push([folder,true]);
			}
		}

		var fileStr = "";

		for(values in list)
		{
			if(fileStr.length > 0)
				fileStr += "\n";

			fileStr += values[0] + "|" + (values[1] ? "1" : "0");
		}

		File.saveContent(modsListPath,fileStr);

		updatedOnState = true;

		#end
	}

	public static function loadTopMod()
	{
		currentModDirectory = "";

		#if MODS_ALLOWED

		var list = parseList().enabled;

		if(list != null && list.length > 0)
			currentModDirectory = list[0];

		#end
	}
}
