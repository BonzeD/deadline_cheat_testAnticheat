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
local testMouse={}
function player:GetMouse() return testMouse end
local playerService={LocalPlayer=player}
function playerService:GetPlayers() return self.list or {player} end
local input={InputBegan=event(),InputEnded=event(),InputChanged=event(),WindowFocusReleased=event(),WindowFocused=event(),JumpRequest=event()}
function input:GetFocusedTextBox() return nil end
local run={Stepped=event(),Heartbeat=event()}
function run:BindToRenderStep(n,p,fn) self.render=fn end
function run:UnbindFromRenderStep(n) self.render=nil end
local lighting={Ambient=Color3.fromRGB(10,10,10),OutdoorAmbient=Color3.fromRGB(20,20,20),Brightness=1,FogEnd=100}
local services={Players=playerService,RunService=run,UserInputService=input,Lighting=lighting}
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
local boundingCalls = 0
function character:GetBoundingBox() boundingCalls=boundingCalls+1; return cf,Vector3.new(4,6,2) end
local function makePlayer(id,team,neutral)
 return {Name='User'..id,DisplayName='Display'..id,UserId=id, Team=team, Neutral=neutral, TeamColor={Color={team=team}}, Character=character}
end
local ally=makePlayer(2,red,false); local enemy=makePlayer(3,blue,false); local neutral=makePlayer(4,nil,true)
playerService.list={localPlayer,ally,enemy,neutral}
local camera={CFrame={Position=Vector3.new(0,0,0)}, ViewportSize=Vector2.new(1000,600)}
function camera:WorldToViewportPoint(v) return {X=500+(self.shiftX or 0)+v.X*10,Y=300-v.Y*10,Z=v.Z},true end
function camera:GetPartsObscuringTarget(points,ignored) return self.obstacles or {} end
workspace.CurrentCamera=camera
assert(ctx.ESP.relationOf(ally)=='Ally' and ctx.ESP.relationOf(enemy)=='Enemy' and ctx.ESP.relationOf(neutral)=='Neutral')
ctx.UI.updateTeamChecker(); assert(teamValue.Text=='Red' and countValue.Text:find('A 1') and countValue.Text:find('E 1') and countValue.Text:find('N 1'))
ctx.ESP.update(); assert(not espEntries[ally] and espEntries[enemy] and espEntries[neutral]); assert(espEntries[enemy].overlay.Visible)
assert(espEntries[enemy].topText.Text=='Display3' and espEntries[enemy].bottomText.Text=='30 studs')
-- 2D geometry moves with camera and root between slow scans, without another bounds query.
local xBefore=espEntries[enemy].overlay.Position.X.Offset
local callsBefore=boundingCalls
camera.shiftX=40; anchor.Position=Vector3.new(2,0,30)
ctx.ESP.render(camera, 0.001); assert(espEntries[enemy].overlay.Position.X.Offset==xBefore)
ctx.ESP.render(camera, 0.02); assert(espEntries[enemy].overlay.Position.X.Offset==xBefore+60)
assert(boundingCalls==callsBefore)
-- Highlight-only mode skips expensive bounding-box scans.
local saved2D={settings.ESPBoxStyle,settings.ESPTracer,settings.ESPNames,settings.ESPTeams,settings.ESPDistance,settings.ESPHealth,settings.ESPTool,settings.ESPHealthBar}
settings.ESPBoxStyle='Off';settings.ESPTracer='Off';settings.ESPNames=false;settings.ESPTeams=false;settings.ESPDistance=false;settings.ESPHealth=false;settings.ESPTool=false;settings.ESPHealthBar=false
local beforeHighlightScan=boundingCalls;ctx.ESP.update();assert(boundingCalls==beforeHighlightScan and not espEntries[enemy].overlay.Visible)
settings.ESPBoxStyle,settings.ESPTracer,settings.ESPNames,settings.ESPTeams,settings.ESPDistance,settings.ESPHealth,settings.ESPTool,settings.ESPHealthBar=table.unpack(saved2D)
ctx.ESP.update();assert(boundingCalls>beforeHighlightScan)
camera.shiftX=0; anchor.Position=Vector3.new(0,0,30); ctx.ESP.render(camera)
settings.ESPShowAllies=true; settings.ESPShowNeutral=false; settings.ESPTeams=true; settings.ESPHealth=true; settings.ESPTool=true
settings.ESPBoxStyle='Full'; settings.ESPTracer='Top'; settings.ESPHighlight='Outline'; settings.ESPDepth='Occluded'
ctx.ESP.update(); assert(espEntries[ally] and espEntries[neutral] and not espEntries[neutral].active and espEntries[enemy])
assert(espEntries[enemy].topText.Text:find('Blue') and espEntries[enemy].bottomText.Text:find('80 HP') and espEntries[enemy].bottomText.Text:find('Rifle'))
assert(espEntries[enemy].tracer.Visible and espEntries[enemy].highlight.FillTransparency==1 and espEntries[enemy].highlight.DepthMode==Enum.HighlightDepthMode.Occluded)
local pooledEnemy = espEntries[enemy]
settings.ESPVisibleOnly=true; camera.obstacles={1}; ctx.ESP.update()
assert(espEntries[enemy]==pooledEnemy and not pooledEnemy.active and not pooledEnemy.overlay.Visible and not pooledEnemy.tracer.Visible and not pooledEnemy.highlight.Enabled)
ctx.ESP.render(camera); assert(not pooledEnemy.overlay.Visible)
camera.obstacles={}; settings.ESPVisibleOnly=false; hum.Health=0; ctx.ESP.update(); assert(not pooledEnemy.active)
hum.Health=80; ctx.ESP.update(); assert(espEntries[enemy]==pooledEnemy and pooledEnemy.active and pooledEnemy.overlay.Visible)
hum.Health=0; settings.ESPAliveOnly=false; ctx.ESP.update(); assert(espEntries[enemy])
local before=espEntries[enemy]; enemy.Character=nil; ctx.ESP.update(); assert(not espEntries[enemy] and before.overlay.destroyed and before.highlight.destroyed and before.tracer.destroyed)
localPlayer.Team=nil; localPlayer.Neutral=true; assert(ctx.ESP.relationOf(ally)=='Neutral' and ctx.ESP.currentTeamName(localPlayer)=='Neutral / no team')
settings.ESP=false; ctx.ESP.update(); assert(espEntries[ally] and not espEntries[ally].active and not espEntries[ally].overlay.Visible)
settings.ESP=true; settings.ESPShowNeutral=true; ctx.ESP.update(); assert(espEntries[ally] and espEntries[ally].active)
local departed=espEntries[neutral]; playerService.list={localPlayer,ally,enemy}; ctx.ESP.update()
assert(not espEntries[neutral] and departed.overlay.destroyed and departed.highlight.destroyed and departed.tracer.destroyed)
playerService.list={localPlayer,ally,enemy,neutral}
local function press(code,processed)
 local e={UserInputType=Enum.UserInputType.Keyboard,KeyCode=code}
 if code==Enum.UserInputType.MouseButton1 or code==Enum.UserInputType.MouseButton2 or code==Enum.UserInputType.MouseButton3 then e.UserInputType=code end
 input.InputBegan:fire(e,processed or false); return e
