package djFlixel.gui;

import djFlixel.SimpleCoords;
import djFlixel.SimpleVector;
import djFlixel.tool.DEST;
import djFlixel.tool.DataTool;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import djFlixel.gfx.Palette_DB32 as DB32;
import flixel.tweens.misc.VarTween;



/**
 * Simple non-modal notification that slides into the screen from the edge
 * and then auto-hides. Customizable colors, width, duration, etc.
 * 
 * @author John Dimi
 */
class Toast extends FlxSpriteGroup
{
	// Default width
	public var WIDTH(default, null):Int;
	// HEIGHT is autogenerated from text height
	public var HEIGHT(default, null):Int;
	
	// Offset position for the whole box, you can directly alter this
	public var offsetPos:SimpleCoords;
	
	// Keep some text Formats:
	var textFormats:Array<FlxTextFormatMarkerPair> = [];
	
	// -- Visual Elements
	var text:FlxText;
	var bg:FlxSprite;
	
	// When animating, start and end to these positions
	var animStartPoint:SimpleVector;
	var animEndPoint:SimpleVector;
	
	// Store the tween for future reference
	var animTween:VarTween;
	
	// Running Parameters
	var P:Dynamic;
	
	//====================================================;

	/**
	 * @param	_width  Set the width of the toast box
	 * @param	_alignX left,center,right
	 * @param	_alignY top,bottom
	 */
	public function new(?params:Dynamic)
	{
		super();
		
		// Set the default parameters
		P = DataTool.copyFieldsC(params, {
			width  : 0,				// Width of the whole notification, 0 for auto (careful for long lines)
			alignY : "top",			// top | bottom
			alignX : "center",		// left| center | right
			timeTween : 0.4,		// Time it takes to tween
			timeOn	  : 3,			// Time it stays on screen
			padding   : 4,			// Text padding to edges
			
			easeIn  : "elasticOut",	// Name of EaseFunction for when going in
			easeOut : "circIn",		// Name of EaseFunction for when going out
			
			color   : DB32.COL[22],	// Text color
			colorBG : DB32.COL[2],	// Background color
			
			colorT1 : DB32.COL[8],
			colorT2 : DB32.COL[19],
			
			alpha:1,	//	Alpha of the background
			
			alignText:	"left"
			
		});
		
		visible = false;
		
		scrollFactor.set(0, 0);
		
		// - Create the bg
		// : note : no graphic yet, it will be created later.
		bg = new FlxSprite();
		bg.moves = false;
		bg.alpha = P.alpha;
		add(bg);
		
		// - Create the text
		text = new FlxText(P.padding, P.padding);
		text.color = P.color;
		text.alignment = P.alignText;
		text.moves = false;
		add(text);
		// --
		animStartPoint = new SimpleVector();
		animEndPoint = new SimpleVector();
		offsetPos = new SimpleCoords(4, 4); // Default 4 pixels offset from the edges
		
		// Set a couple of default textformat colors
		setTagColors(P.colorT1, P.colorT2);
		
	}//---------------------------------------------------;
	
	
	/**
	 * Supports two text format colors
	 * @param	color1 Color used with the "#" Tag
	 * @param	color2 Color used with the "$" Tag
	 */
	public function setTagColors(color1:Int, color2:Int)
	{
		textFormats = [ 
			Gui.getFormatRule("#",color1),
			Gui.getFormatRule("$",color2),
		];
	}//---------------------------------------------------;
	
	/**
	 * Force the toast to offscreen with an animation
	 */
	public function hide()
	{
		throw "Not Implemented yet";
	}//---------------------------------------------------;
	
	// --
	override public function destroy():Void 
	{
		animTween = DEST.tween(animTween);
		super.destroy();
	}//---------------------------------------------------;
	
	/**
	 * Fire the toast with text
	 * @param	TXT Markup styles [ # , $ ]
	 * @param	params You can override some parameters ( alignX, alignY, timeTween, timeOn, colorBG, easeOut, easeIn)
	 * 
	 */
	public function fire(TXT:String, ?params:Dynamic)
	{
		animTween = DEST.tween(animTween);
		
		// Current Running Parameters
		var RP:Dynamic;
		
		// Create a temp merge of params and global params
		if (params != null){
			RP = DataTool.copyFields(params, Reflect.copy(P));
		}else{
			RP = P; //else point to the global params
		}
		
		// -- Set the new content
		
		WIDTH = RP.width;
		
		if (WIDTH < 8) {
			text.fieldWidth = 0;
		}else{
			text.fieldWidth = WIDTH;
		}
		
		text.applyMarkup(TXT, textFormats);
		
		WIDTH = Std.int(text.width + (RP.padding * 2));
		HEIGHT = Std.int(text.height + (RP.padding * 2));
		
		bg.makeGraphic(WIDTH, HEIGHT, RP.colorBG);
		
		text.applyMarkup(TXT, textFormats);
		
		// - Figure out the start and endpoints for the x and y axis
		switch(RP.alignX) {
			case "left"	:
				animEndPoint.x = 0 + offsetPos.x;
				animStartPoint.x = animEndPoint.x;
			case "right":
				animEndPoint.x = FlxG.width - WIDTH - offsetPos.x;
				animStartPoint.x = animEndPoint.x;
			case "center":
				animEndPoint.x = (FlxG.width / 2) - (WIDTH / 2);
				animStartPoint.x = animEndPoint.x;
			default:
				throw "Alignment is not defined !!";
		}
		
		switch(RP.alignY) {
			case "top":
				animEndPoint.y = 0 + offsetPos.y;
				animStartPoint.y = -HEIGHT + offsetPos.y;
			case "bottom":
				animEndPoint.y = FlxG.height - HEIGHT - offsetPos.y;
				animStartPoint.y = animEndPoint.y + HEIGHT + offsetPos.y;
			default:
				throw "Alignment is not defined !!";				
		}
	
		// - Start the tween
		
		this.x = animStartPoint.x;
		this.y = animStartPoint.y;
		this.visible = true;
		
		animTween = FlxTween.tween(this, { x:animEndPoint.x, y:animEndPoint.y }, RP.timeTween, {
				ease:Reflect.field(FlxEase,RP.easeIn), 
				onComplete: function(e:FlxTween) {
					// When the toast is on, wait X seconds and anim out
					animTween = FlxTween.tween(this, 
						{ x:animStartPoint.x, y:animStartPoint.y }, RP.timeTween, {
						  ease:Reflect.field(FlxEase,RP.easeOut),
						  startDelay:RP.timeOn,
						  onComplete:function(e:FlxTween) {
							this.visible = false;
							animTween = DEST.tween(animTween);
						}});					
				}// --
			});
	}//---------------------------------------------------;
	
	
}// -- end