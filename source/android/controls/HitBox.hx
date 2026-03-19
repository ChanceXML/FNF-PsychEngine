package android.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.math.FlxPoint;

typedef HitboxCallback = {
    var callback:Void->Void;
}

class HitBox extends FlxSpriteGroup {
    public var hitboxCamera:FlxCamera;

    public var buttonLeft:HitboxButton;
    public var buttonDown:HitboxButton;
    public var buttonUp:HitboxButton;
    public var buttonRight:HitboxButton;

    public function new() {
        super();

        var w:Int = Std.int(FlxG.width / 4);
        var h:Int = Std.int(FlxG.height);

        hitboxCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        hitboxCamera.bgColor = 0x00000000;
        hitboxCamera.alpha = 1;
        
        buttonLeft = new HitboxButton(0, 0, w, h, 0xFFC24B99, hitboxCamera);
        buttonDown = new HitboxButton(w, 0, w, h, 0xFF00FFFF, hitboxCamera);
        buttonUp = new HitboxButton(w * 2, 0, w, h, 0xFF12FA05, hitboxCamera);
        buttonRight = new HitboxButton(w * 3, 0, w, h, 0xFFF9393F, hitboxCamera);

        add(buttonLeft);
        add(buttonDown);
        add(buttonUp);
        add(buttonRight);

        for (button in [buttonLeft, buttonDown, buttonUp, buttonRight]) {
            button.cameras = [hitboxCamera];
            button.scrollFactor.set(0, 0);
        }

        this.scrollFactor.set(0, 0);
    }

    public function setupCamera():Void {
        if (!FlxG.cameras.list.contains(hitboxCamera)) {
            FlxG.cameras.add(hitboxCamera, false);
        }
    }

    override public function destroy():Void {
        super.destroy();
        if (FlxG.cameras.list.contains(hitboxCamera)) {
            FlxG.cameras.remove(hitboxCamera);
        }
    }

    public static function BACK():Bool {
        return #if android FlxG.android.justReleased.BACK #else false #end;
    }
}

class HitboxButton extends FlxSprite {
    public var onDown:HitboxCallback = {callback: null};
    public var onUp:HitboxCallback = {callback: null};
    public var onOut:HitboxCallback = {callback: null};

    public var isPressed:Bool = false;
    public var justPressed:Bool = false;
    public var justReleased:Bool = false;
    private var _wasPressed:Bool = false;

    private var _assignedCamera:FlxCamera;
    private var _touchPoint:FlxPoint = new FlxPoint();

    public function new(x:Float, y:Float, width:Int, height:Int, color:FlxColor, camera:FlxCamera) {
        super(x, y);
        
        _assignedCamera = camera;
        
        makeGraphic(width, height, color);
        alpha = 0.00001;
        antialiasing = false;
    }

    override public function update(elapsed:Float) {
        _wasPressed = isPressed;
        isPressed = false;

        checkInputs();

        justPressed = isPressed && !_wasPressed;
        justReleased = !isPressed && _wasPressed;

        if (justPressed) {
            if (onDown.callback != null) onDown.callback();
        } 
        else if (justReleased) {
            if (onUp.callback != null) onUp.callback();
            if (onOut.callback != null) onOut.callback();
        }

        alpha = isPressed ? 0.25 : 0.00001;

        super.update(elapsed);
    }

    private function checkInputs():Void {
        #if FLX_TOUCH
        for (touch in FlxG.touches.list) {
            touch.getWorldPosition(_assignedCamera, _touchPoint);
            if (overlapPointCheck(_touchPoint)) {
                isPressed = true;
                return;
            }
        }
        #end

        #if FLX_MOUSE
        if (FlxG.mouse.pressed) {
            FlxG.mouse.getWorldPosition(_assignedCamera, _touchPoint);
            if (overlapPointCheck(_touchPoint)) {
                isPressed = true;
            }
        }
        #end
    }

    private function overlapPointCheck(point:FlxPoint):Bool {
        return (point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height);
    }

    override public function destroy():Void {
        _touchPoint = null;
        super.destroy();
    }
}
