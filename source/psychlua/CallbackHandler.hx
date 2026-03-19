#if LUA_ALLOWED
package psychlua;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			var cbf:Dynamic = null;
			if (Lua_helper.callbacks != null) cbf = Lua_helper.callbacks.get(fname);

			if(cbf == null) 
			{
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if(last == null || last.lua != l)
				{
					if(PlayState.instance != null && PlayState.instance.luaArray != null)
					{
						for (script in PlayState.instance.luaArray)
						{
							if(script != FunkinLua.lastCalledScript && script != null && script.lua == l && script.callbacks != null)
							{
								cbf = script.callbacks.get(fname);
								if (cbf != null) break;
							}
						}
					}
				}
				else if (last != null && last.callbacks != null) cbf = last.callbacks.get(fname);
			}
			
			if(cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams) {
				args.push(Convert.fromLua(l, i + 1));
			}

			var ret:Dynamic = null;

			ret = Reflect.callMethod(null, cbf, args);

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:haxe.Exception)
		{
			if(Lua_helper.sendErrorsToLua)
			{
				LuaL.error(l, 'CALLBACK ERROR! ${e.details()}');
				return 0;
			}
			throw e;
		}
		return 0;
	}
}
#end
