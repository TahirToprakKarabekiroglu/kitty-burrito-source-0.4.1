package;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.utils.Assets;
import flixel.FlxG;
import openfl.Lib;
import flixel.math.FlxPoint;

class PCEffect
{
  public var shader:PCShader = new PCShader();
  public function new(){
    shader.iTime.value = [0];
    shader.vignetteOn.value = [true];
    shader.perspectiveOn.value = [true];
    shader.distortionOn.value = [false];
    shader.scanlinesOn.value = [false];
    shader.vignetteMoving.value = [false];
    shader.noiseOn.value = [false];
    shader.glitchModifier.value = [0];
    shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
    var noise = null;
    shader.noiseTex.input = noise;
    shader.curvateOn.value = [false];
  }

  public function update(elapsed:Float){
    shader.iTime.value[0] += elapsed;
    shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
  }

  public function setCurvate(state:Bool){
    shader.curvateOn.value[0] = state;
  }

  public function setVignette(state:Bool){
    shader.vignetteOn.value[0] = state;
  }

  public function setNoise(state:Bool){
    shader.noiseOn.value[0] = state;
  }

  public function setPerspective(state:Bool){
    shader.perspectiveOn.value[0] = state;
  }

  public function setGlitchModifier(modifier:Float){
    shader.glitchModifier.value[0] = modifier;
  }

  public function setDistortion(state:Bool){
    shader.distortionOn.value[0] = state;
  }

  public function setScanlines(state:Bool){
    shader.scanlinesOn.value[0] = state;
  }

  public function setVignetteMoving(state:Bool){
    shader.vignetteMoving.value[0] = state;
  }
}

class PCShader extends FlxShader
{

  @:glFragmentSource('
  #pragma header

  uniform float iTime;
  uniform bool vignetteOn;
  uniform bool perspectiveOn;
  uniform bool distortionOn;
  uniform bool scanlinesOn;
  uniform bool vignetteMoving;
  uniform sampler2D noiseTex;
  uniform float glitchModifier;
  uniform vec3 iResolution;
  uniform bool noiseOn;
  uniform bool curvateOn;
  
  vec2 rotate(vec2 v, float a) {
      float s = sin(a);
      float c = cos(a);
      mat2 m = mat2(c, -s, s, c);
      return m * v;
  }
  
  vec2 vCrtCurvature(vec2 uv, float q, float daValues) {
      if (curvateOn) {
          return uv + (vec2(daValues, daValues) - uv) * (daValues - distance(uv, vec2(daValues, daValues))) * q;
      } else {
          return uv;
      }
  }
  
  float onOff(float a, float b, float c) {
      return step(c, sin(iTime + a * cos(iTime * b)));
  }
  
  vec2 screenDistort(vec2 uv) {
      if (perspectiveOn) {
          uv = (uv - 0.5) * 2.0;
          uv *= 1.2; // Reduced from 1.3 to 1.1
          uv.x *= 1.0 + pow((abs(uv.y) / 8.0), 2.0); // Reduced distortion
          uv.y *= 1.0 + pow((abs(uv.x) / 6.0), 2.0); // Reduced distortion
          uv = (uv / 2.0) + 0.5;
          uv = uv * 0.96 + 0.02; // Adjusted from 0.92 + 0.04
          return uv;
      }
      return uv;
  }
  
  float random(vec2 uv) {
      return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
  }
  
  float noise(vec2 uv) {
      vec2 i = floor(uv);
      vec2 f = fract(uv);
  
      float a = random(i);
      float b = random(i + vec2(1., 0.));
      float c = random(i + vec2(0., 1.));
      float d = random(i + vec2(1.));
  
      vec2 u = smoothstep(0., 1., f);
  
      return mix(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
  }
  
  vec2 scandistort(vec2 uv) {
      float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
      float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0);
      float amount = scan1 * scan2 * uv.x * 0.5; // Halved the amount of distortion
  
      uv = uv * 2.0 - 1.0;
      uv *= 0.95; // Reduced from 0.9 to 0.95
      uv = (uv + 1.0) * 0.5;
  
      uv.x -= 0.03 * mix(texture2D(noiseTex, vec2(uv.x, amount)).r * amount, amount, 0.9); // Reduced the distortion effect
  
      return uv;
  }
  
  void main() {
      vec2 uv = openfl_TextureCoordv;
      vec2 uvB = vCrtCurvature(uv, 0.5, 0.5);
      vec2 curUV = screenDistort(uvB);
      uv = scandistort(curUV);
  
      if (curUV.x < 0 || curUV.x > 1 || curUV.y < 0 || curUV.y > 1) {
          gl_FragColor = vec4(0, 0, 0, 0);
      } else {
          vec4 video = texture2D(bitmap, uv);
  
          // Simulate old monitor effect
          float luminance = dot(video.rgb, vec3(0.2126, 0.7152, 0.0722));
          video.rgb = mix(vec3(luminance), video.rgb, 0.8); // Desaturate
          video.rgb = pow(video.rgb, vec3(0.8)); // Apply gamma correction
  
          gl_FragColor = video;
      }
  }
  
  ')
  public function new()
  {
    super();
  }
}