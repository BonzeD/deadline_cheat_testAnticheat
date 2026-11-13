Enum={MouseBehavior={Default={},LockCenter={},LockCurrentPosition={}}, UserInputType={MouseButton2={}}}
local held=false
local input={MouseBehavior=Enum.MouseBehavior.LockCenter,MouseIconEnabled=false}
function input:IsMouseButtonPressed(key) assert(key==Enum.UserInputType.MouseButton2);return held end
local cursor=assert(loadfile('src/ui/cursor.lua'))()({UserInputService=input})
-- A first-person lock is released for menu interaction and restored for RMB.
cursor.setOpen(true);cursor.step()
assert(input.MouseBehavior==Enum.MouseBehavior.Default and input.MouseIconEnabled==true)
held=true;cursor.step();assert(input.MouseBehavior==Enum.MouseBehavior.LockCenter and not input.MouseIconEnabled)
-- The game may update camera state freely while RMB is held.
input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;cursor.step();assert(input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition)
held=false;cursor.step();assert(input.MouseBehavior==Enum.MouseBehavior.Default and input.MouseIconEnabled)
cursor.setOpen(false);assert(input.MouseBehavior==Enum.MouseBehavior.LockCenter and not input.MouseIconEnabled)
-- Normal third-person RMB drag must not leave a stale lock on close.
input.MouseBehavior=Enum.MouseBehavior.Default;input.MouseIconEnabled=true
cursor.setOpen(true);cursor.step();held=true;cursor.step();input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
cursor.step();assert(input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition)
held=false;cursor.step();cursor.setOpen(false);assert(input.MouseBehavior==Enum.MouseBehavior.Default)
-- Opening with a drag lock held, then releasing before the first/next step.
held=true;input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;input.MouseIconEnabled=false
cursor.setOpen(true);cursor.step();held=false;cursor.setOpen(false)
assert(input.MouseBehavior==Enum.MouseBehavior.Default and not input.MouseIconEnabled)
-- Closing while RMB is still held does not fight the game's current camera state.
held=false;input.MouseBehavior=Enum.MouseBehavior.LockCenter;cursor.setOpen(true);cursor.step();held=true;cursor.step()
input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;cursor.setOpen(false);assert(input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition)
-- Observe unrelated game writes outside a camera drag.
held=false;input.MouseBehavior=Enum.MouseBehavior.LockCenter;input.MouseIconEnabled=false
cursor.setOpen(true);cursor.step();input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;cursor.step()
cursor.cleanup();assert(input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition and not input.MouseIconEnabled)
-- Missing or failed button query falls back to the free-cursor behaviour.
input.IsMouseButtonPressed=nil;input.MouseBehavior=Enum.MouseBehavior.LockCenter;cursor.setOpen(true);cursor.step()
assert(input.MouseBehavior==Enum.MouseBehavior.Default and input.MouseIconEnabled);cursor.cleanup()
assert(input.MouseBehavior==Enum.MouseBehavior.LockCenter)
print('Cursor mocks: RMB camera handoff, release, close, first-person and fallback PASS')
