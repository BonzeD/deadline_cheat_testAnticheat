-- Local cursor override, active only while the menu is open.
return function(ctx)
local input=ctx.UserInputService
local open=false
local savedBehavior,savedIcon
local function setOpen(value)
    if value==open then return end
    if value then
        savedBehavior,savedIcon=input.MouseBehavior,input.MouseIconEnabled
        open=true
    else
        open=false
        pcall(function() if input.MouseBehavior==Enum.MouseBehavior.Default then input.MouseBehavior=savedBehavior end end)
        pcall(function() if input.MouseIconEnabled==true then input.MouseIconEnabled=savedIcon end end)
    end
end
local function step()
    if not open then return end
    -- Preserve the most recent game-side changes where observable.
    pcall(function()
        if input.MouseBehavior~=Enum.MouseBehavior.Default then savedBehavior=input.MouseBehavior end
        if input.MouseIconEnabled~=true then savedIcon=input.MouseIconEnabled end
        input.MouseBehavior=Enum.MouseBehavior.Default
        input.MouseIconEnabled=true
    end)
end
return {setOpen=setOpen,step=step,cleanup=function() setOpen(false) end}
end
