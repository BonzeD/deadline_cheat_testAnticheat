-- Mock-only timing, filtering, failure, and cleanup checks.
local make=assert(loadfile('src/trigger/init.lua'))()
local count=0;mouse1click=function() count=count+1 end
local localTeam,otherTeam={},{}
local player={Team=localTeam};local mouse={};function player:GetMouse() return mouse end
local human={Health=100};local root={Position={Magnitude=50},IsA=function(_,t) return t=='BasePart' end}
local character={};function character:FindFirstChildOfClass(n) if n=='Humanoid' then return human end end
function character:FindFirstChild(n) if n=='HumanoidRootPart' then return root end end
local other={Team=otherTeam,Character=character};local hit={};function hit:IsDescendantOf(c) return c==character end
local players={GetPlayers=function() return {player,other} end}
local settings=assert(loadfile('src/trigger/settings.lua'))()
local context={settings=settings,localPlayer=player,Players=players,running=true,setStatus=function() end}
local camera={CFrame={Position={}}};workspace={CurrentCamera=camera}
setmetatable(root.Position,{__sub=function(a,b) return {Magnitude=a.Magnitude} end})
local t=make(context); assert(not t.isEnabled());t.toggle();assert(t.isEnabled())
mouse.Target=hit
local function step(now,menu,focused,aim,window) t.step(now,menu or false,focused or false,aim~=false,window~=false) end
step(1);assert(count==0);step(1.14);assert(count==0);step(1.16);assert(count==1)
step(1.25);assert(count==1);step(1.37);assert(count==2)
step(2,true);step(3);assert(count==2);step(3.16);assert(count==3)
step(4,false,true);step(5,false,false,false);step(6,false,false,true,false);assert(count==3)
other.Team=localTeam;step(7);step(8);assert(count==3)
settings.TriggerTeamCheck=false;step(9);step(9.16);assert(count==4)
settings.TriggerTeamCheck=true;other.Team=otherTeam;human.Health=0;step(10);human.Health=100
root.Position.Magnitude=900;step(11);assert(count==4);root.Position.Magnitude=50
settings.TriggerActivation='Always';step(12,false,false,false);step(12.16,false,false,false);assert(count==5)
mouse1click=function() error('failed') end;step(13);assert(not t.isEnabled())
mouse1click=function() count=count+1 end;t.toggle();t.respawn();assert(not t.isEnabled())
t.toggle();t.cleanup();assert(not t.isEnabled());mouse1click=nil;t.toggle();assert(not t.isEnabled())
print('Trigger mocks: timing, target filters, focus, error and lifecycle PASS')
