-- Client-side mouse-target automation, independent from camera aim.
return function(ctx)
local settings, player, players = ctx.settings, ctx.localPlayer, ctx.Players
local mouse = player:GetMouse()
local found, acquired, lastFire = nil, 0, -math.huge
local function reset() found, acquired = nil, 0 end
local function toggle()
    if not settings.TriggerEnabled and type(mouse1click) ~= "function" then
        ctx.setStatus("Trigger bot unavailable: mouse1click is missing."); return
    end
    settings.TriggerEnabled = not settings.TriggerEnabled
    reset(); ctx.setStatus("Trigger bot " .. (settings.TriggerEnabled and "on" or "off"))
end
local function targetFor(camera)
    local hit = mouse.Target
    if not hit then return nil end
    for _, other in ipairs(players:GetPlayers()) do
        if other ~= player and other.Character and hit:IsDescendantOf(other.Character) then
            local human = other.Character:FindFirstChildOfClass("Humanoid")
            if not human or human.Health <= 0 then return nil end
            if settings.TriggerTeamCheck and player.Team ~= nil and other.Team == player.Team then return nil end
            local root = other.Character:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsA("BasePart") then return nil end
            if (root.Position - camera.CFrame.Position).Magnitude > settings.TriggerDistance then return nil end
            return other
        end
    end
end
local function step(now, menuVisible, focused, aimActive, windowFocused)
    if not ctx.running or not settings.TriggerEnabled or menuVisible or focused or not windowFocused
       or (settings.TriggerActivation == "Aim" and not aimActive) or not workspace.CurrentCamera then reset(); return end
    local ok, target = pcall(targetFor, workspace.CurrentCamera)
    if not ok or not target then reset(); return end
    if target ~= found then found, acquired = target, now end
    if now - acquired >= settings.TriggerDelay and now - lastFire >= settings.TriggerInterval then
        local clicked = pcall(mouse1click)
        if not clicked then settings.TriggerEnabled=false; reset(); ctx.setStatus("Trigger bot stopped: mouse1click failed."); return end
        lastFire = now
    end
end
local function cleanup() settings.TriggerEnabled=false; reset() end
return {step=step, toggle=toggle, isEnabled=function() return settings.TriggerEnabled end,
    respawn=cleanup, cleanup=cleanup}
end
