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
    AimPart = "Head",
    MaxDistance = 1000,
    StickyTarget = false,
    ShowFOV = true,
    AimMode = "Hold",
    Prediction = 0,
    -- Exact LocalScript names that YOU have identified in your test place.
    -- Empty by default: watcher test will not disable any game scripts until configured.
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

-- Shared state for keyboard shortcuts and the menu.
local refreshUI = function() end
local statusText = "Ready • Right Shift opens or hides the menu."
local function setStatus(message)
    statusText = message
    refreshUI()
end
local function toggleESP()
    settings.ESP = not settings.ESP
    updateESP()
    setStatus("ESP " .. (settings.ESP and "enabled" or "disabled"))
end
local aimActive = false
local function toggleAim()
    settings.Aimbot = not settings.Aimbot
    aimActive = false
    lockedPlayer = nil
    setStatus("Aim " .. (settings.Aimbot and "enabled" or "disabled"))
end
local function toggleSilentAim()
    if settings.SilentAim then
        settings.SilentAim = false
        if silentState then silentState.active = false; silentState.target = nil end
        setStatus("Silent aim off. Mouse hook remains inert until session ends.")
    elseif installSilentHook() then
        settings.SilentAim = true
        setStatus("Silent aim on: Mouse.Hit/Target only. Not universal.")
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

-- Self-contained UI. Right Shift is reserved as a recovery shortcut.
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "DeadlineTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local C = {
    background = Color3.fromRGB(13, 16, 27), panel = Color3.fromRGB(19, 24, 39),
    surface = Color3.fromRGB(27, 34, 52), edge = Color3.fromRGB(54, 67, 91),
    accent = Color3.fromRGB(103, 215, 199), purple = Color3.fromRGB(141, 124, 238),
    text = Color3.fromRGB(239, 243, 252), muted = Color3.fromRGB(151, 165, 189),
}
local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(parent, pixels)
    make("UICorner", parent, {CornerRadius = UDim.new(0, pixels)})
end
local function outline(parent, color, transparency)
    make("UIStroke", parent, {Color = color or C.edge, Transparency = transparency or 0, Thickness = 1})
end
local function text(parent, value, size, position, bounds, color, font)
    return make("TextLabel", parent, {BackgroundTransparency = 1, Text = value, TextSize = size,
        Position = position, Size = bounds, TextColor3 = color or C.text, Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left})
end
local function button(parent, value)
    local b = make("TextButton", parent, {Text = value, TextSize = 12, Font = Enum.Font.GothamSemibold,
        TextColor3 = C.text, BackgroundColor3 = C.surface, BorderSizePixel = 0, AutoButtonColor = true})
    round(b, 8)
    return b
