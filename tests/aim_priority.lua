-- Mock test of the independently implemented selection priorities and offset.
local v3={};v3.__index=function(v,k)if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end end
v3.__add=function(a,b)return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},v3)end
v3.__sub=function(a,b)return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},v3)end
v3.__mul=function(a,n)return setmetatable({X=a.X*n,Y=a.Y*n,Z=a.Z*n},v3)end
Vector3={new=function(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},v3)end}
local v2={};v2.__index=function(v,k)if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y)end end
v2.__sub=function(a,b)return setmetatable({X=a.X-b.X,Y=a.Y-b.Y},v2)end
v2.__div=function(a,b)return setmetatable({X=a.X/b,Y=a.Y/b},v2)end
Vector2={new=function(x,y)return setmetatable({X=x,Y=y},v2)end}
math.clamp=function(x,a,b)return math.min(math.max(x,a),b)end
local localPlayer={Team='A'}; local function target(id,x,z,h)
 local part={Position=Vector3.new(x,0,z),AssemblyLinearVelocity=Vector3.new(0,0,0)}; function part:IsA(name)return name=='BasePart'end
 local hum={Health=h};local character={};part.Parent=character
 function character:FindFirstChildOfClass(name)if name=='Humanoid'then return hum end end
 function character:FindFirstChild(name)if name=='Head'then return part end end
 return {Name=id,Team='B',Character=character},part
end
local a,pa=target('screen',1,100,100);local b,pb=target('near',5,20,50);local c,pc=target('weak',10,80,10)
local players={GetPlayers=function()return {localPlayer,a,b,c}end}
local settings=assert(loadfile('src/aim/settings.lua'))();settings.WallCheck=false;settings.Smoothness=1
local cframe={Position=Vector3.new(0,0,0)};function cframe:Lerp(target,alpha)self.target=target;return self end
local cam={CFrame=cframe,ViewportSize=Vector2.new(1000,600)}
function cam:WorldToViewportPoint(p)return {X=500+p.X,Y=300,Z=p.Z},true end
workspace={CurrentCamera=cam};CFrame={lookAt=function(_,p)return p end}
local ctx={Players=players,localPlayer=localPlayer,settings=settings,env={},running=true,setStatus=function()end}
local aim=assert(loadfile('src/aim/init.lua'))()(ctx)
for _,case in ipairs({{'Screen',pa},{'Distance',pb},{'Health',pc}})do
 settings.AimPriority=case[1];aim.reset();aim.step(0.016,true,false,false);assert(cframe.target==case[2].Position or (cframe.target.X==case[2].Position.X and cframe.target.Z==case[2].Position.Z))
end
settings.AimVerticalOffset=2;aim.step(.016,true,false,false);assert(cframe.target.Y==2)
print('Aim mocks: screen, distance, health priorities and vertical offset PASS')
