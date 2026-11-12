-- Run from the project root with Lua 5.4. Mock objects do not emulate Roblox rendering.
local function event()
    local e = {listeners = {}}
    function e:Connect(fn)
        local conn = {connected=true}; self.listeners[#self.listeners+1] = {fn=fn, c=conn}
        function conn:Disconnect() self.connected=false end
        return conn
    end
    function e:fire(...) for _,x in ipairs(self.listeners) do if x.c.connected then x.fn(...) end end end
    return e
end
local enumTypes = {}
Enum = setmetatable({}, {__index=function(t,k)
    local typ=setmetatable({}, {__index=function(a,b) local v={Name=b,Value=b=='Camera' and 100 or 1}; rawset(a,b,v); return v end})
    rawset(t,k,typ); return typ
end})
local function pair(x,y) return {X=x,Y=y} end
local vec2 = {}; vec2.__index=function(self,k) if k=='Magnitude' then return math.sqrt(self.X*self.X+self.Y*self.Y) end return vec2[k] end
vec2.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y},vec2) end
vec2.__div=function(a,b) return setmetatable({X=a.X/b,Y=a.Y/b},vec2) end
Vector2={new=function(x,y) return setmetatable({X=x,Y=y},vec2) end}
local vec={}; vec.__index=function(self,k) if k=='Magnitude' then return math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z) end return vec[k] end
vec.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vec) end
vec.__mul=function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},vec) end
vec.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vec) end
Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vec) end}
math.atan2=function(y,x) return math.atan(y,x) end
UDim={new=pair}
UDim2={new=function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end, fromOffset=function(x,y) return UDim2.new(0,x,0,y) end, fromScale=function(x,y) return UDim2.new(x,0,y,0) end}
Color3={fromRGB=function(r,g,b) return {r,g,b} end,fromHSV=function(h,s,v) return {h,s,v} end}; ColorSequence={new=function(a,b)return {} end}
math.clamp=function(v,a,b) return math.max(a,math.min(v,b)) end
function typeof(v) return type(v) end
function getgenv() return _G end
function warn(...) end
if not table.clear then function table.clear(t) for k in pairs(t) do t[k]=nil end end end
if not table.find then function table.find(t,value) for i,v in ipairs(t) do if v==value then return i end end end end
local createdObjects = {}
local function obj(class)
    local o={Visible=true,ClassName=class, AbsolutePosition=pair(0,0),AbsoluteSize=pair(100,20), Activated=event(), InputBegan=event(), InputChanged=event(), InputEnded=event()}
    function o:Destroy() self.destroyed=true end
    table.insert(createdObjects, o)
    return o
end
Instance={new=obj}
local guiParent=obj('PlayerGui')
local player={Team=nil,Character=nil}
function player:WaitForChild() return guiParent end
player.CharacterAdded=event()
function player:GetMouse() return {} end
local playerService={LocalPlayer=player}
function playerService:GetPlayers() return self.list or {player} end
local input={InputBegan=event(),InputEnded=event(),InputChanged=event(),WindowFocusReleased=event()}
function input:GetFocusedTextBox() return nil end
local run={Stepped=event()}
function run:BindToRenderStep(n,p,fn) self.render=fn end
function run:UnbindFromRenderStep(n) self.render=nil end
local services={Players=playerService,RunService=run,UserInputService=input}
game={}; function game:GetService(name) return assert(services[name],name) end
workspace={CurrentCamera=nil}; task={spawn=function(fn) end,wait=function() end}

CFrame={lookAt=function(position,target) return {position=position,target=target} end}
loadstring = load
function readfile(path)
    local suffix = path:match('^DeadlineTest/(.*)$')
    if not suffix then error('invalid test path: '..path) end
    local f = assert(io.open('./'..suffix,'rb')); local content=f:read('*a');f:close();return content
end
local ctx = assert(loadfile('./main.lua'))()
local settings = ctx.settings
local function upvalue(fn, name)
    for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
    error('upvalue missing: '..name)
