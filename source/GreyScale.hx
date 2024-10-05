package;

import flixel.tweens.FlxTween;
import openfl.filters.ColorMatrixFilter;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.util.FlxTimer;

class GreyScale extends FlxObject
{
    var camHUD:FlxCamera;
    var camGame:FlxCamera;
    var color:ColorMatrixFilter;
    var timer:FlxTimer;

    private var grayscaleMatrix:Array<Float>;
    public var transition(default, set):Float = 0;

    public function new(camHUD:FlxCamera, camGame:FlxCamera) 
    {
        super();

        this.camHUD = camHUD;
        this.camGame = camGame;

        grayscaleMatrix = [
            0.299, 0.587, 0.114, 0, 0,
            0.299, 0.587, 0.114, 0, 0,
            0.299, 0.587, 0.114, 0, 0,
            0, 0, 0, 1, 0
        ];

        applyColorMatrix(0);
    }

    override function destroy() 
    {
        if (timer != null)
        {
            if (!timer.finished)
                timer.cancel();
            timer = null;
        }

        super.destroy();
    }

    function updateTransition() 
    {
        if (transition > 1) transition = 1;
        applyColorMatrix(transition);
    }

    function applyColorMatrix(transition:Float) 
    {
        if (color == null)
            color = new ColorMatrixFilter();

        var currentMatrix:Array<Float> = [
            (1 - transition) + grayscaleMatrix[0] * transition, grayscaleMatrix[1] * transition, grayscaleMatrix[2] * transition, 0, 0,
            grayscaleMatrix[5] * transition, (1 - transition) + grayscaleMatrix[6] * transition, grayscaleMatrix[7] * transition, 0, 0,
            grayscaleMatrix[10] * transition, grayscaleMatrix[11] * transition, (1 - transition) + grayscaleMatrix[12] * transition, 0, 0,
            0, 0, 0, 1, 0
        ];
        color.matrix = currentMatrix;

        camHUD.filters = [color];
        camGame.filters = [color];
    }

    function set_transition(value:Float):Float 
    {
        transition = value;
        updateTransition();
        return value;
    }
}