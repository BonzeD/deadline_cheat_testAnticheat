-- Local movement and allowlisted watcher experiments.
return function(ctx)
local localPlayer, settings = ctx.localPlayer, ctx.settings
local originalCollision, disabledWatchers = {}, {}
local noclip, watcherTest = false, false
-- Noclip: disable character collisions locally; server-side checks may reject movement.
local function restoreCollision()
    for part, wasCollidable in pairs(originalCollision) do
        pcall(function() if part.Parent then part.CanCollide = wasCollidable end end)
    end
    table.clear(originalCollision)
end

local function stepNoclip()
    if not noclip then return end
    local character = localPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if originalCollision[part] == nil then originalCollision[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end

-- Watcher test: experiment with specifically allowlisted client-side signal callbacks.
-- getconnections and callback environment inspection are executor-specific.
-- This cannot disable server handlers or bypass Roblox platform security.
local function restoreWatchers()
    for _, connection in ipairs(disabledWatchers) do
        pcall(function() connection:Enable() end)
    end
    table.clear(disabledWatchers)
end

local function disableNamedWatchers(character)
    if type(getconnections) ~= "function" then
        warn("Watcher test unavailable: executor does not expose getconnections")
        return false
    end
    if #settings.WatcherScriptNames == 0 then
        warn("Watcher test not enabled: WatcherScriptNames is empty")
        return false
    end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then warn("Watcher test: HumanoidRootPart not found") return false end
    local signals = {root.Changed, root:GetPropertyChangedSignal("CFrame")}
    local count = 0
    for _, signal in ipairs(signals) do
        local ok, list = pcall(getconnections, signal)
        if ok and type(list) == "table" then
            for _, connection in ipairs(list) do
                pcall(function()
                    local callback = connection.Function
                    if type(callback) ~= "function" or connection.Enabled ~= true then return end
                    local scope = getfenv(callback)
                    local scriptObject = scope and scope.script
                    if typeof(scriptObject) ~= "Instance" or not scriptObject:IsA("LocalScript") then return end
                    if not table.find(settings.WatcherScriptNames, scriptObject.Name) then return end
                    connection:Disable()
                    table.insert(disabledWatchers, connection)
                    count = count + 1
                end)
            end
        end
    end
    print("Watcher test: disabled matching local callbacks:", count)
    return count > 0
end

local function toggleNoclip()
    noclip = not noclip
    if not noclip then restoreCollision() end
    ctx.setStatus("Noclip " .. (noclip and "enabled" or "disabled"))
end
local function toggleWatchers()
    if watcherTest then
        watcherTest = false
        restoreWatchers()
        ctx.setStatus("Local watcher test disabled; connections restored.")
    else
        watcherTest = disableNamedWatchers(localPlayer.Character)
        if watcherTest then
            ctx.setStatus("Matching local watchers disabled. Server checks are unaffected.")
        elseif #settings.WatcherScriptNames == 0 then
            ctx.setStatus("Watcher test needs names in WatcherScriptNames.")
        elseif type(getconnections) ~= "function" then
            ctx.setStatus("Watcher test unavailable: getconnections is missing.")
        else
            ctx.setStatus("No matching accessible watchers found. See console.")
        end
    end
end


return {
    step = stepNoclip, toggleNoclip = toggleNoclip, toggleWatchers = toggleWatchers,
    isNoclip = function() return noclip end, isWatcher = function() return watcherTest end,
    respawn = function()
        restoreCollision(); restoreWatchers()
        if watcherTest then watcherTest = false; ctx.setStatus("Watcher test reset on respawn.") end
    end,
    cleanup = function() noclip = false; restoreCollision(); restoreWatchers() end,
}
end
