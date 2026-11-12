-- Test client: ESP, camera aim and opt-in bypass experiments.
-- Only test in places you own or are authorized to test.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or _G

if type(env.TestClientCleanup) == "function" then pcall(env.TestClientCleanup) end

local settings = {
    ESP = true,
    Aimbot = true,
    TeamCheck = true,
    AimRadius = 180,
    Smoothness = 0.25,
    -- Exact LocalScript names that YOU have identified in your test place.
    -- Empty by default: F9 will not disable any game scripts until configured.
    WatcherScriptNames = {},
}

local running = true
local noclip = false
local watcherTest = false
local highlights = {}
local connections = {}
local originalCollision = {}
local disabledWatchers = {}

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

local function updateESP()
    local active = {}
    if settings.ESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if isTarget(player) then
                local character = player.Character
                active[character] = true
                if not highlights[character] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "TestClientESP"
                    highlight.FillColor = Color3.fromRGB(255, 60, 60)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.65
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Adornee = character
                    highlight.Parent = character
                    highlights[character] = highlight
                end
            end
        end
    end
    for character, highlight in pairs(highlights) do
        if not active[character] then
            highlight:Destroy()
            highlights[character] = nil
        end
    end
end

local function findTarget(camera)
    local center = camera.ViewportSize / 2
    local bestHead, bestDistance = nil, settings.AimRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if isTarget(player) then
            local head = player.Character:FindFirstChild("Head")
            local point, visible = camera:WorldToViewportPoint(head.Position)
            if visible and point.Z > 0 then
                local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
                if distance < bestDistance then bestDistance, bestHead = distance, head end
            end
        end
    end
    return bestHead
end

-- F8: disable character collisions locally; server-side checks may reject movement.
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

-- F9: experiment with specifically allowlisted client-side signal callbacks.
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
        warn("F9 unavailable: executor does not expose getconnections")
        return false
    end
    if #settings.WatcherScriptNames == 0 then
        warn("F9 not enabled: WatcherScriptNames is empty")
        return false
    end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then warn("F9: HumanoidRootPart not found") return false end
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
    print("F9: disabled matching local callbacks:", count)
    return true
end

connections[#connections + 1] = localPlayer.CharacterAdded:Connect(function()
    restoreCollision()
    restoreWatchers()
    if watcherTest then
        watcherTest = false
        warn("F9 disabled on respawn; enable again after character loads")
    end
end)

connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        settings.ESP = not settings.ESP
        updateESP()
        print("ESP:", settings.ESP)
    elseif input.KeyCode == Enum.KeyCode.F7 then
        settings.Aimbot = not settings.Aimbot
        print("Aimbot:", settings.Aimbot)
    elseif input.KeyCode == Enum.KeyCode.F8 then
        noclip = not noclip
        if not noclip then restoreCollision() end
        print("Noclip:", noclip)
    elseif input.KeyCode == Enum.KeyCode.F9 then
        if watcherTest then
            watcherTest = false
            restoreWatchers()
        else
            watcherTest = disableNamedWatchers(localPlayer.Character)
        end
        print("Targeted watcher test:", watcherTest)
    end
end)

connections[#connections + 1] = RunService.Stepped:Connect(stepNoclip)
RunService:BindToRenderStep("TestClientAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if not running or not settings.Aimbot then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local head = findTarget(camera)
    if head then
        local current = camera.CFrame
        camera.CFrame = current:Lerp(CFrame.lookAt(current.Position, head.Position), settings.Smoothness)
    end
end)

task.spawn(function()
    while running do
        updateESP()
        task.wait(1)
    end
end)

env.TestClientCleanup = function()
    running = false
    noclip = false
    RunService:UnbindFromRenderStep("TestClientAimbot")
    for _, connection in ipairs(connections) do connection:Disconnect() end
    restoreCollision()
    restoreWatchers()
    for _, highlight in pairs(highlights) do highlight:Destroy() end
    env.TestClientCleanup = nil
    print("Test client stopped")
end

print("Loaded: F6 ESP | F7 aim | F8 noclip | F9 targeted watcher test | hold RMB to aim")
print("Stop: getgenv().TestClientCleanup()")
