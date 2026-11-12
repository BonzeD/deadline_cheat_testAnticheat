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
    WallCheck = true,
    SilentAim = false, -- experimental; executor and game dependent
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

local function findTarget(camera)
    local center = camera.ViewportSize / 2
    local bestHead, bestDistance = nil, settings.AimRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if isTarget(player) then
            local head = player.Character:FindFirstChild("Head")
            local point, visible = camera:WorldToViewportPoint(head.Position)
            if visible and point.Z > 0 and hasLineOfSight(camera, head) then
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
    return count > 0
end

-- Mouse.Hit / Mouse.Target interception is experimental, not an anti-cheat bypass guarantee.
-- Once installed, the executor hook stays in place but becomes inert on disable/cleanup.
-- Reuse a single hook on rerun; do not overwrite another script's later hook.
local silentState = env.DeadlineSilentAimHook
local function installSilentHook()
    if silentState and silentState.installed then return true end
    if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" or type(checkcaller) ~= "function" then
        return false
    end
    local candidate = {active = false, target = nil, mouse = localPlayer:GetMouse()}
    local oldIndex
    local ok, result = pcall(function()
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(object, key)
            local target = candidate.target
            if candidate.active and target and target.Parent and object == candidate.mouse and not checkcaller() then
                if key == "Hit" then return target.CFrame end
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

-- Shared state for keyboard shortcuts and the menu.
local refreshUI = function() end
local statusText = "Ready. Right Shift opens or hides the menu."
local function setStatus(message)
    statusText = message
    refreshUI()
end
local function toggleESP()
    settings.ESP = not settings.ESP
    updateESP()
    setStatus("ESP " .. (settings.ESP and "enabled" or "disabled"))
end
local function toggleAim()
    settings.Aimbot = not settings.Aimbot
    setStatus("Aim " .. (settings.Aimbot and "enabled" or "disabled"))
end
local function toggleSilentAim()
    if settings.SilentAim then
        settings.SilentAim = false
        if silentState then silentState.active = false; silentState.target = nil end
        setStatus("Silent aim off. Mouse hook remains inert until session ends.")
    elseif installSilentHook() then
        settings.SilentAim = true
        setStatus("Silent aim on: Mouse.Hit/Target only; hold RMB. Not universal.")
    else
        setStatus("Silent aim unavailable: executor hook functions missing or failed.")
    end
end
local function toggleWallCheck()
    settings.WallCheck = not settings.WallCheck
    setStatus("Aim wall check " .. (settings.WallCheck and "enabled" or "disabled"))
end
local function toggleNoclip()
    noclip = not noclip
    if not noclip then restoreCollision() end
    setStatus("Noclip " .. (noclip and "enabled" or "disabled"))
end
local function toggleWatchers()
    if watcherTest then
        watcherTest = false
        restoreWatchers()
        setStatus("Local watcher test disabled; connections restored.")
    else
        watcherTest = disableNamedWatchers(localPlayer.Character)
        if watcherTest then
            setStatus("Matching local watchers disabled. Server checks are unaffected.")
        elseif #settings.WatcherScriptNames == 0 then
            setStatus("Watcher test needs names in WatcherScriptNames.")
        elseif type(getconnections) ~= "function" then
            setStatus("Watcher test unavailable: getconnections is missing.")
        else
            setStatus("No matching accessible watchers found. See console.")
        end
    end
end

-- PlayerGui is used rather than loading an external UI library.
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "DeadlineTestMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(parent, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius)
    item.Parent = parent
end
local function label(parent, text, position, size, textSize, color)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position = position
    item.Size = size
    item.Font = Enum.Font.Gotham
    item.Text = text
    item.TextColor3 = color
    item.TextSize = textSize
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = parent
    return item
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(370, 463)
panel.Position = UDim2.new(0.5, -185, 0.5, -231)
panel.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 12)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(66, 75, 94)
stroke.Thickness = 1
stroke.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = panel
local title = label(header, "DEADLINE  /  TEST CLIENT", UDim2.fromOffset(18, 11), UDim2.new(1, -36, 0, 23), 17, Color3.fromRGB(240, 243, 250))
title.Font = Enum.Font.GothamBold
label(header, "RIGHT SHIFT  •  SHOW / HIDE  •  DRAG HEADER", UDim2.fromOffset(18, 36), UDim2.new(1, -36, 0, 16), 10, Color3.fromRGB(151, 162, 184))

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(18, 64)
divider.Size = UDim2.new(1, -36, 0, 1)
divider.BorderSizePixel = 0
divider.BackgroundColor3 = Color3.fromRGB(57, 65, 80)
divider.Parent = panel
local rows = Instance.new("Frame")
rows.BackgroundTransparency = 1
rows.Position = UDim2.fromOffset(18, 78)
rows.Size = UDim2.new(1, -36, 0, 292)
rows.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = rows

