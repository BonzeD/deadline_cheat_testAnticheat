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
