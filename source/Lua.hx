import funkin.backend.utils.NdllUtil;

var lua_create = NdllUtil.getFunction("lua", "lua_create", 0);
var lua_get_version = NdllUtil.getFunction("lua", "lua_get_version", 0);
var lua_call_function = NdllUtil.getFunction("lua", "lua_call_function", 3);
var lua_execute = NdllUtil.getFunction("lua", "lua_execute", 2);
var lua_load_context = NdllUtil.getFunction("lua", "lua_load_context", 2);
var lua_load_libs = NdllUtil.getFunction("lua", "lua_load_libs", 2);
var add_callback_function = NdllUtil.getFunction("lua", "add_callback_function", 2);
var set_callbacks_function = NdllUtil.getFunction("lua", "set_callbacks_function", 1);
var _lua_type = NdllUtil.getFunction("lua", "_lua_type", 2);
var lua_val_to_haxe = NdllUtil.getFunction("lua", "lua_val_to_haxe", 2);
var _lua_gettop = NdllUtil.getFunction("lua", "_lua_gettop", 1);
var _haxe_to_lua = NdllUtil.getFunction("lua", "_haxe_to_lua", 2);

class Lua
{
	var handle = null;
	var self = null;
	var code = null;
	var callbacks = ["placeholder" => ""];
	/**
	 * Creates a new lua vm state
	 */
	var create = function()
	{
		self.handle = lua_create();
		self.set_callbacks_function(self.callback_handler);
	}

	/**
	 * Get the version string from Lua
	 */
	/*var version:String;
	private inline function get_version():String
	{
		return lua_get_version();
	}*/

	/**
	 * Loads lua libraries (base, debug, io, math, os, package, string, table)
	 * @param libs An array of library names to load
	 */
	var loadLibs = function(libs:Array<String>):Void
	{
		lua_load_libs(self.handle, libs);
	}

	/**
	 * Defines variables in the lua vars
	 * @param vars An object defining the lua variables to create
	 */
	var setVars = function(vars:Dynamic):Void
	{
		lua_load_context(self.handle, vars);
	}

	/**
	 * Runs a lua script
	 * @param script The lua script to run in a string
	 * @return The result from the lua script in Haxe
	 */
	var execute = function(script:String):Dynamic
	{
		return lua_execute(self.handle, script);
	}

	/**
	 * Calls a previously loaded lua function
	 * @param func The lua function name (globals only)
	 * @param args A single argument or array of arguments
	 */
	var call = function(func:String, args:Dynamic):Dynamic
	{
		return lua_call_function(self.handle, func, args);
	}

	var add_callback =  function(name, code) {
		callbacks.set(name, code);
		add_callback_function(self.handle, name);
		return true;
	}

	var callback_handler = function (fname)
	{
		var cbf:Dynamic = callbacks.get(fname);
		
		if(cbf == null) return 0;

		var nparams = _lua_gettop(self.handle);
		var args = [];
		for (i in 0...nparams) {
			args[i] = lua_val_to_haxe(self.handle,i + 1);
		}

		var ret = null;

		ret = Reflect.callMethod(null,cbf,args);
	}

	var haxe_to_lua = function(obj:Dynamic)
	{
		return _haxe_to_lua(obj, self.handle);
	}
}