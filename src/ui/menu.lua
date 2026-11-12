-- Menu, input bindings and visual controls.
return function(ctx)
local Players, localPlayer, settings, UserInputService = ctx.Players, ctx.localPlayer, ctx.settings, ctx.UserInputService
local connections, Aim, ESP, Experiments = ctx.connections, ctx.Aim, ctx.ESP, ctx.Experiments
local relationOf, currentTeamName = ESP.relationOf, ESP.currentTeamName
local Movement = ctx.Movement
local aimActive = false
local refreshUI = function() end
local statusText = "Ready • Right Shift opens or hides the menu."
local function setStatus(message) statusText = message; refreshUI() end
ctx.setStatus = setStatus
local function toggleESP()
    settings.ESP = not settings.ESP; ESP.update()
    setStatus("ESP " .. (settings.ESP and "enabled" or "disabled"))
end
local function toggleAim() aimActive = false; Aim.toggle() end
local function toggleSilentAim() Aim.toggleSilent() end
local function toggleWallCheck() Aim.toggleWall() end
local function toggleNoclip() Experiments.toggleNoclip() end
local function toggleWatchers() Experiments.toggleWatchers() end
local function toggleSpeed() Movement.toggleSpeed() end
local function toggleAirJump() Movement.toggleJump() end
-- Self-contained UI. Right Shift is reserved as a recovery shortcut.
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "DeadlineTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
gui.DisplayOrder = 10
ctx.gui = gui

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
make("UIListLayout", nav, {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
local pages = make("Frame", panel, {BackgroundTransparency = 1, Position = UDim2.fromOffset(154, 78), Size = UDim2.new(1, -170, 1, -132)})
local footer = text(panel, "", 10, UDim2.new(0, 20, 1, -43), UDim2.new(1, -40, 0, 31), C.muted)
footer.TextWrapped = true
local navButtons, pageFrames, updaters = {}, {}, {}
local order = 0
local function page(name, caption)
    local navButton = button(nav, caption)
    navButton.Size = UDim2.new(1, 0, 0, 30)
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
local espPage = page("ESP", "◈  ESP")
local espStylePage = page("ESPStyle", "◌  ESP STYLE")
local visualPage = page("Visual", "◇  TOOLS")
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
        Aim.reset()
        if key == "MovementMode" then Movement.modeChanged() end
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
local function flip(key) settings[key] = not settings[key]; Aim.reset() end
local binds = {Menu = Enum.KeyCode.RightShift, Trigger = Enum.UserInputType.MouseButton2}
local actions = {ESP = toggleESP, Aimbot = toggleAim, Noclip = toggleNoclip,
    Watcher = toggleWatchers, Silent = toggleSilentAim, Wall = toggleWallCheck,
    Speed = toggleSpeed, AirJump = toggleAirJump}
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
-- ESP controls are independent from aim filters.
local teamCard = card(espPage, "Your team", "Updates while the menu is open")
local teamValue = text(teamCard, "", 12, UDim2.new(1,-160,0,10), UDim2.fromOffset(148,30), C.accent, Enum.Font.GothamBold)
teamValue.TextXAlignment = Enum.TextXAlignment.Right; teamValue.TextScaled = true
local countCard = card(espPage, "Team checker", "Other players, including neutrals")
local countValue = text(countCard, "", 11, UDim2.new(1,-158,0,10), UDim2.fromOffset(146,30), C.muted)
countValue.TextXAlignment = Enum.TextXAlignment.Right; countValue.TextScaled = true
local function updateTeamChecker()
    local counts = {Ally = 0, Enemy = 0, Neutral = 0}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then local group = relationOf(player); counts[group] = counts[group] + 1 end
    end
    teamValue.Text = currentTeamName(localPlayer)
    countValue.Text = string.format("A %d  ·  E %d  ·  N %d", counts.Ally, counts.Enemy, counts.Neutral)
end
local function espFlip(key) settings[key] = not settings[key] end
toggle(espPage, "ESP", "Independent from aim filters", function() return settings.ESP end, toggleESP)
toggle(espPage, "Allies", "Show your own team", function() return settings.ESPShowAllies end, function() espFlip("ESPShowAllies") end)
toggle(espPage, "Enemies", "Show other known teams", function() return settings.ESPShowEnemies end, function() espFlip("ESPShowEnemies") end)
toggle(espPage, "Neutral / unknown", "Includes missing team info", function() return settings.ESPShowNeutral end, function() espFlip("ESPShowNeutral") end)
toggle(espPage, "Alive only", "Hide dead characters", function() return settings.ESPAliveOnly end, function() espFlip("ESPAliveOnly") end)
toggle(espPage, "Visible only", "Ray visibility check for all ESP", function() return settings.ESPVisibleOnly end, function() espFlip("ESPVisibleOnly") end)
slider(espPage, "ESP distance", "Maximum distance from camera", "ESPMaxDistance", 25, 3000, 25, "%.0f studs")
slider(espPage, "Update interval", "Lower = smoother, more CPU", "ESPRefresh", 0.05, 1, 0.05, "%.2f s")
choice(espStylePage, "Highlight style", "Character outline / fill", "ESPHighlight", {"Both", "Outline", "Fill", "Off"})
choice(espStylePage, "Highlight depth", "Applies only to highlight", "ESPDepth", {"Always", "Occluded"})
choice(espStylePage, "Outline color", "Highlight outline color", "ESPOutlineColor", {"White", "Same", "Black"})
slider(espStylePage, "Fill transparency", "0 opaque → 1 invisible", "ESPFillTransparency", 0, 1, 0.05, "%.2f")
slider(espStylePage, "Outline transparency", "0 opaque → 1 invisible", "ESPOutlineTransparency", 0, 1, 0.05, "%.2f")
choice(espStylePage, "Color mode", "Relation / team / health / rainbow", "ESPColorMode", {"Relation", "Team", "Health", "Rainbow"})
slider(espStylePage, "Ally hue", "Relation color: hue", "ESPAllyHue", 0, 360, 5, "%.0f°")
slider(espStylePage, "Enemy hue", "Relation color: hue", "ESPEnemyHue", 0, 360, 5, "%.0f°")
slider(espStylePage, "Neutral hue", "Relation color: hue", "ESPNeutralHue", 0, 360, 5, "%.0f°")
choice(espStylePage, "Box style", "2D bounding box", "ESPBoxStyle", {"Off", "Full", "Corners"})
slider(espStylePage, "Line thickness", "Box and tracer pixels", "ESPBoxThickness", 1, 6, 1, "%.0f px")
slider(espStylePage, "Corner length", "Fraction of box sides", "ESPCornerSize", 0.1, 0.5, 0.05, "%.2f")
choice(espStylePage, "Tracers", "Screen edge to character", "ESPTracer", {"Off", "Bottom", "Center", "Top"})
toggle(espStylePage, "Name", "Show player name", function() return settings.ESPNames end, function() espFlip("ESPNames") end)
choice(espStylePage, "Name type", "Display name or username", "ESPNameMode", {"DisplayName", "Username"})
toggle(espStylePage, "Team label", "Show target team", function() return settings.ESPTeams end, function() espFlip("ESPTeams") end)
toggle(espStylePage, "Distance label", "Camera-to-target studs", function() return settings.ESPDistance end, function() espFlip("ESPDistance") end)
toggle(espStylePage, "Health label", "Show target HP", function() return settings.ESPHealth end, function() espFlip("ESPHealth") end)
toggle(espStylePage, "Tool label", "Show equipped Tool if present", function() return settings.ESPTool end, function() espFlip("ESPTool") end)
toggle(espStylePage, "Health bar", "Show health proportion", function() return settings.ESPHealthBar end, function() espFlip("ESPHealthBar") end)
choice(espStylePage, "Health bar side", "Left or right of box", "ESPHealthPosition", {"Left", "Right"})
slider(espStylePage, "Health bar width", "Width in pixels", "ESPHealthWidth", 2, 10, 1, "%.0f px")
slider(espStylePage, "Label size", "Text size in pixels", "ESPTextSize", 10, 24, 1, "%.0f px")
slider(espStylePage, "Overlay transparency", "Box / labels / tracers", "ESPOverlayTransparency", 0, 0.9, 0.05, "%.2f")
updateTeamChecker()

toggle(visualPage, "Speed test", "Client movement experiment", Movement.isSpeed, toggleSpeed)
choice(visualPage, "Speed mode", "WalkSpeed / CFrame / Velocity", "MovementMode", {"WalkSpeed", "CFrame", "Velocity"})
slider(visualPage, "Speed amount", "CFrame adds; others set", "MovementSpeed", 0, 150, 1, "%.0f studs/s")
toggle(visualPage, "Air jump", "Press jump while in air", Movement.isJump, toggleAirJump)
choice(visualPage, "Air jump mode", "State or vertical velocity", "AirJumpMode", {"State", "Velocity"})
slider(visualPage, "Jump velocity", "Only in Velocity mode", "AirJumpVelocity", 10, 150, 5, "%.0f studs/s")
toggle(visualPage, "Noclip", "Local collision experiment", Experiments.isNoclip, toggleNoclip)
toggle(visualPage, "Watcher test", "Needs allowlisted script names", Experiments.isWatcher, toggleWatchers)
bindRow("Aim trigger", "Default RMB; Esc removes", "Trigger")
bindRow("Toggle aimbot", "No key until assigned", "Aimbot")
bindRow("Toggle ESP", "No key until assigned", "ESP")
bindRow("Toggle speed", "No key until assigned", "Speed")
bindRow("Toggle air jump", "No key until assigned", "AirJump")
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
    if visible then aimActive = false; Aim.reset() end
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
    if settings.AimMode == "Hold" and code == binds.Trigger then aimActive = false; Aim.reset() end
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
        if not aimActive then Aim.reset() end
        return
    end
    if processed then return end
    for name, action in pairs(actions) do
        if binds[name] == code then action(); break end
    end
end)
connections[#connections + 1] = UserInputService.WindowFocusReleased:Connect(function()
    aimActive = false; Aim.reset(); dragging = false
end)
connections[#connections + 1] = localPlayer.CharacterAdded:Connect(function()
    Experiments.respawn(); Movement.respawn(); aimActive = false; Aim.reset()
    refreshUI()
end)
local function updateFOV(camera)
    fov.Visible = camera ~= nil and settings.Aimbot and settings.ShowFOV
    if camera then
        fov.Position = UDim2.fromOffset(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        fov.Size = UDim2.fromOffset(settings.AimRadius * 2, settings.AimRadius * 2)
    end
end

return {
    isMenuVisible = function() return panel.Visible end,
    isAimActive = function() return aimActive end,
    updateFOV = updateFOV,
    updateTeamChecker = updateTeamChecker,
    cleanup = function() gui:Destroy() end,
}
end
