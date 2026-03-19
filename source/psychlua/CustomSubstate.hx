package psychlua;

import flixel.FlxObject;
import flixel.FlxG;

class CustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
		Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
		Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
	}
	#end
	
	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		var pause:Bool = (pauseGame == true);

		if(pause && PlayState.instance != null)
		{
			if (FlxG.camera != null) FlxG.camera.followLerp = 0;
			
			PlayState.instance.persistentUpdate = false;
			PlayState.instance.persistentDraw = true;
			PlayState.instance.paused = true;
			
			if(FlxG.sound.music != null) 
			{
				FlxG.sound.music.pause();
			}
			
			if(PlayState.instance.vocals != null) 
			{
				PlayState.instance.vocals.pause();
			}
		}
		
		if (PlayState.instance != null) 
		{
			PlayState.instance.openSubState(new CustomSubstate(name));
		}
	}

	public static function closeCustomSubstate()
	{
		if(instance != null && PlayState.instance != null)
		{
			PlayState.instance.closeSubState();
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance != null)
		{
			var rawObject:Dynamic = MusicBeatState.getVariables().get(tag);
			
			if (rawObject != null && Std.isOfType(rawObject, FlxObject))
			{
				var tagObject:FlxObject = cast rawObject;
				
				var position:Int = (pos == null) ? -1 : pos;

				if(position < 0) 
					instance.add(tagObject);
				else 
					instance.insert(position, tagObject);
					
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;
		
		if (PlayState.instance != null) 
		{
			PlayState.instance.setOnHScript('customSubstate', instance);
			PlayState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		}
		
		super.create();
		
		if (PlayState.instance != null) 
		{
			PlayState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
		}
	}
	
	public function new(name:String)
	{
		CustomSubstate.name = name;
		
		if (PlayState.instance != null) 
		{
			PlayState.instance.setOnHScript('customSubstateName', name);
		}
		
		super();
		
		if (FlxG.cameras != null && FlxG.cameras.list != null && FlxG.cameras.list.length > 0) 
		{
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}
	}
	
	override function update(elapsed:Float)
	{
		if (PlayState.instance != null) PlayState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		
		super.update(elapsed);
		
		if (PlayState.instance != null) PlayState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		if (PlayState.instance != null) 
		{
			PlayState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		}
		
		instance = null;
		name = 'unnamed';

		if (PlayState.instance != null) 
		{
			PlayState.instance.setOnHScript('customSubstate', null);
			PlayState.instance.setOnHScript('customSubstateName', name);
		}
		
		super.destroy();
	}
}