end
assert(ctx.UI.isMenuVisible()); press(Enum.KeyCode.RightShift);assert(not ctx.UI.isMenuVisible())
local value=settings.ESP; press(Enum.KeyCode.F6);assert(settings.ESP==value)
local mouse=press(Enum.UserInputType.MouseButton2,true);assert(ctx.UI.isAimActive())
input.InputEnded:fire(mouse);assert(not ctx.UI.isAimActive())
settings.AimMode='Toggle';press(Enum.UserInputType.MouseButton2);assert(ctx.UI.isAimActive())
input.WindowFocusReleased:fire();assert(not ctx.UI.isAimActive() and not ctx.UI.isWindowFocused());input.WindowFocused:fire();assert(ctx.UI.isWindowFocused())
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
local speedControl=controlFor("Speed mode");speedControl.Activated:fire();assert(settings.MovementMode=="CFrame")
speedControl.Activated:fire();speedControl.Activated:fire();assert(settings.MovementMode=="WalkSpeed")
local speedBind=controlFor("Toggle speed");speedBind.Activated:fire();press(Enum.KeyCode.L);assert(speedBind.Text=="L")
local highlightControl=controlFor("Highlight style");local oldStyle=settings.ESPHighlight;highlightControl.Activated:fire();assert(settings.ESPHighlight~=oldStyle)
local distControl=controlFor("ESP distance");distControl.InputBegan:fire({UserInputType=Enum.UserInputType.MouseButton1,Position={X=50}});assert(settings.ESPMaxDistance==1525)
input.InputEnded:fire({UserInputType=Enum.UserInputType.MouseButton1})
press(Enum.KeyCode.RightShift);assert(not ctx.UI.isMenuVisible())
press(Enum.KeyCode.L);assert(ctx.Movement.isSpeed());press(Enum.KeyCode.L);assert(not ctx.Movement.isSpeed())
local oldAim=settings.Aimbot;press(Enum.KeyCode.K);assert(settings.Aimbot~=oldAim)
settings.Aimbot=true
-- Verify modular targeting reacts to aim activation, and menu-open blocks camera movement.
hum.Health=80; enemy.Character=character; anchor.AssemblyLinearVelocity=Vector3.new(0,0,0)
local cframe = camera.CFrame; cframe.lerps=0
function cframe:Lerp(target,alpha) self.lerps=self.lerps+1; assert(alpha>0 and alpha<=1); return self end
ctx.Aim.step(1/60,true,false,false); assert(cframe.lerps>0)
local previous=cframe.lerps;ctx.Aim.step(1/60,true,true,false);assert(cframe.lerps==previous)
-- Test movement module and reversible state against mock Roblox objects.
localPlayer.Character=character
hum.Parent=character; hum.WalkSpeed=16; hum.MoveDirection=Vector3.new(1,0,0)
function hum:ChangeState(state) self.lastState=state end
anchor.CFrame=Vector3.new(0,0,0); anchor.AssemblyLinearVelocity=Vector3.new(2,3,4)
assert(not ctx.Movement.isSpeed() and not ctx.Movement.isJump())
ctx.Movement.toggleSpeed(); run.Heartbeat:fire(0.1); assert(hum.WalkSpeed==40)
ctx.Movement.toggleSpeed(); assert(hum.WalkSpeed==16)
ctx.Movement.toggleSpeed();run.Heartbeat:fire(0.1); hum.WalkSpeed=23
ctx.Movement.toggleSpeed(); assert(hum.WalkSpeed==23) -- preserve a later game write
hum.WalkSpeed=16;ctx.Movement.toggleSpeed();run.Heartbeat:fire(0.1)
settings.MovementMode='CFrame';ctx.Movement.modeChanged();assert(hum.WalkSpeed==16)
run.Heartbeat:fire(0.1);assert(math.abs(anchor.CFrame.X-4)<0.001)
settings.MovementMode='Velocity';run.Heartbeat:fire(0.1);assert(anchor.AssemblyLinearVelocity.X==40 and anchor.AssemblyLinearVelocity.Y==3)
ctx.Movement.toggleSpeed();assert(not ctx.Movement.isSpeed())
ctx.Movement.toggleJump();input.JumpRequest:fire();assert(hum.lastState==Enum.HumanoidStateType.Jumping)
ctx.Movement.toggleJump();ctx.Movement.toggleJump();settings.AirJumpMode='Velocity';input.JumpRequest:fire()
assert(anchor.AssemblyLinearVelocity.X==40 and anchor.AssemblyLinearVelocity.Y==60)
-- Open menu prevents jump; restore mode and verify respawn turns tests off.
press(Enum.KeyCode.RightShift);hum.lastState=nil;settings.AirJumpMode='State';ctx.Movement.toggleJump();ctx.Movement.toggleJump()
input.JumpRequest:fire();assert(hum.lastState==nil)
press(Enum.KeyCode.RightShift);settings.MovementMode='WalkSpeed';ctx.Movement.toggleSpeed();run.Heartbeat:fire(0.1);assert(hum.WalkSpeed==40)
localPlayer.CharacterAdded:fire();assert(not ctx.Movement.isSpeed() and not ctx.Movement.isJump() and hum.WalkSpeed==16)

