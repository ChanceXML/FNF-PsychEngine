import sys.io.File;
import llua.Lua;
import llua.LuaL;

class Test {
    static function main() {
        trace("=== Starting Lua system test ===");

        var L = LuaL.newstate();
        if (L == null) {
            trace("Lua state FAILED");
            Sys.exit(1);
        }

        LuaL.openlibs(L);

        // test Lua string execution
        trace("Testing Lua string...");
        if (LuaL.dostring(L, "print('Lua string works')") != 0) {
            trace("Lua string execution FAILED");
            Sys.exit(1);
        }

        // test loading a real Lua file
        trace("Testing Lua file load...");
        var code = File.getContent("test/Test.lua");

        if (LuaL.dostring(L, code) != 0) {
            trace("Lua file execution FAILED");
            Sys.exit(1);
        }

        trace("=== Lua subsystem OK ===");
    }
}
