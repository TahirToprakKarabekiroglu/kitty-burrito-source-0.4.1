package;

import openfl.filters.ShaderFilter;
import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ColorMatrixFilter;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class PauseXPSubState extends MusicBeatSubstate
{
    var camHUD:FlxCamera;
    var camGame:FlxCamera;
    var filter:PCShader;
    var color:ColorMatrixFilter;
    var timer:FlxTimer;

    private var grayscaleMatrix:Array<Float>;
    private var transition:Float = 0;
    var canClose:Bool = true;

    public function new(camera:FlxCamera, camHUD:FlxCamera, camGame:FlxCamera, filter:PCShader) 
    {
        super();

        this.camHUD = camHUD;
        this.camGame = camGame;
        this.filter = filter;

        grayscaleMatrix = [
            0.299, 0.587, 0.114, 0, 0,
            0.299, 0.587, 0.114, 0, 0,
            0.299, 0.587, 0.114, 0, 0,
            0, 0, 0, 1, 0
        ];

        var menu:FlxSprite = new FlxSprite();
        menu.loadGraphic(Paths.image("turnoff"));
        menu.screenCenter();
        menu.cameras = [camera];
        add(menu);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        applyColorMatrix(0);
        
        timer = new FlxTimer().start(0.3, updateTransition, 10);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.BACK)
            close();

        if (FlxG.mouse.justPressed)
        {
            if (FlxG.mouse.x >= 326 && FlxG.mouse.x <= 401 
                && FlxG.mouse.y >= 636 && FlxG.mouse.y <= 706)
            {
               close();
            }

            else if (FlxG.mouse.x >= 759 && FlxG.mouse.x <= 889 
                && FlxG.mouse.y >= 836 && FlxG.mouse.y <= 876)
            {
                close();
            }

            else if (FlxG.mouse.x >= 529 && FlxG.mouse.x <= 599 
                && FlxG.mouse.y >= 636 && FlxG.mouse.y <= 704)
            {
                FlxG.mouse.visible = false;
                CustomFadeTransition.nextCamera = camera;
                PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.leftSide = false;
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('loop'));
				PlayState.usedPractice = false;
				PlayState.changedDifficulty = false;
				PlayState.cpuControlled = false;
            }

            else if (FlxG.mouse.x >= 724 && FlxG.mouse.x <= 791 
                && FlxG.mouse.y >= 636 && FlxG.mouse.y <= 704)
            {
                CustomFadeTransition.nextCamera = camera;
                MusicBeatState.resetState();
                FlxG.sound.music.volume = 0;
            }
        }
    }

    override function close()
    {
        if (!canClose)
            return;

        super.close();
    }

    override function destroy() 
    {
        camHUD.filters = [new ShaderFilter(filter)];
        camGame.filters = [new ShaderFilter(filter)];

        if (timer != null)
        {
            if (!timer.finished)
                timer.cancel();
            timer = null;
        }

        super.destroy();
    }

    function updateTransition(timer:FlxTimer) 
    {
        transition += 0.1;
        if (transition > 1) transition = 1;
        if (transition > 0.2) canClose = true;

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

        var filter2 = new ShaderFilter(this.filter);

        camHUD.filters = [filter2, color];
        camGame.filters = [filter2, color];
    }
}