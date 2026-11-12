-- Controlled client-side anti-cheat experiments. No platform bypass is claimed.
return function(ctx)
local env, settings, player = ctx.env, ctx.settings, ctx.localPlayer
local speedState = env.DeadlineSpeedSpoofHook
local signalState = env.DeadlineSignalHook
local function permitted()
    if type(settings.BypassAllowedPlaceIds) ~= "table" then return false end
    for _, id in ipairs(settings.BypassAllowedPlaceIds) do
        if type(id) == "number" and id > 0 and id == game.PlaceId then return true end
    end
    return false
end
local function supported(namecall)
    return type(hookmetamethod) == "function" and type(newcclosure) == "function"
       and type(checkcaller) == "function" and (not namecall or type(getnamecallmethod) == "function")
end
local function installSpeed()
    if speedState and speedState.installed then return true end
    if not supported(false) then return false end
    local state = {active = false}
    local previous
    local ok, result = pcall(function()
        previous = hookmetamethod(game, "__index", newcclosure(function(object, key)
            if state.active and object == state.humanoid and (key == "WalkSpeed" or key == "walkSpeed") and not checkcaller() then
                return state.value
            end
            return previous(object, key)
        end))
        return previous
    end)
    if not ok or type(result) ~= "function" then return false end
    state.installed = true; speedState = state; env.DeadlineSpeedSpoofHook = state
    return true
end
local function installSignal()
    if signalState and signalState.installed then return true end
    if not supported(true) then return false end
    local state = {active = false}
    local previous
    local ok, result = pcall(function()
        previous = hookmetamethod(game, "__namecall", newcclosure(function(object, ...)
            if state.active and object == state.remote and not checkcaller()
                and getnamecallmethod() == "FireServer" and select(1, ...) == state.flag then
                state.blocked = state.blocked + 1
                return nil
            end
            return previous(object, ...)
        end))
        return previous
    end)
    if not ok or type(result) ~= "function" then return false end
    state.installed = true; signalState = state; env.DeadlineSignalHook = state
    return true
end
local function resolveRemote()
    local path, flag = settings.BypassRemotePath, settings.BypassRemoteFlag
    if type(path) ~= "table" or #path == 0 or type(flag) ~= "string" or flag == "" then return nil end
    local ok, remote = pcall(function()
        local node = game:GetService("ReplicatedStorage")
        for _, part in ipairs(path) do
            if type(part) ~= "string" or part == "" then return nil end
            node = node:FindFirstChild(part)
            if not node then return nil end
        end
        return node:IsA("RemoteEvent") and node or nil
    end)
    return ok and remote or nil
end
local function toggleSpeedSpoof()
    if speedState and speedState.active then
        speedState.active = false; speedState.humanoid = nil
        ctx.setStatus("Speed read test off; hook remains inert."); return
    end
    if not permitted() then ctx.setStatus("Test disabled: add your PlaceId to bypass settings."); return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then ctx.setStatus("Speed read test: local Humanoid not found."); return end
    if not installSpeed() then ctx.setStatus("Speed read test unavailable: executor hook missing or failed."); return end
    speedState.humanoid, speedState.value, speedState.active = humanoid, settings.BypassSpoofSpeed, true
    ctx.setStatus("Speed read test on: only local WalkSpeed reads are affected.")
end
local function updateSpoofValue()
    if speedState and speedState.active then speedState.value = settings.BypassSpoofSpeed end
end
local function toggleSignal()
    if signalState and signalState.active then
        signalState.active = false; signalState.remote = nil
        ctx.setStatus("Signal test off; hook remains inert."); return
    end
    if not permitted() then ctx.setStatus("Test disabled: add your PlaceId to bypass settings."); return end
    local remote = resolveRemote()
    if not remote then ctx.setStatus("Signal test needs exact remote path and flag in bypass settings."); return end
    if not installSignal() then ctx.setStatus("Signal test unavailable: executor hook missing or failed."); return end
    signalState.remote, signalState.flag, signalState.blocked, signalState.active = remote, settings.BypassRemoteFlag, 0, true
    ctx.setStatus("Signal test on: only the configured event and flag are suppressed.")
end
local function reset()
    if speedState then speedState.active = false; speedState.humanoid = nil end
    if signalState then signalState.active = false; signalState.remote = nil end
end
return {
    toggleSpeedSpoof = toggleSpeedSpoof, toggleSignal = toggleSignal, updateSpoofValue = updateSpoofValue,
    isSpeedSpoof = function() return speedState ~= nil and speedState.active == true end,
    isSignal = function() return signalState ~= nil and signalState.active == true end,
    respawn = function() reset(); ctx.setStatus("Bypass experiments reset on respawn.") end,
    cleanup = reset,
}
end
