-- Test button modes, physical release, focus/menu cleanup and unavailable actions.
Enum={UserInputType={MouseButton1={},MouseButton2={},MouseButton3={}}}
local key,down={},false
local input={IsKeyDown=function(_,k) assert(k==key);return down end}
local value, calls=false,0
local actions={ESP=function() value=not value;calls=calls+1 end}
local getters={ESP=function()return value end}
local modes={ESP='Toggle'}
local binding=assert(loadfile('src/ui/bindings.lua'))()(input,actions,getters,modes)
binding.press('ESP',key);assert(value)
binding.press('ESP',key);assert(not value)
binding.setMode('ESP','Hold');assert(not value and modes.ESP=='Hold')
binding.press('ESP',key);binding.press('ESP',key);assert(value and calls==3)
binding.inputEnded(key);assert(not value and calls==4)
binding.press('ESP',key);binding.releaseAll();assert(not value)
-- The fallback detects a lost release without synthesizing input.
local oldClock=os.clock;local now=10;os.clock=function()return now end
down=true;binding.press('ESP',key);now=10.2;binding.step();assert(value)
down=false;binding.step();assert(not value)
os.clock=oldClock
-- If the feature was already enabled, switching to Hold turns it off.
value=true;binding.setMode('ESP','Hold');assert(not value)
binding.setMode('ESP','Toggle');binding.press('ESP',key);assert(value)
binding.inputEnded(key);assert(value)
local failActions={Unavailable=function() end};local failGetters={Unavailable=function()return false end}
local fail=assert(loadfile('src/ui/bindings.lua'))()(input,failActions,failGetters,{Unavailable='Hold'})
fail.press('Unavailable',key);fail.releaseAll();assert(value)
print('Binding mocks: toggle, hold, lost release and lifecycle PASS')