-- UI controls must fail closed in an unconfigured place; sliders and binds remain usable.
press(Enum.KeyCode.RightShift); assert(ctx.UI.isMenuVisible())
local spoofControl=controlFor("Speed read test"); spoofControl.Activated:fire(); assert(not ctx.Bypass.isSpeedSpoof())
local signalControl=controlFor("Signal drop test"); signalControl.Activated:fire(); assert(not ctx.Bypass.isSignal())
local spoofSlider=controlFor("Reported WalkSpeed")
spoofSlider.InputBegan:fire({UserInputType=Enum.UserInputType.MouseButton1,Position={X=50}})
assert(settings.BypassSpoofSpeed==50)
input.InputEnded:fire({UserInputType=Enum.UserInputType.MouseButton1})
local spoofBind=controlFor("Toggle speed read test"); spoofBind.Activated:fire(); press(Enum.KeyCode.J);assert(spoofBind.Text=="J")
press(Enum.KeyCode.RightShift);press(Enum.KeyCode.J); assert(not ctx.Bypass.isSpeedSpoof())

-- Additional UI and visual lifecycle, exercised on mocks.
press(Enum.KeyCode.RightShift);assert(ctx.UI.isMenuVisible())
controlFor("Crosshair").Activated:fire();assert(settings.CrosshairEnabled)
controlFor("Crosshair shape").Activated:fire();assert(settings.CrosshairShape=="Dot")
controlFor("Fullbright").Activated:fire();assert(settings.FullbrightEnabled)
controlFor("No fog").Activated:fire();assert(settings.NoFogEnabled)
controlFor("Camera FOV").Activated:fire();assert(settings.CameraFOVEnabled)
local crossBind=controlFor("Toggle crosshair");crossBind.Activated:fire();press(Enum.KeyCode.H);assert(crossBind.Text=="H")
press(Enum.KeyCode.RightShift);press(Enum.KeyCode.H);assert(not settings.CrosshairEnabled)
press(Enum.KeyCode.H);assert(settings.CrosshairEnabled)
camera.FieldOfView=70;ctx.Visuals.step(0.016,camera)
assert(lighting.Brightness==4 and lighting.FogEnd==1000000 and camera.FieldOfView==80)
settings.FullbrightEnabled=false;settings.NoFogEnabled=false;settings.CameraFOVEnabled=false
ctx.Visuals.step(0.016,camera);assert(lighting.Brightness==1 and lighting.FogEnd==100 and camera.FieldOfView==70)
assert(not ctx.Trigger.isEnabled());ctx.Trigger.toggle();assert(not ctx.Trigger.isEnabled()) -- no mouse API

