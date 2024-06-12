package;

import flixel.system.FlxAssets.FlxShader;

class PCShaderGray extends FlxShader
{
    @:glFragmentSource('
        #ifdef GL_ES
        precision mediump float;
        #endif

        uniform float uTime; // Time uniform to control the desaturation

        varying vec2 vTexCoord;
        uniform sampler2D uImage0;

        void main() {
            vec4 color = texture2D(uImage0, vTexCoord);
            float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            color.rgb = mix(color.rgb, vec3(gray), uTime);
            gl_FragColor = color;
        }
    ')

    public function update(elapsed:Float)
    {
        if (this.uTime.value[0] > 1)
            return;
        
        this.uTime.value[0] += elapsed;
    }

    public function new() 
    {
        super();    

        this.uTime.value = [0];
    }    
}