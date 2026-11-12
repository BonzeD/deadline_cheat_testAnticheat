Enum={Material={Air={}},HumanoidStateType={Jumping={}}}
local s=assert(loadfile('src/mobility/settings.lua'))()
local hum={Health=100,FloorMaterial={},MoveDirection={Magnitude=1},count=0}
function hum:ChangeState(state)assert(state==Enum.HumanoidStateType.Jumping);self.count=self.count+1 end
local character={FindFirstChildOfClass=function()return hum end}
local ui={isMenuVisible=function()return false end,isWindowFocused=function()return true end}
local ctx={settings=s,localPlayer={Character=character},running=true,UserInputService={GetFocusedTextBox=function()return nil end},UI=ui,setStatus=function()end}
local m=assert(loadfile('src/mobility/init.lua'))()(ctx);assert(not m.isEnabled());m.toggle()
m.step(1);m.step(1.1);assert(hum.count==1);m.step(1.3);assert(hum.count==2)
hum.FloorMaterial=Enum.Material.Air;m.step(2);assert(hum.count==2);hum.FloorMaterial={};hum.MoveDirection.Magnitude=0;m.step(3);assert(hum.count==2)
s.AutoJumpMovingOnly=false;m.step(4);assert(hum.count==3)
ui.isMenuVisible=function()return true end;m.step(5);assert(hum.count==3);ui.isMenuVisible=function()return false end
ui.isWindowFocused=function()return false end;m.step(6);assert(hum.count==3)
m.respawn();assert(not m.isEnabled());m.toggle();m.cleanup();assert(not m.isEnabled())
print('Mobility mocks: grounded jumps, interval, focus and cleanup PASS')
