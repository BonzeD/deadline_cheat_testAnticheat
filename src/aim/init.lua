-- Aimbot module. Only operates on client state.
return function(ctx)
local Players, localPlayer, settings, env = ctx.Players, ctx.localPlayer, ctx.settings, ctx.env
local function isTarget(player)
    if player == localPlayer then return false end
    if settings.TeamCheck and localPlayer.Team ~= nil and player.Team == localPlayer.Team then
        return false
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local head = character and character:FindFirstChild("Head")
    return character ~= nil and humanoid ~= nil and humanoid.Health > 0 and head ~= nil
end

-- Visibility check inspired by Exunys/Aimbot-V3 (CC0; credit: Exunys).
-- If the query fails, do not treat the target as visible.
local function hasLineOfSight(camera, targetPart)
    if not settings.WallCheck then return true end
    local ignored = {targetPart.Parent}
    if localPlayer.Character then table.insert(ignored, localPlayer.Character) end
    local ok, obstacles = pcall(function()
        return camera:GetPartsObscuringTarget({targetPart.Position}, ignored)
    end)
    return ok and #obstacles == 0
end

-- Options inspired by Exunys/Aimbot-V3; implementation written for this test client.
local lockedPlayer = nil
local function candidateFor(camera, player)
    if not isTarget(player) then return nil end
    local part = player.Character:FindFirstChild(settings.AimPart)
    if not part or not part:IsA("BasePart") then return nil end
    if (part.Position - camera.CFrame.Position).Magnitude > settings.MaxDistance then return nil end
    local point, visible = camera:WorldToViewportPoint(part.Position)
    if not visible or point.Z <= 0 or not hasLineOfSight(camera, part) then return nil end
    local distance = (Vector2.new(point.X, point.Y) - camera.ViewportSize / 2).Magnitude
    if distance > settings.AimRadius then return nil end
    return part, distance
end
local function findTarget(camera)
    if settings.StickyTarget and lockedPlayer then
        local part = candidateFor(camera, lockedPlayer)
        if part then return part end
    end
    lockedPlayer = nil
    local bestPart, bestDistance = nil, settings.AimRadius + 1
    for _, player in ipairs(Players:GetPlayers()) do
        local part, distance = candidateFor(camera, player)
        if part and distance < bestDistance then
            bestPart, bestDistance, lockedPlayer = part, distance, player
        end
    end
    return bestPart
end

-- Mouse.Hit / Mouse.Target interception is experimental, not an anti-cheat bypass guarantee.
-- Once installed, the executor hook stays in place but becomes inert on disable/cleanup.
-- Reuse a single hook on rerun; do not overwrite another script's later hook.
local silentState = env.DeadlineSilentAimHook
local function installSilentHook()
    if silentState and silentState.installed then
        silentState.position = silentState.position or Vector3.new()
        return true
    end
    if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" or type(checkcaller) ~= "function" then
        return false
    end
    local candidate = {active = false, target = nil, position = Vector3.new(), mouse = localPlayer:GetMouse()}
    local oldIndex
    local ok, result = pcall(function()
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(object, key)
            local target = candidate.target
            if candidate.active and target and target.Parent and object == candidate.mouse and not checkcaller() then
                if key == "Hit" then return target.CFrame + (candidate.position - target.Position) end
                if key == "Target" then return target end
            end
            return oldIndex(object, key)
        end))
        return oldIndex
    end)
    if not ok or type(result) ~= "function" then return false end
    candidate.installed = true
    silentState = candidate
    env.DeadlineSilentAimHook = candidate
    return true
end


local function reset() lockedPlayer = nil end
local function toggle()
    settings.Aimbot = not settings.Aimbot
    reset()
    ctx.setStatus("Aim " .. (settings.Aimbot and "enabled" or "disabled"))
end
local function toggleSilent()
    if settings.SilentAim then
        settings.SilentAim = false
        if silentState then silentState.active = false; silentState.target = nil end
        ctx.setStatus("Silent aim off. Mouse hook remains inert until session ends.")
    elseif installSilentHook() then
        settings.SilentAim = true
        ctx.setStatus("Silent aim on: Mouse.Hit/Target only. Not universal.")
    else
        ctx.setStatus("Silent aim unavailable: executor hook functions missing or failed.")
    end
end
local function toggleWall()
    settings.WallCheck = not settings.WallCheck
    reset()
    ctx.setStatus("Aim wall check " .. (settings.WallCheck and "enabled" or "disabled"))
end
local function step(dt, aimActive, menuVisible, focused)
    if silentState then silentState.active = false; silentState.target = nil end
    local camera = workspace.CurrentCamera
    if not ctx.running or not settings.Aimbot or menuVisible or focused or not aimActive or not camera then
        reset(); return
    end
    local part = findTarget(camera)
    if part then
        local position = part.Position + part.AssemblyLinearVelocity * settings.Prediction
        if settings.SilentAim and silentState then
            silentState.target, silentState.position, silentState.active = part, position, true
        else
            local current = camera.CFrame
            local alpha = 1 - (1 - settings.Smoothness) ^ (math.clamp(dt, 0, 0.1) * 60)
            camera.CFrame = current:Lerp(CFrame.lookAt(current.Position, position), alpha)
        end
    end
end
return {toggle = toggle, toggleSilent = toggleSilent, toggleWall = toggleWall, reset = reset, step = step,
    cleanup = function() if silentState then silentState.active = false; silentState.target = nil end end}
end
