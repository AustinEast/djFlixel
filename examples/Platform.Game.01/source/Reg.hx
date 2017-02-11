/*
 * Default REG class
 * =======================
 * Version: 01-2017
 * ---------------- *
 * 
 * You should copy-paste this file to your new Project and use this as a template.
 * Expand the functions as you like
 * 
 */

package;

import djFlixel.gapi.ApiOffline;
import djFlixel.tool.DataTool;
import flixel.FlxG;
import flixel.FlxObject;
import djFlixel.tool.DynAssets;
import djFlixel.SAVE;
import djFlixel.Controls;
import djFlixel.SND;

#if desktop
	import openfl.filters.BitmapFilter;
	import openfl.filters.BlurFilter;
#end

class Reg
{
	// -- Parameters file --
	// -  It is useful to have various game parameters to an external file
	// -  so that I don't have to compile everytime I want to change a value.
	inline static public var PARAMS_FILE:String = "data/params.json";

	// -  These vars are loaded externally from the JSON parameters file ::
	//    If the parameter is not present on the ext file, then defaults will be used.
	public static var VERSION:String = "0.1";
	public static var NAME:String = "HaxeFlixel app";
	public static var VOLUME:Float = 0.6;
	public static var MUSIC:Bool = false;
	public static var WEBSITE:String = "";
	
	// Changing this will also take effect
	public static var FULLSCREEN(default, set):Bool = false;
	// Currently Antialiasing on/off, comes with a setter that applies to all cameras
	public static var ANTIALIASING(default, set):Bool = false;
	
	// Store the json parameters loaded from the file
	public static var JSON:Dynamic;
	
	// new: Polymoprhic Api.
	public static var api:ApiOffline = null;
	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	//--
	// Do a once per program run, initialization.
	// Auto called right after the FlxGame is ready 
	// and before any state is created.
	public static function initOnce()
	{
		trace("\n  :: Initializing REG ------------ \n");
		
		#if (desktop)
			initFilters();
		#end
		
		trace("Loading and applying JSON parameters.");
		applyParamsInto("reg", Reg);
		
		// Add a state switch trigger, useful to re-set antialiasing automatically
		FlxG.signals.stateSwitched.add(onStateSwitch);
		FlxG.signals.preGameReset.add(onPreGameReset);
		FlxG.signals.postGameReset.add(onPostGameReset);
		FlxG.fullscreen = FULLSCREEN;
		FlxG.mouse.useSystemCursor = false;
		FlxG.autoPause = false;
		
		trace("Initializing Sounds.");
		FlxG.sound.volume = VOLUME;
		SND.init();
		SND.MUSIC_ENABLED = MUSIC;
		SND.VOL_MUSIC = 0.88; // Hand adjust
		SND.VOL_EFFECTS = 0.76; // Hand adjust
		SND.loadFromJSON(JSON);
		
		trace("Initializing Controls.");
		Controls.init();
		
		// -- This is the time to do it.
		// api = new ApiOffline();
		
		#if (html5)
			FlxG.drawFramerate = 60;
			trace(":: build == HTML5");
		#end
	}//---------------------------------------------------;
	
	
	
	#if desktop
	static var screenFilter:BitmapFilter;
	// Get params from JSON file and set the filter
	static function initFilters()
	{
		trace("Initializing Filters.");
		var params = DataTool.defParams(Reg.JSON.filter, { x:3.0, y:3.0, q:1 } );
		screenFilter = new BlurFilter(params.x, params.y, params.q);
		
		// Make sure no camera uses antialiasing
		for (i in FlxG.cameras.list) i.antialiasing = false;
		
		// Don't add yet! it will be auto added if needed ::
		// FlxG.game.setFilters([screenFilter]);
		
		// GLSL SHADERS :: UNUSED ::
		// add some post processing FX
		//var SHADER = new PostProcess("assets/shaders/blur.txt");
		//SHADER.setUniform("diry", 1);
		//SHADER.setUniform("dirx", 1);
		//SHADER.setUniform("radius", 1);
		//FlxG.addPostProcess(SHADER);
	}//---------------------------------------------------;
	#end

	
	//====================================================;
	// SYSTEM FUNCTIONS
	//====================================================;
	
	// --
	// Gets called after every state switch.
	static function onStateSwitch()
	{
		// Force the cameras to use the default AA (with setter)
		#if (!desktop)
			Reg.ANTIALIASING = Reg.ANTIALIASING;
		#end
	}//---------------------------------------------------;
	
	// --
	static function onPreGameReset()
	{
		SND.destroy();
	}//---------------------------------------------------;
	
	// --
	static function onPostGameReset()
	{
		// Reload the sounds!
		SND.init();
		SND.loadFromJSON(JSON);
	}//---------------------------------------------------;
	
	
	// --
	// Quick way to alter the Antialiasing of all cameras
	static function set_ANTIALIASING(value:Bool):Bool
	{
		ANTIALIASING = value;
		
		#if (desktop)
			if (ANTIALIASING) {
				FlxG.game.setFilters([screenFilter]);
			}else {
				FlxG.game.setFilters([]);
			}
			return value;
		#end
		
		for (i in FlxG.cameras.list) {
			i.antialiasing = ANTIALIASING;
		}
		
		return value;
	}//---------------------------------------------------;
	
	// --
	// Quick way to alter the Antialiasing of all cameras
	static function set_FULLSCREEN(value:Bool):Bool
	{
		FULLSCREEN = value;
		FlxG.fullscreen = FULLSCREEN;
		return value;
	}//---------------------------------------------------;	
	
	// --
	// Apply all the variables from a json node into an object
	// WARNING: FIELDS MUST HAVE THE SAME NAME!!
	// e.g. json.player.speed ==> player.speed
	public static function applyParamsInto(node:String, Object:Dynamic)
	{
		var jsonNode = Reflect.getProperty(JSON, node);
		
		for (field in Reflect.fields(jsonNode)) {
			try{
			Reflect.setField(Object, field, Reflect.field(jsonNode, field));
			}catch (e:Dynamic) {
				trace('Could not set field $field');
			}
		}
	}//---------------------------------------------------;
	

	//====================================================;
	// DEBUGGING
	//====================================================;

	#if debug
	public static function debug_keys()
	{	
		#if EXTERNAL_LOAD
		if (FlxG.keys.justPressed.F12)
		{
			trace(" = Reloading external parameters file :: ");
			DynAssets.loadFiles(function() {
					JSON = DynAssets.json.get(PARAMS_FILE);
					FlxG.resetState();
			});
		}else
		#end
		if (FlxG.keys.justPressed.F9)
		{
			ANTIALIASING = !ANTIALIASING;
		}
	}//---------------------------------------------------;
	
	// -
	// Useful tool for debugging
	public static function translateDir(dir:Int):String
	{
		return switch(dir) {
			case FlxObject.LEFT:"left";	
			case FlxObject.RIGHT:"right";	
			case FlxObject.UP:"up";	
			case FlxObject.DOWN:"down";	
			default:"";
		}
	}//---------------------------------------------------;
	#else
	
	// Inline so it will not be called at all.
	public static inline function debug_keys() { }	
	
	#end
	
}//--