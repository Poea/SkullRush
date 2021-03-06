package ;
import flash.text.TextFormat;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.text.FlxTextField;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.events.Event;

/**
 * ...
 * @author Ohmnivore
 */
class ChatBox extends FlxSpriteGroup
{
	public var opened(get, set):Bool;
	private var _opened:Bool;
	
	private function get_opened():Bool
	{
		return _opened;
	}

	private function set_opened(Value:Bool):Bool
	{ 
		if (Value)
		{
			open();
		}
		else
		{
			close();
		}
		return _opened;
	}
	
	public var text:FlxInputText;
	public var background:FlxSprite;
	
	public var callback:Void->Void;
	
	private var tot_height:Float;
	private var texts:FlxSpriteGroup;
	
	public function new() 
	{
		super(0, 0, 6);
		scrollFactor.set();
		
		_opened = true;
		
		text = new FlxInputText(0, 0, FlxG.width, null, 8);
		text.callback = _call;
		text.hasFocus = true;
		text.textField.multiline = false;
		text.textField.addEventListener(Event.CHANGE,
		function test_change(e:Event)
		{
			text.text = StringTools.replace(text.text, "\r", "");
		}
		);
		
		background = new FlxSprite(0, text.height);
		background.makeGraphic(FlxG.width, Std.int(text.height * 4), 0x99000000);
		
		texts = new FlxSpriteGroup(0, text.height, 10);
		
		add(background);
		add(text);
		add(texts);
		
		tot_height = background.height + text.height;
		
		y += FlxG.height - tot_height;
		
		toggle();
	}
	
	public function addMsg(T:String, Color:Int):Void
	{
		var markup_index:Int = T.indexOf(":");
		
		var cur_text:FlxText = new FlxText(0, 0, FlxG.width, T);
		cur_text.addFormat(new FlxTextFormat(Color, 0, markup_index), 0, markup_index);
		cur_text.alpha = 0;
		FlxTween.tween(cur_text, { alpha:1 }, 1, {type:FlxTween.ONESHOT, ease:FlxEase.cubeIn});
		
		var last_text:FlxText = cur_text;
		for (i in texts.members.iterator())
		{
			var t:FlxText = cast (i, FlxText);
			t.y += cur_text.height;
			
			if (t.y > last_text.y)
				last_text = t;
		}
		
		if (texts.members.length > 5)
		{
			texts.remove(last_text, true);
		}
		
		texts.add(cur_text);
	}
	
	public function _call(Text:String, Action:String):Void
	{
		if (Action == FlxInputText.ENTER_ACTION)
		{
			if (callback != null)
				callback();
		}
	}
	
	public function open():Void
	{
		if (!opened)
			toggle();
	}
	
	public function close():Void
	{
		if (opened)
			toggle();
	}
	
	public function toggle():Void
	{
		if (opened)
		{
			text.hasFocus = false;
			text.visible = false;
			//y += text.height * 2;
			//FlxTween.tween(text, {alpha:0}, 1);
			FlxTween.tween(this, {y:FlxG.height - tot_height + text.height * 2}, 1, {type:FlxTween.ONESHOT, ease:FlxEase.quadIn});
		}
		
		else
		{
			text.hasFocus = true;
			text.visible = true;
			//y -= text.height * 2;
			FlxTween.tween(this, {y:FlxG.height - tot_height}, 1, {type:FlxTween.ONESHOT, ease:FlxEase.quadIn});
		}
		
		_opened = !_opened;
	}
}