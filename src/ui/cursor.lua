-- Cursor is free while the menu is open, but RMB temporarily returns mouse
-- control to the game so its camera can handle a normal drag.
return function(ctx)
local input=ctx.UserInputService
local open=false
local savedBehavior,savedIcon
local sawRightButton=false
local cameraControl=false
local overriding=false
local function rightButtonDown()
    if type(input.IsMouseButtonPressed)~="function" then return nil end
    local ok, value=pcall(function() return input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
    if ok and type(value)=="boolean" then return value end
    return nil
end
local function restoreOverride()
    local behavior=savedBehavior
    if behavior==Enum.MouseBehavior.LockCurrentPosition and sawRightButton and rightButtonDown()==false then
        behavior=Enum.MouseBehavior.Default
    end
    pcall(function() if input.MouseBehavior==Enum.MouseBehavior.Default then input.MouseBehavior=behavior end end)
    pcall(function() if input.MouseIconEnabled==true then input.MouseIconEnabled=savedIcon end end)
    overriding=false
end
local function setOpen(value)
    if value==open then return end
    if value then
        savedBehavior,savedIcon=input.MouseBehavior,input.MouseIconEnabled
        sawRightButton = rightButtonDown()==true
        cameraControl=false;overriding=false;open=true
    else
        open=false
        if overriding then
            restoreOverride()
        elseif cameraControl and rightButtonDown()==false then
            -- RMB can be released just before the menu closes, before the next frame.
            pcall(function()
                if input.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition then
                    input.MouseBehavior=savedBehavior==Enum.MouseBehavior.LockCurrentPosition and Enum.MouseBehavior.Default or savedBehavior
                end
            end)
        end
        cameraControl=false
    end
end
local function step()
    if not open then return end
    local down=rightButtonDown()
    if down==true then
        sawRightButton=true
        if not cameraControl and overriding then restoreOverride() end
        cameraControl=true
        return -- Do not fight the game's camera while RMB is held.
    end
    local justReleased=cameraControl and down==false
    cameraControl=false
    if justReleased and savedBehavior==Enum.MouseBehavior.LockCurrentPosition then savedBehavior=Enum.MouseBehavior.Default end
    pcall(function()
        -- Do not save a transient drag lock immediately after RMB is released.
        if not justReleased and input.MouseBehavior~=Enum.MouseBehavior.Default then savedBehavior=input.MouseBehavior end
        if not justReleased and input.MouseIconEnabled~=true then savedIcon=input.MouseIconEnabled end
        input.MouseBehavior=Enum.MouseBehavior.Default
        input.MouseIconEnabled=true
        overriding=true
    end)
end
return {setOpen=setOpen,step=step,cleanup=function() setOpen(false) end}
end
