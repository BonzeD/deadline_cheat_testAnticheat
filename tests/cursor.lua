Enum={MouseBehavior={Default={},LockCenter={},LockCurrentPosition={}}}
local input={MouseBehavior=Enum.MouseBehavior.LockCenter,MouseIconEnabled=false}
local cursor=assert(loadfile('src/ui/cursor.lua'))()({UserInputService=input})
cursor.setOpen(true);cursor.step()
assert(input.MouseBehavior==Enum.MouseBehavior.Default and input.MouseIconEnabled==true)
input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;input.MouseIconEnabled=false
cursor.step();assert(input.MouseBehavior==Enum.MouseBehavior.Default and input.MouseIconEnabled)
cursor.setOpen(false);assert(input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition and input.MouseIconEnabled==false)
cursor.setOpen(true);cursor.step();input.MouseBehavior=Enum.MouseBehavior.LockCenter
cursor.cleanup();assert(input.MouseBehavior==Enum.MouseBehavior.LockCenter and not input.MouseIconEnabled)
print('Cursor mocks: unlock, restore, game changes and cleanup PASS')
-- If RMB was held while opening and released during the menu, a transient camera
-- lock must not be restored after closing. Never change an unrelated game write.
Enum.UserInputType={MouseButton2={}}
local held=true
function input:IsMouseButtonPressed(key) assert(key==Enum.UserInputType.MouseButton2);return held end
input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;input.MouseIconEnabled=false
cursor.setOpen(true);cursor.step();held=false;cursor.step();cursor.setOpen(false)
assert(input.MouseBehavior==Enum.MouseBehavior.Default and input.MouseIconEnabled==false)
-- LockCenter is legitimate for first-person; preserve it even after RMB release.
held=true;input.MouseBehavior=Enum.MouseBehavior.LockCenter;cursor.setOpen(true);cursor.step();held=false;cursor.setOpen(false)
assert(input.MouseBehavior==Enum.MouseBehavior.LockCenter)
-- If RMB is still held, preserve LockCurrentPosition instead of overriding it.
held=true;input.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;cursor.setOpen(true);cursor.step();cursor.setOpen(false)
assert(input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition)
print('Cursor mocks: released right-button lock recovery PASS')
