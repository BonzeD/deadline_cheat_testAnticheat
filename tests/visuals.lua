local function color(r,g,b) return setmetatable({r=r,g=g,b=b},{__eq=function(a,b) return a.r==b.r and a.g==b.g and a.b==b.b end}) end
Color3={fromRGB=color,fromHSV=color};Vector2={new=function(x,y)return {X=x,Y=y}end}
UDim2={fromScale=function(x,y)return {X=x,Y=y}end,fromOffset=function(x,y)return {X=x,Y=y}end}
math.clamp=function(x,a,b)return math.min(math.max(x,a),b)end
local created={};Instance={new=function(kind) local o={ClassName=kind};function o:Destroy()self.destroyed=true end;table.insert(created,o);return o end}
local original=color(10,10,10);local lighting={Ambient=original,OutdoorAmbient=original,Brightness=1,FogEnd=100}
game={GetService=function(_,name)assert(name=='Lighting');return lighting end}
local settings=assert(loadfile('src/visuals/settings.lua'))();local ctx={settings=settings,localPlayer={WaitForChild=function()return {} end},setStatus=function()end}
local v=assert(loadfile('src/visuals/init.lua'))()(ctx);local cam={FieldOfView=70}
assert(not settings.CrosshairEnabled);v.toggle('CrosshairEnabled','Cross');settings.CrosshairShape='Cross+Dot';settings.CrosshairSpin=true
settings.FullbrightEnabled=true;settings.NoFogEnabled=true;settings.CameraFOVEnabled=true
v.step(.1,cam); assert(created[2].Visible and created[3].Rotation==9 and created[3].Position.Y~=0 and created[7].Visible)
assert(lighting.Brightness==4 and lighting.FogEnd==1000000 and cam.FieldOfView==80)
settings.CrosshairSpin=false;v.step(.1,cam);assert(created[3].Rotation==0 and created[3].Position.Y==0)
settings.CrosshairSpin=true
lighting.Brightness=3;cam.FieldOfView=65;v.step(.1,cam);assert(lighting.Brightness==4 and cam.FieldOfView==80)
settings.FullbrightEnabled=false;settings.NoFogEnabled=false;settings.CameraFOVEnabled=false;v.step(.1,cam)
assert(lighting.Brightness==3 and lighting.FogEnd==100 and cam.FieldOfView==65 and lighting.Ambient==original)
settings.CameraFOVEnabled=true;v.step(.1,cam);local nextCam={FieldOfView=60};v.step(.1,nextCam);assert(cam.FieldOfView==65 and nextCam.FieldOfView==80)
v.cleanup();assert(nextCam.FieldOfView==60 and created[1].destroyed and not settings.CrosshairEnabled)
print('Visual mocks: crosshair, lighting, camera replacement, restore and cleanup PASS')