-- Binding the activation key is distinct from the master on/off key.
press(Enum.KeyCode.RightShift); assert(ctx.UI.isMenuVisible())
local activateBind=controlFor("Aim activation key")
local mirrorBind=controlFor("Aim trigger")
activateBind.Activated:fire(); press(Enum.KeyCode.Q)
assert(activateBind.Text=="Q" and mirrorBind.Text=="Q")
settings.Aimbot=true; settings.AimMode="Hold"
press(Enum.KeyCode.RightShift); local q=press(Enum.KeyCode.Q,true); assert(ctx.UI.isAimActive())
input.InputEnded:fire(q); assert(not ctx.UI.isAimActive())
local oldMouse=press(Enum.UserInputType.MouseButton2); assert(not ctx.UI.isAimActive())
settings.AimMode="Toggle"; press(Enum.KeyCode.Q); assert(ctx.UI.isAimActive())
press(Enum.KeyCode.Q); assert(not ctx.UI.isAimActive())
-- Mouse rebind works too; Escape clears, and focus loss deactivates.
press(Enum.KeyCode.RightShift); activateBind.Activated:fire(); press(Enum.UserInputType.MouseButton3)
assert(activateBind.Text=="MouseButton3" and mirrorBind.Text=="MouseButton3")
press(Enum.KeyCode.RightShift); settings.AimMode="Hold"
local mb3=press(Enum.UserInputType.MouseButton3,true); assert(ctx.UI.isAimActive())
input.WindowFocusReleased:fire();assert(not ctx.UI.isAimActive());input.WindowFocused:fire()
press(Enum.KeyCode.RightShift);activateBind.Activated:fire();press(Enum.KeyCode.Escape)
assert(activateBind.Text=="Unbound" and mirrorBind.Text=="Unbound")
press(Enum.KeyCode.RightShift);press(Enum.UserInputType.MouseButton3);assert(not ctx.UI.isAimActive())

