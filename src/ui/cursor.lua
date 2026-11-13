-- Local cursor override, active only while the menu is open.
return function(ctx)
local input=ctx.UserInputService
local open=false
local cameraControl=false
local savedBehavior,savedIcon
local sawRightButton=false
local function rightButtonDown()
    if type(input.IsMouseButtonPressed)~="function" then return nil end
    local ok, value=pcall(function() return input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
    if ok and type(value)=="boolean" then return value end
    return nil
end
local function setOpen(value)
    if value==open then return end
    if value then
        savedBehavior,savedIcon=input.MouseBehavior,input.MouseIconEnabled
        sawRightButton = rightButtonDown()==true
        cameraControl=false
        open=true
    else
        open=false
        if cameraControl then cameraControl=false; return end
        -- LockCurrentPosition may be a stale RMB-drag lock if the user released
        -- RMB while our cursor override was active. Never fake input events.
        local behavior=savedBehavior
        if behavior==Enum.MouseBehavior.LockCurrentPosition and sawRightButton and rightButtonDown()==false then
            behavior=Enum.MouseBehavior.Default
        end
        pcall(function() if input.MouseBehavior==Enum.MouseBehavior.Default then input.MouseBehavior=behavior end end)
        pcall(function() if input.MouseIconEnabled==true then input.MouseIconEnabled=savedIcon end end)
    end
end
local function setCameraControl(value)
    if not open or value==cameraControl then return end
    if value then
        -- Release only properties that still contain our cursor override.
        local behavior=savedBehavior
        if behavior==Enum.MouseBehavior.LockCurrentPosition and sawRightButton and rightButtonDown()==false then
            behavior=Enum.MouseBehavior.Default
        end
        pcall(function() if input.MouseBehavior==Enum.MouseBehavior.Default then input.MouseBehavior=behavior end end)
        pcall(function() if input.MouseIconEnabled==true then input.MouseIconEnabled=savedIcon end end)
        cameraControl=true
    else
        savedBehavior,savedIcon=input.MouseBehavior,input.MouseIconEnabled
        sawRightButton=rightButtonDown()==true
        cameraControl=false
    end
end
local function step()
    if not open or cameraControl then return end
    if rightButtonDown()==true then sawRightButton=true end
    -- Preserve the most recent game-side changes where observable.
    pcall(function()
        if input.MouseBehavior~=Enum.MouseBehavior.Default then savedBehavior=input.MouseBehavior end
        if input.MouseIconEnabled~=true then savedIcon=input.MouseIconEnabled end
        input.MouseBehavior=Enum.MouseBehavior.Default
        input.MouseIconEnabled=true
    end)
end
return {setOpen=setOpen,step=step,setCameraControl=setCameraControl,
    isCameraControl=function() return cameraControl end,cleanup=function() setOpen(false) end}
end