local buttons = {}
local function addToggle(name, shortcut, description, order, action)
    local button = Instance.new("TextButton")
    button.Name = name
    button.LayoutOrder = order
    button.Size = UDim2.new(1, 0, 0, 42)
    button.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Text = ""
    button.Parent = rows
    corner(button, 8)
    local textName = label(button, name .. "  [" .. shortcut .. "]", UDim2.fromOffset(12, 3), UDim2.new(1, -85, 0, 20), 13, Color3.fromRGB(234, 238, 246))
    textName.Font = Enum.Font.GothamSemibold
    label(button, description, UDim2.fromOffset(12, 22), UDim2.new(1, -85, 0, 15), 10, Color3.fromRGB(152, 162, 183))
    local badge = label(button, "OFF", UDim2.new(1, -63, 0.5, -10), UDim2.fromOffset(50, 20), 11, Color3.fromRGB(149, 159, 178))
    badge.TextXAlignment = Enum.TextXAlignment.Right
    badge.Font = Enum.Font.GothamBold
    connections[#connections + 1] = button.Activated:Connect(action)
    buttons[name] = badge
end
addToggle("ESP", "F6", "Highlight other players", 1, toggleESP)
addToggle("Aimbot", "F7", "Hold right mouse button to aim", 2, toggleAim)
addToggle("Noclip", "F8", "Local collision experiment", 3, toggleNoclip)
addToggle("Watcher test", "F9", "Requires configured script names", 4, toggleWatchers)
addToggle("Silent aim", "F10", "Mouse.Hit / Target only; hold RMB", 5, toggleSilentAim)
addToggle("Wall check", "F11", "Aim at unobstructed targets only", 6, toggleWallCheck)

local status = label(panel, "", UDim2.fromOffset(18, 381), UDim2.new(1, -36, 0, 42), 11, Color3.fromRGB(169, 180, 201))
status.TextWrapped = true
status.TextYAlignment = Enum.TextYAlignment.Top
local hint = label(panel, "Client tests only  •  Server protection is not bypassed", UDim2.fromOffset(18, 437), UDim2.new(1, -36, 0, 15), 10, Color3.fromRGB(122, 136, 159))

refreshUI = function()
    local states = {ESP = settings.ESP, Aimbot = settings.Aimbot, Noclip = noclip, ["Watcher test"] = watcherTest, ["Silent aim"] = settings.SilentAim, ["Wall check"] = settings.WallCheck}
    for name, badge in pairs(buttons) do
        badge.Text = states[name] and "ON" or "OFF"
        badge.TextColor3 = states[name] and Color3.fromRGB(106, 225, 177) or Color3.fromRGB(149, 159, 178)
    end
    status.Text = statusText
end
refreshUI()

-- Drag with the mouse; do not intercept button clicks.
local dragging, dragStart, startPosition = false, nil, nil
connections[#connections + 1] = header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPosition = true, input.Position, panel.Position
    end
end)
connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
connections[#connections + 1] = localPlayer.CharacterAdded:Connect(function()
    restoreCollision()
    restoreWatchers()
    if watcherTest then
        watcherTest = false
        setStatus("Watcher test reset on respawn. Enable it again if needed.")
    end
    refreshUI()
end)
connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
        return
    end
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F6 then toggleESP()
    elseif input.KeyCode == Enum.KeyCode.F7 then toggleAim()
    elseif input.KeyCode == Enum.KeyCode.F8 then toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.F9 then toggleWatchers()
    elseif input.KeyCode == Enum.KeyCode.F10 then toggleSilentAim()
    elseif input.KeyCode == Enum.KeyCode.F11 then toggleWallCheck() end
end)

connections[#connections + 1] = RunService.Stepped:Connect(stepNoclip)
RunService:BindToRenderStep("TestClientAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if silentState then silentState.active = false; silentState.target = nil end
    if not running or not settings.Aimbot or gui.Enabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local head = findTarget(camera)
    if head then
        if settings.SilentAim and silentState then
            silentState.target = head
            silentState.active = true
        else
            local current = camera.CFrame
            camera.CFrame = current:Lerp(CFrame.lookAt(current.Position, head.Position), settings.Smoothness)
        end
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
    if silentState then silentState.active = false; silentState.target = nil end
    RunService:UnbindFromRenderStep("TestClientAimbot")
    for _, connection in ipairs(connections) do connection:Disconnect() end
    restoreCollision()
    restoreWatchers()
    for _, highlight in pairs(highlights) do highlight:Destroy() end
    gui:Destroy()
    env.TestClientCleanup = nil
    print("Test client stopped")
end

print("Loaded: Right Shift menu | F6 ESP | F7 aim | F8 noclip | F9 watchers | F10 silent | F11 wall check | hold RMB")
print("Stop: getgenv().TestClientCleanup()")
