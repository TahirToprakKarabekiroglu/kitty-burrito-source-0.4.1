package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class CheckboxThingie extends FlxSpriteGroup
{
	var unchecked:FlxSprite;
	var checked:FlxSprite;

	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;
	public function new(x:Float = 0, y:Float = 0, ?checked = false) {
		super(x, y);

		unchecked = new FlxSprite().loadGraphic(Paths.image('checkbox'));
		add(unchecked);

		this.checked = new FlxSprite().loadGraphic(Paths.image("checkbox_checked"));
		add(this.checked);

		antialiasing = false;
		daValue = checked;
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 10);

		super.update(elapsed);
	}

	private function set_daValue(value:Bool):Bool {
		unchecked.visible = value;
		checked.visible = !value;

		return daValue = value;
	}
}