end
local fov = make("Frame", gui, {Name = "AimFOV", AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
round(fov, 9999)
outline(fov, C.accent, 0.2)
local panel = make("Frame", gui, {Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.92, 0, 0.84, 0),
    BackgroundColor3 = C.background, BorderSizePixel = 0, ClipsDescendants = true})
make("UISizeConstraint", panel, {MaxSize = Vector2.new(720, 540), MinSize = Vector2.new(360, 320)})
round(panel, 16); outline(panel)
local bar = make("Frame", panel, {Size = UDim2.new(1, 0, 0, 3), BorderSizePixel = 0, BackgroundColor3 = C.accent})
make("UIGradient", bar, {Color = ColorSequence.new(C.accent, C.purple)})
local header = make("Frame", panel, {Size = UDim2.new(1, 0, 0, 73), BackgroundTransparency = 1, Active = true})
text(header, "◈  DEADLINE", 19, UDim2.fromOffset(22, 15), UDim2.fromOffset(240, 25), C.text, Enum.Font.GothamBold)
text(header, "RESEARCH CLIENT  /  AUTHORIZED TESTING", 10, UDim2.fromOffset(24, 42), UDim2.fromOffset(320, 16), C.muted)
local close = button(header, "—")
close.Size = UDim2.fromOffset(38, 32); close.Position = UDim2.new(1, -55, 0, 19)
local sidebar = make("Frame", panel, {Position = UDim2.fromOffset(16, 78), Size = UDim2.new(0, 126, 1, -132), BackgroundColor3 = C.panel, BorderSizePixel = 0})
round(sidebar, 10)
local nav = make("Frame", sidebar, {BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 10), Size = UDim2.new(1, -16, 1, -20)})
make("UIListLayout", nav, {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
local pages = make("Frame", panel, {BackgroundTransparency = 1, Position = UDim2.fromOffset(154, 78), Size = UDim2.new(1, -170, 1, -132)})
local footer = text(panel, "", 10, UDim2.new(0, 20, 1, -43), UDim2.new(1, -40, 0, 31), C.muted)
footer.TextWrapped = true
local navButtons, pageFrames, updaters = {}, {}, {}
local order = 0
local function page(name, caption)
    local navButton = button(nav, caption)
    navButton.Size = UDim2.new(1, 0, 0, 36)
    navButton.TextXAlignment = Enum.TextXAlignment.Center
    navButtons[name] = navButton
    local frame = make("ScrollingFrame", pages, {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false})
    make("UIListLayout", frame, {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    make("UIPadding", frame, {PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 8)})
    pageFrames[name] = frame
    connections[#connections + 1] = navButton.Activated:Connect(function()
        for k, f in pairs(pageFrames) do
            f.Visible = k == name
            navButtons[k].BackgroundColor3 = k == name and C.purple or C.surface
        end
    end)
    return frame
end
local aimPage = page("Aim", "◉  AIM")
local visualPage = page("Visual", "◇  VISUAL")
local bindPage = page("Bindings", "⌘  BINDS")
local function card(parent, title, subtitle, height)
    order = order + 1
    local frame = make("Frame", parent, {LayoutOrder = order, Size = UDim2.new(1, 0, 0, height or 56), BackgroundColor3 = C.panel, BorderSizePixel = 0})
    round(frame, 9); outline(frame, C.edge, 0.45)
    text(frame, title, 13, UDim2.fromOffset(13, 8), UDim2.new(1, -165, 0, 19), C.text, Enum.Font.GothamSemibold)
    text(frame, subtitle, 10, UDim2.fromOffset(13, 29), UDim2.new(1, -165, 0, 16), C.muted)
    return frame
end
local function toggle(parent, name, description, getter, action)
    local frame = card(parent, name, description)
    local b = button(frame, "")
    b.Size = UDim2.fromOffset(68, 30); b.Position = UDim2.new(1, -80, 0.5, -15)
    local function update()
        local on = getter()
        b.Text = on and "ON" or "OFF"
        b.BackgroundColor3 = on and Color3.fromRGB(41, 103, 97) or C.surface
        b.TextColor3 = on and C.accent or C.muted
    end
    table.insert(updaters, update)
    connections[#connections + 1] = b.Activated:Connect(function() action(); refreshUI() end)
end
local function choice(parent, name, description, key, options)
    local frame = card(parent, name, description)
    local b = button(frame, "")
    b.Size = UDim2.fromOffset(124, 30); b.Position = UDim2.new(1, -136, 0.5, -15)
    table.insert(updaters, function() b.Text = tostring(settings[key]) .. "  ›" end)
    connections[#connections + 1] = b.Activated:Connect(function()
        local index = table.find(options, settings[key]) or 0
        settings[key] = options[index % #options + 1]
        lockedPlayer = nil
        if key == "AimMode" then aimActive = false end
        refreshUI()
    end)
end
local function slider(parent, name, description, key, minimum, maximum, step, format)
    local frame = card(parent, name, description, 74)
    local value = text(frame, "", 12, UDim2.new(1, -103, 0, 9), UDim2.fromOffset(90, 20), C.accent, Enum.Font.GothamBold)
    value.TextXAlignment = Enum.TextXAlignment.Right
    local track = make("TextButton", frame, {Text = "", AutoButtonColor = false, Position = UDim2.new(0, 14, 1, -18),
        Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = C.surface, BorderSizePixel = 0})
    round(track, 3)
    local fill = make("Frame", track, {BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1)})
    round(fill, 3)
    local function update()
        value.Text = string.format(format, settings[key])
        fill.Size = UDim2.fromScale((settings[key] - minimum) / (maximum - minimum), 1)
    end
    table.insert(updaters, update)
    local moving = false
    local function setFromX(x)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local amount = math.floor(((minimum + ratio * (maximum - minimum)) - minimum) / step + 0.5)
        settings[key] = math.clamp(minimum + amount * step, minimum, maximum)
        update()
    end
    connections[#connections + 1] = track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then moving = true; setFromX(input.Position.X) end
    end)
    connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
        if moving and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
    end)
    connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then moving = false end
    end)
end
local function flip(key) settings[key] = not settings[key]; lockedPlayer = nil end
local binds = {Menu = Enum.KeyCode.RightShift, Trigger = Enum.UserInputType.MouseButton2}
local actions = {ESP = toggleESP, Aimbot = toggleAim, Noclip = toggleNoclip,
    Watcher = toggleWatchers, Silent = toggleSilentAim, Wall = toggleWallCheck}
local capture = nil
local function bindName(key)
    return binds[key] and binds[key].Name or "Unbound"
end
local function bindRow(name, description, key)
    local frame = card(bindPage, name, description)
    local b = button(frame, "")
    b.Size = UDim2.fromOffset(128, 30); b.Position = UDim2.new(1, -140, 0.5, -15)
    table.insert(updaters, function() b.Text = capture == key and "Press key..." or bindName(key) end)
    connections[#connections + 1] = b.Activated:Connect(function()
        capture = key; aimActive = false
        setStatus("Press a key or mouse button. Escape clears; Right Shift is reserved.")
    end)
end
-- Local declaration is before all handlers which change activation state.
toggle(aimPage, "Aimbot", "Enable camera targeting", function() return settings.Aimbot end, toggleAim)
toggle(aimPage, "Silent aim", "Experimental: Mouse.Hit / Target", function() return settings.SilentAim end, toggleSilentAim)
toggle(aimPage, "Team check", "Exclude your own team", function() return settings.TeamCheck end, function() flip("TeamCheck") end)
toggle(aimPage, "Wall check", "Require a clear line of sight", function() return settings.WallCheck end, toggleWallCheck)
toggle(aimPage, "Sticky target", "Keep target while still eligible", function() return settings.StickyTarget end, function() flip("StickyTarget") end)
toggle(aimPage, "FOV circle", "Show targeting radius", function() return settings.ShowFOV end, function() flip("ShowFOV") end)
choice(aimPage, "Aim part", "Target character body part", "AimPart", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"})
choice(aimPage, "Activation", "Hold or press to toggle", "AimMode", {"Hold", "Toggle"})
slider(aimPage, "FOV radius", "Screen pixels from centre", "AimRadius", 30, 600, 5, "%.0f px")
slider(aimPage, "Response", "Lower is smoother; 1 is instant", "Smoothness", 0.01, 1, 0.01, "%.2f")
slider(aimPage, "Max distance", "From camera, in studs", "MaxDistance", 25, 3000, 25, "%.0f studs")
slider(aimPage, "Prediction", "Velocity offset in seconds", "Prediction", 0, 0.5, 0.01, "%.2f s")
toggle(visualPage, "ESP", "Highlight eligible players", function() return settings.ESP end, toggleESP)
toggle(visualPage, "Noclip", "Local collision experiment", function() return noclip end, toggleNoclip)
toggle(visualPage, "Watcher test", "Needs allowlisted script names", function() return watcherTest end, toggleWatchers)
bindRow("Aim trigger", "Default RMB; Esc removes", "Trigger")
bindRow("Toggle aimbot", "No key until assigned", "Aimbot")
bindRow("Toggle ESP", "No key until assigned", "ESP")
bindRow("Toggle noclip", "No key until assigned", "Noclip")
bindRow("Toggle watcher", "No key until assigned", "Watcher")
bindRow("Toggle silent aim", "No key until assigned", "Silent")
bindRow("Toggle wall check", "No key until assigned", "Wall")
local info = card(bindPage, "Menu: Right Shift", "Reserved so the menu can always reopen")
refreshUI = function()
    for _, update in ipairs(updaters) do update() end
    footer.Text = statusText
end
pageFrames.Aim.Visible = true; navButtons.Aim.BackgroundColor3 = C.purple
refreshUI()
local function showMenu(visible)
    panel.Visible = visible
    if visible then aimActive = false; lockedPlayer = nil end
    capture = nil
    refreshUI()
end
connections[#connections + 1] = close.Activated:Connect(function() showMenu(false) end)
local dragging, dragStart, startPosition = false, nil, nil
connections[#connections + 1] = header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging, dragStart, startPosition = true, input.Position, panel.Position end
end)
connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + d.X, startPosition.Y.Scale, startPosition.Y.Offset + d.Y)
    end
end)
connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    local code = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
    if settings.AimMode == "Hold" and code == binds.Trigger then aimActive = false; lockedPlayer = nil end
end)
connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
    if UserInputService:GetFocusedTextBox() then return end
    local code
    if input.UserInputType == Enum.UserInputType.Keyboard then code = input.KeyCode
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then code = input.UserInputType end
    if not code then return end
    if capture then
        if code == Enum.KeyCode.Escape then
            binds[capture] = nil; capture = nil; setStatus("Binding cleared.")
        elseif code == Enum.KeyCode.RightShift then
            setStatus("Right Shift is reserved for the menu. Choose another key.")
        else
            for key, existing in pairs(binds) do
                if key ~= capture and existing == code then binds[key] = nil end
            end
            binds[capture] = code; capture = nil; setStatus("Binding assigned. Duplicate binding cleared.")
        end
        refreshUI(); return
    end
    if code == binds.Menu then showMenu(not panel.Visible); return end
    if panel.Visible then return end
    if code == binds.Trigger then
        if settings.AimMode == "Toggle" then aimActive = not aimActive else aimActive = true end
        if not aimActive then lockedPlayer = nil end
        return
    end
    if processed then return end
    for name, action in pairs(actions) do
        if binds[name] == code then action(); break end
    end
end)
connections[#connections + 1] = UserInputService.WindowFocusReleased:Connect(function()
    aimActive = false; lockedPlayer = nil; dragging = false
end)
connections[#connections + 1] = localPlayer.CharacterAdded:Connect(function()
    restoreCollision(); restoreWatchers(); aimActive = false; lockedPlayer = nil
    if watcherTest then watcherTest = false; setStatus("Watcher test reset on respawn.") end
    refreshUI()
end)
local function updateFOV(camera)
    fov.Visible = camera ~= nil and settings.Aimbot and settings.ShowFOV
    if camera then
        fov.Position = UDim2.fromOffset(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        fov.Size = UDim2.fromOffset(settings.AimRadius * 2, settings.AimRadius * 2)
    end
end

connections[#connections + 1] = RunService.Stepped:Connect(stepNoclip)
RunService:BindToRenderStep("TestClientAimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if silentState then silentState.active = false; silentState.target = nil end
    local camera = workspace.CurrentCamera
    updateFOV(camera)
    if not running or not settings.Aimbot or panel.Visible or UserInputService:GetFocusedTextBox() or not aimActive or not camera then
        lockedPlayer = nil
        return
    end
    local part = findTarget(camera)
    if part then
        local position = part.Position + part.AssemblyLinearVelocity * settings.Prediction
        if settings.SilentAim and silentState then
            silentState.target = part
            silentState.position = position
            silentState.active = true
        else
            local current = camera.CFrame
            -- Smoothness represents the interpolation factor at 60 FPS.
            local alpha = 1 - (1 - settings.Smoothness) ^ (math.clamp(dt, 0, 0.1) * 60)
            camera.CFrame = current:Lerp(CFrame.lookAt(current.Position, position), alpha)
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

print("Loaded: Right Shift menu | configure feature binds in Bindings | default aim trigger: RMB")
print("Stop: getgenv().TestClientCleanup()")
