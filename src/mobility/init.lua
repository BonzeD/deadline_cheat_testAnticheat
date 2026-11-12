-- Repeated grounded jump requests for controlled movement testing.
return function(ctx)
local s, input, player = ctx.settings, ctx.UserInputService, ctx.localPlayer
local last=-math.huge
local function toggle()
    s.AutoJumpEnabled=not s.AutoJumpEnabled;last=-math.huge
    ctx.setStatus("Auto jump " .. (s.AutoJumpEnabled and "on" or "off"))
end
local function step(now)
    if not ctx.running or not s.AutoJumpEnabled or not ctx.UI or ctx.UI.isMenuVisible()
       or not ctx.UI.isWindowFocused() or input:GetFocusedTextBox() then return end
    local character=player.Character
    local human=character and character:FindFirstChildOfClass("Humanoid")
    if not human or human.Health<=0 or human.FloorMaterial==Enum.Material.Air then return end
    if s.AutoJumpMovingOnly and human.MoveDirection.Magnitude<0.01 then return end
    if now-last < s.AutoJumpInterval then return end
    last=now; human:ChangeState(Enum.HumanoidStateType.Jumping)
end
local function reset() s.AutoJumpEnabled=false;last=-math.huge end
return {step=step,toggle=toggle,isEnabled=function()return s.AutoJumpEnabled end,respawn=reset,cleanup=reset}
end