end
local espEntries = upvalue(ctx.ESP.update, 'espEntries')
local teamValue = upvalue(ctx.UI.updateTeamChecker, 'teamValue')
local countValue = upvalue(ctx.UI.updateTeamChecker, 'countValue')
local panel = upvalue(ctx.UI.isMenuVisible, 'panel')
local red = {Name='Red'}; local blue = {Name='Blue'}
localPlayer = ctx.localPlayer
localPlayer.Team=red; localPlayer.Neutral=false; localPlayer.UserId=1
local hum = {Health=80, MaxHealth=100}
local anchor={Position=Vector3.new(0,0,30)}
function anchor:IsA(name) return name=='BasePart' end
local cf = {}; function cf:PointToWorldSpace(v) return Vector3.new(v.X,v.Y,v.Z+30) end
local character={PrimaryPart=anchor}
function character:FindFirstChildOfClass(name) if name=='Humanoid' then return hum end if name=='Tool' then return {Name='Rifle'} end end
function character:FindFirstChild(name) if name=='HumanoidRootPart' or name=='Head' then return anchor end end
function character:GetBoundingBox() return cf,Vector3.new(4,6,2) end
local function makePlayer(id,team,neutral)
 return {Name='User'..id,DisplayName='Display'..id,UserId=id, Team=team, Neutral=neutral, TeamColor={Color={team=team}}, Character=character}
end
local ally=makePlayer(2,red,false); local enemy=makePlayer(3,blue,false); local neutral=makePlayer(4,nil,true)
playerService.list={localPlayer,ally,enemy,neutral}
local camera={CFrame={Position=Vector3.new(0,0,0)}, ViewportSize=Vector2.new(1000,600)}
function camera:WorldToViewportPoint(v) return {X=500+v.X*10,Y=300-v.Y*10,Z=v.Z},true end
function camera:GetPartsObscuringTarget(points,ignored) return self.obstacles or {} end
workspace.CurrentCamera=camera
assert(ctx.ESP.relationOf(ally)=='Ally' and ctx.ESP.relationOf(enemy)=='Enemy' and ctx.ESP.relationOf(neutral)=='Neutral')
ctx.UI.updateTeamChecker(); assert(teamValue.Text=='Red' and countValue.Text:find('A 1') and countValue.Text:find('E 1') and countValue.Text:find('N 1'))
ctx.ESP.update(); assert(not espEntries[ally] and espEntries[enemy] and espEntries[neutral]); assert(espEntries[enemy].overlay.Visible)
assert(espEntries[enemy].topText.Text=='Display3' and espEntries[enemy].bottomText.Text=='30 studs')
settings.ESPShowAllies=true; settings.ESPShowNeutral=false; settings.ESPTeams=true; settings.ESPHealth=true; settings.ESPTool=true
settings.ESPBoxStyle='Full'; settings.ESPTracer='Top'; settings.ESPHighlight='Outline'; settings.ESPDepth='Occluded'
ctx.ESP.update(); assert(espEntries[ally] and not espEntries[neutral] and espEntries[enemy])
assert(espEntries[enemy].topText.Text:find('Blue') and espEntries[enemy].bottomText.Text:find('80 HP') and espEntries[enemy].bottomText.Text:find('Rifle'))
assert(espEntries[enemy].tracer.Visible and espEntries[enemy].highlight.FillTransparency==1 and espEntries[enemy].highlight.DepthMode==Enum.HighlightDepthMode.Occluded)
settings.ESPVisibleOnly=true; camera.obstacles={1}; ctx.ESP.update(); assert(next(espEntries)==nil)
camera.obstacles={}; settings.ESPVisibleOnly=false; hum.Health=0; ctx.ESP.update(); assert(next(espEntries)==nil)
settings.ESPAliveOnly=false; ctx.ESP.update(); assert(espEntries[enemy])
local before=espEntries[enemy]; enemy.Character=nil; ctx.ESP.update(); assert(not espEntries[enemy] and before.overlay.destroyed and before.highlight.destroyed and before.tracer.destroyed)
localPlayer.Team=nil; localPlayer.Neutral=true; assert(ctx.ESP.relationOf(ally)=='Neutral' and ctx.ESP.currentTeamName(localPlayer)=='Neutral / no team')
settings.ESP=false; ctx.ESP.update(); assert(next(espEntries)==nil)
settings.ESP=true; settings.ESPShowNeutral=true; ctx.ESP.update(); assert(espEntries[ally])
local function press(code,processed)
 local e={UserInputType=Enum.UserInputType.Keyboard,KeyCode=code}
 if code==Enum.UserInputType.MouseButton2 then e.UserInputType=code end
 input.InputBegan:fire(e,processed or false); return e