-- Exercise config buttons through the real menu with mocked disk and JSON service.
local jsonStore, disk = nil, {}
services.HttpService={JSONEncode=function(_,data) jsonStore=data; return "profile-json" end,
    JSONDecode=function(_,data) assert(data=="profile-json"); return jsonStore end}
local originalReadFile=readfile
readfile=function(path) return disk[path] or originalReadFile(path) end
writefile=function(path,content) disk[path]=content end
listfiles=function(root) local files={} for path in pairs(disk) do files[#files+1]=path end return files end
press(Enum.KeyCode.RightShift);assert(ctx.UI.isMenuVisible())
activateBind.Activated:fire();press(Enum.KeyCode.Q)
settings.AimRadius=230; settings.ESP=false
controlFor("Save profile").Activated:fire();assert(disk["DeadlineTest/config_default.json"]=="profile-json")
settings.AimRadius=500;settings.ESP=true;activateBind.Activated:fire();press(Enum.KeyCode.E)
controlFor("Load profile").Activated:fire()
assert(settings.AimRadius==230 and settings.ESP==false and activateBind.Text=="Q")
press(Enum.KeyCode.RightShift);settings.AimMode="Hold";local configKey=press(Enum.KeyCode.Q,true);assert(ctx.UI.isAimActive())
input.InputEnded:fire(configKey);assert(not ctx.UI.isAimActive())
readfile=originalReadFile;writefile=nil;listfiles=nil

-- Lost release events: in Hold mode only, reconcile physical input state.
local fakeClock, oldClock=100,os.clock;os.clock=function() return fakeClock end
local rightDown=true
function input:IsMouseButtonPressed(key) return rightDown end
press(Enum.KeyCode.RightShift);activateBind.Activated:fire();press(Enum.UserInputType.MouseButton2)
press(Enum.KeyCode.RightShift);settings.AimMode="Hold";press(Enum.UserInputType.MouseButton2)
assert(ctx.UI.isAimActive());rightDown=false;fakeClock=100.2;assert(not ctx.UI.isAimActive())
-- Toggle deliberately remains active after releasing the physical button.
settings.AimMode="Toggle";rightDown=true;press(Enum.UserInputType.MouseButton2)
rightDown=false;fakeClock=100.4;assert(ctx.UI.isAimActive())
press(Enum.KeyCode.RightShift);assert(not ctx.UI.isAimActive())
-- Same lost-release recovery for keyboard bindings.
activateBind.Activated:fire();press(Enum.KeyCode.Q);press(Enum.KeyCode.RightShift)
settings.AimMode="Hold";local keyDown=true
function input:IsKeyDown(key) assert(key==Enum.KeyCode.Q);return keyDown end
press(Enum.KeyCode.Q);fakeClock=100.6;assert(ctx.UI.isAimActive())
keyDown=false;fakeClock=100.8;assert(not ctx.UI.isAimActive())
input.IsKeyDown=nil;input.IsMouseButtonPressed=nil;os.clock=oldClock

-- Full UI controls: bind mode changes, hold release, focus and config restore.
local function modeFor(key)
    for _,o in ipairs(createdObjects) do if o.ClassName=="TextButton" and o.Name=="BindMode_"..key then return o end end
    error("missing mode control: "..key)
end
press(Enum.KeyCode.RightShift);assert(ctx.UI.isMenuVisible())
local crossMode=modeFor("Crosshair");assert(crossMode.Text=="MODE: Toggle")
crossMode.Activated:fire();assert(crossMode.Text=="MODE: Hold" and not settings.CrosshairEnabled)
local crossKey=controlFor("Toggle crosshair");crossKey.Activated:fire();press(Enum.KeyCode.H)
press(Enum.KeyCode.RightShift);local heldH=press(Enum.KeyCode.H);assert(settings.CrosshairEnabled)
input.InputEnded:fire(heldH);assert(not settings.CrosshairEnabled)
heldH=press(Enum.KeyCode.H);assert(settings.CrosshairEnabled)
input.WindowFocusReleased:fire();assert(not settings.CrosshairEnabled);input.WindowFocused:fire()
heldH=press(Enum.KeyCode.H);assert(settings.CrosshairEnabled)
press(Enum.KeyCode.RightShift);assert(not settings.CrosshairEnabled)
-- Both UI controls for aim activation share the same settings.AimMode.
local triggerMode=modeFor("Trigger");local oldMode=settings.AimMode
triggerMode.Activated:fire();assert(settings.AimMode~=oldMode)
-- Modes persist in profile, and load does not leave held features enabled.
local savedJSON, memoryDisk
memoryDisk={};services.HttpService={JSONEncode=function(_,v)savedJSON=v;return 'modes-json' end,
    JSONDecode=function(_,v)assert(v=='modes-json');return savedJSON end}
local prevRead=readfile;readfile=function(path)return memoryDisk[path] or prevRead(path) end
writefile=function(path,v)memoryDisk[path]=v end
controlFor("Save profile").Activated:fire();assert(savedJSON.bindModes.Crosshair=="Hold")
crossMode.Activated:fire();assert(crossMode.Text=="MODE: Toggle")
controlFor("Load profile").Activated:fire();assert(crossMode.Text=="MODE: Hold" and not settings.CrosshairEnabled)
press(Enum.KeyCode.RightShift);heldH=press(Enum.KeyCode.H);assert(settings.CrosshairEnabled)
input.InputEnded:fire(heldH);assert(not settings.CrosshairEnabled)
readfile=prevRead;writefile=nil

local originalCleanup=env and env.TestClientCleanup or _G.TestClientCleanup
-- Failed module reads must not unload an existing client.
local originalRead=readfile;readfile=function(path) error('missing') end
local good,err=pcall(assert(loadfile('./main.lua')))
assert(not good and tostring(err):find('Cannot read') and _G.TestClientCleanup==originalCleanup)
readfile=originalRead
_G.TestClientCleanup(); assert(next(espEntries)==nil and ctx.espLayer.destroyed and ctx.gui.destroyed and run.render==nil)
print('Mock runtime: movement, ESP, UI, extras, bypass controls, aim and loader PASS')