end
assert(ctx.UI.isMenuVisible()); press(Enum.KeyCode.RightShift);assert(not ctx.UI.isMenuVisible())
local value=settings.ESP; press(Enum.KeyCode.F6);assert(settings.ESP==value)
local mouse=press(Enum.UserInputType.MouseButton2,true);assert(ctx.UI.isAimActive())
input.InputEnded:fire(mouse);assert(not ctx.UI.isAimActive())
settings.AimMode='Toggle';press(Enum.UserInputType.MouseButton2);assert(ctx.UI.isAimActive())
input.WindowFocusReleased:fire();assert(not ctx.UI.isAimActive())
-- Exercise actual menu control callbacks, not only underlying settings.
local function controlFor(title)
    local card
    for _,o in ipairs(createdObjects) do if o.ClassName == "TextLabel" and o.Text == title then card=o.Parent; break end end
    assert(card, "missing UI card: "..title)
    for _,o in ipairs(createdObjects) do if o.Parent==card and o.ClassName=="TextButton" then return o end end
    error("missing control: "..title)
end
press(Enum.KeyCode.RightShift); assert(ctx.UI.isMenuVisible())
local espBind=controlFor("Toggle ESP"); espBind.Activated:fire(); press(Enum.KeyCode.K); assert(espBind.Text=="K")
local aimBind=controlFor("Toggle aimbot"); aimBind.Activated:fire(); press(Enum.KeyCode.K);assert(espBind.Text=="Unbound" and aimBind.Text=="K")
local highlightControl=controlFor("Highlight style");local oldStyle=settings.ESPHighlight;highlightControl.Activated:fire();assert(settings.ESPHighlight~=oldStyle)
local distControl=controlFor("ESP distance");distControl.InputBegan:fire({UserInputType=Enum.UserInputType.MouseButton1,Position={X=50}});assert(settings.ESPMaxDistance==1525)
input.InputEnded:fire({UserInputType=Enum.UserInputType.MouseButton1})
press(Enum.KeyCode.RightShift);assert(not ctx.UI.isMenuVisible())
local oldAim=settings.Aimbot;press(Enum.KeyCode.K);assert(settings.Aimbot~=oldAim)
settings.Aimbot=true
-- Verify modular targeting reacts to aim activation, and menu-open blocks camera movement.
hum.Health=80; enemy.Character=character; anchor.AssemblyLinearVelocity=Vector3.new(0,0,0)
local cframe = camera.CFrame; cframe.lerps=0
function cframe:Lerp(target,alpha) self.lerps=self.lerps+1; assert(alpha>0 and alpha<=1); return self end
ctx.Aim.step(1/60,true,false,false); assert(cframe.lerps>0)
local previous=cframe.lerps;ctx.Aim.step(1/60,true,true,false);assert(cframe.lerps==previous)
local originalCleanup=env and env.TestClientCleanup or _G.TestClientCleanup
-- Failed module reads must not unload an existing client.
local originalRead=readfile;readfile=function(path) error('missing') end
local good,err=pcall(assert(loadfile('./main.lua')))
assert(not good and tostring(err):find('Cannot read') and _G.TestClientCleanup==originalCleanup)
readfile=originalRead
_G.TestClientCleanup(); assert(next(espEntries)==nil and ctx.espLayer.destroyed and ctx.gui.destroyed and run.render==nil)
print('Modular runtime: loading, ESP, teams, aim bindings, cleanup and failed reload PASS')
