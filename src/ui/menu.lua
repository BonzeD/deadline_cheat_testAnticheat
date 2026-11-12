-- Menu, input bindings and visual controls.
return function(ctx)
local Players, localPlayer, settings, UserInputService = ctx.Players, ctx.localPlayer, ctx.settings, ctx.UserInputService
local connections, Aim, ESP, Experiments = ctx.connections, ctx.Aim, ctx.ESP, ctx.Experiments
local relationOf, currentTeamName = ESP.relationOf, ESP.currentTeamName
local Movement, Bypass, Trigger, Visuals, Mobility = ctx.Movement, ctx.Bypass, ctx.Trigger, ctx.Visuals, ctx.Mobility
local Config, Cursor = ctx.Config, ctx.Cursor
local aimActive, windowFocused = false, true
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
local function toggleSpoof() Bypass.toggleSpeedSpoof() end
local function toggleSignal() Bypass.toggleSignal() end
local function toggleTrigger() Trigger.toggle() end
local function toggleAutoJump() Mobility.toggle() end
local function toggleCrosshair() Visuals.toggle("CrosshairEnabled", "Crosshair") end
local function toggleBright() Visuals.toggle("FullbrightEnabled", "Fullbright") end
local function toggleFog() Visuals.toggle("NoFogEnabled", "No fog") end
local function toggleCameraFov() Visuals.toggle("CameraFOVEnabled", "Camera FOV") end
-- Self-contained UI. Right Shift is reserved as a recovery shortcut.
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "DeadlineTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Prefer executor UI container / CoreGui if accessible, otherwise PlayerGui.
-- Core system menus may still cover or capture input regardless of DisplayOrder.
local placed = false
if type(gethui) == "function" then
    local ok, container = pcall(gethui)
    if ok and container then placed = pcall(function() gui.Parent = container end) end
end
if not placed then
    local ok, container = pcall(function() return game:GetService("CoreGui") end)
    if ok and container then placed = pcall(function() gui.Parent = container end) end
end
if not placed then gui.Parent = playerGui end
gui.DisplayOrder = 2147483647
-- Best effort only: capability and CoreGui stacking vary by executor and Roblox.
if type(sethiddenproperty)=="function" then
    pcall(sethiddenproperty, gui, "OnTopOfCoreBlur", true)
elseif type(setscriptable)=="function" then
    pcall(function()
        setscriptable(gui, "OnTopOfCoreBlur", true)
        pcall(function() gui.OnTopOfCoreBlur=true end)
        pcall(setscriptable,gui,"OnTopOfCoreBlur",false)
    end)
end
ctx.gui = gui

local C = {
    background = Color3.fromRGB(20, 20, 20), panel = Color3.fromRGB(28, 28, 28),
    surface = Color3.fromRGB(35, 35, 35), edge = Color3.fromRGB(50, 50, 50),
    accent = Color3.fromRGB(0, 85, 255), purple = Color3.fromRGB(0, 85, 255),
    text = Color3.fromRGB(255, 255, 255), muted = Color3.fromRGB(175, 175, 175),
}
local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(parent, pixels)
    make("UICorner", parent, {CornerRadius = UDim.new(0, pixels >= 9999 and pixels or 2)})
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
make("UISizeConstraint", panel, {MaxSize = Vector2.new(920, 680), MinSize = Vector2.new(680, 390)})
round(panel, 16); outline(panel)
local bar = make("Frame", panel, {Size = UDim2.new(1, 0, 0, 3), BorderSizePixel = 0, BackgroundColor3 = C.accent})
make("UIGradient", bar, {Color = ColorSequence.new(C.accent, C.purple)})
local header = make("Frame", panel, {Size = UDim2.new(1, 0, 0, 73), BackgroundTransparency = 1, Active = true})
text(header, "◈  DEADLINE", 22, UDim2.fromOffset(22, 15), UDim2.fromOffset(240, 25), C.text, Enum.Font.GothamBold)
text(header, "RESEARCH CLIENT    •    RIGHT SHIFT TO HIDE", 11, UDim2.fromOffset(24, 42), UDim2.fromOffset(320, 16), C.muted)
local close = button(header, "HIDE")
close.Size = UDim2.fromOffset(64, 34); close.Position = UDim2.new(1, -82, 0, 19)
local sidebar = make("Frame", panel, {Position = UDim2.fromOffset(16, 78), Size = UDim2.new(0, 126, 1, -132), BackgroundColor3 = C.panel, BorderSizePixel = 0})
round(sidebar, 10)
local nav = make("ScrollingFrame", sidebar, {BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 10), Size = UDim2.new(1, -16, 1, -20), BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.fromOffset(0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y})
make("UIListLayout", nav, {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
local pages = make("Frame", panel, {BackgroundTransparency = 1, Position = UDim2.fromOffset(154, 78), Size = UDim2.new(1, -170, 1, -132)})
local footer = text(panel, "", 11, UDim2.new(0, 20, 1, -43), UDim2.new(1, -40, 0, 31), C.muted)
footer.TextWrapped = true
local navButtons, pageFrames, updaters = {}, {}, {}
local pageGroups = {}
local capture = nil
local order = 0
local function page(name, caption)
    local navButton = button(nav, caption)
    navButton.Size = UDim2.new(1, 0, 0, 39)
    navButton.TextXAlignment = Enum.TextXAlignment.Center
    navButtons[name] = navButton
    local frame = make("ScrollingFrame", pages, {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false})
    local columns = make("Frame", frame, {Name="Columns", BackgroundTransparency=1,
        Size=UDim2.new(1,-8,0,0), AutomaticSize=Enum.AutomaticSize.Y})
    make("UIListLayout", columns, {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder})
    local left=make("Frame",columns,{Name="Left", LayoutOrder=1, BackgroundTransparency=1,
        Size=UDim2.new(0.5,-4,0,0), AutomaticSize=Enum.AutomaticSize.Y})
    local right=make("Frame",columns,{Name="Right", LayoutOrder=2, BackgroundTransparency=1,
        Size=UDim2.new(0.5,-4,0,0), AutomaticSize=Enum.AutomaticSize.Y})
    for _, column in ipairs({left,right}) do
        make("UIListLayout", column, {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder})
        make("UIPadding", column, {PaddingBottom=UDim.new(0,8)})
    end
    pageGroups[frame]={left=left,right=right,count=0}
    pageFrames[name] = frame
    connections[#connections + 1] = navButton.Activated:Connect(function()
        capture = nil
        refreshUI()
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
local extrasPage = page("Extras", "✦  EXTRAS")
local bindPage = page("Bindings", "⌘  BINDS")
local configPage = page("Configs", "▣  CONFIGS")
local function card(parent, title, subtitle, height)
    order = order + 1
    local group = pageGroups[parent]
    assert(group and group.current, "Every page needs a section before controls")
    local frame = make("Frame", group.current, {LayoutOrder = order, Size = UDim2.new(1, 0, 0, height or 52), BackgroundColor3 = C.panel, BorderSizePixel = 0})
    local heading=text(frame, title, 12, UDim2.fromOffset(8, 6), UDim2.new(1, -145, 0, 18), C.text, Enum.Font.GothamSemibold)
    local detail=text(frame, subtitle, 10, UDim2.fromOffset(8, 25), UDim2.new(1, -145, 0, 18), C.muted)
    heading.TextTruncate=Enum.TextTruncate.AtEnd; detail.TextTruncate=Enum.TextTruncate.AtEnd
    return frame
end
local function section(parent, title, description)
    order = order + 1
    local group=assert(pageGroups[parent]); group.count=group.count+1
    local column=group.count % 2 == 1 and group.left or group.right
    local area=make("Frame",column,{Name="Group_"..title, LayoutOrder=order, BackgroundColor3=C.panel,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y})
    round(area,2);outline(area,C.edge,0)
    make("UIListLayout",area,{Padding=UDim.new(0,1), SortOrder=Enum.SortOrder.LayoutOrder})
    local heading=text(area,title,13,UDim2.fromOffset(0,0),UDim2.new(1,0,0,27),C.text,Enum.Font.GothamBold)
    heading.LayoutOrder=0;heading.BackgroundTransparency=0;heading.BackgroundColor3=C.surface
    make("UIPadding",heading,{PaddingLeft=UDim.new(0,8)})
    group.current=area
end
local function toggle(parent, name, description, getter, action)
    local frame = card(parent, name, description)
    local b = button(frame, "")
    b.Size = UDim2.fromOffset(72, 34); b.Position = UDim2.new(1, -84, 0.5, -17)
    local function update()
        local on = getter()
        b.Text = on and "●  ON" or "○  OFF"
        b.BackgroundColor3 = on and Color3.fromRGB(0, 65, 190) or C.surface
        b.TextColor3 = on and C.accent or C.muted
    end
    table.insert(updaters, update)
    connections[#connections + 1] = b.Activated:Connect(function() action(); refreshUI() end)
end
local function choice(parent, name, description, key, options)
    Config.choice(key, options)
    local frame = card(parent, name, description)
    local b = button(frame, "")
    b.Size = UDim2.fromOffset(120, 30); b.Position = UDim2.new(1, -128, 0.5, -15)
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
    Config.number(key, minimum, maximum)
    local frame = card(parent, name, description, 74)
    local value = text(frame, "", 12, UDim2.new(1, -103, 0, 9), UDim2.fromOffset(90, 20), C.accent, Enum.Font.GothamBold)
    value.TextXAlignment = Enum.TextXAlignment.Right
    local track = make("TextButton", frame, {Text = "", AutoButtonColor = false, Position = UDim2.new(0, 14, 1, -25),
        Size = UDim2.new(1, -28, 0, 14), BackgroundColor3 = C.surface, BorderSizePixel = 0})
    round(track, 7)
    local fill = make("Frame", track, {BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1)})
    round(fill, 7)
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
        if key == "BypassSpoofSpeed" then Bypass.updateSpoofValue() end
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
    Speed = toggleSpeed, AirJump = toggleAirJump, Spoof = toggleSpoof, Signal = toggleSignal,
    TriggerBot = toggleTrigger, AutoJump = toggleAutoJump, Crosshair = toggleCrosshair, Bright = toggleBright, Fog = toggleFog, CameraFov = toggleCameraFov}
local function bindName(key)
    return binds[key] and binds[key].Name or "Unbound"
end
local function bindRow(name, description, key, parent)
    local frame = card(parent or bindPage, name, description)
    local b = button(frame, "")
    b.Size = UDim2.fromOffset(120, 30); b.Position = UDim2.new(1, -128, 0.5, -15)
    table.insert(updaters, function() b.Text = capture == key and "Press key..." or bindName(key) end)
    connections[#connections + 1] = b.Activated:Connect(function()
        capture = key; aimActive = false
        setStatus("Press a key or mouse button. Escape clears; Right Shift is reserved.")
    end)
end
-- Local declaration is before all handlers which change activation state.
section(aimPage, "Aim", "Set activation key, then close the menu to use it")
toggle(aimPage, "Aimbot", "Master switch: must be ON", function() return settings.Aimbot end, toggleAim)
bindRow("Aim activation key", "Hold / press after closing menu", "Trigger", aimPage)
choice(aimPage, "Activation", "Hold = keep pressed; Toggle = press once", "AimMode", {"Hold", "Toggle"})
toggle(aimPage, "Silent aim", "Experimental: Mouse.Hit / Target", function() return settings.SilentAim end, toggleSilentAim)
section(aimPage, "Target filters", "Filters and targeting")
toggle(aimPage, "Team check", "Exclude your own team", function() return settings.TeamCheck end, function() flip("TeamCheck") end)
toggle(aimPage, "Wall check", "Require a clear line of sight", function() return settings.WallCheck end, toggleWallCheck)
toggle(aimPage, "Sticky target", "Keep target while still eligible", function() return settings.StickyTarget end, function() flip("StickyTarget") end)
toggle(aimPage, "FOV circle", "Show targeting radius", function() return settings.ShowFOV end, function() flip("ShowFOV") end)
choice(aimPage, "Aim part", "Target character body part", "AimPart", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"})
choice(aimPage, "Target priority", "Screen / distance / health", "AimPriority", {"Screen", "Distance", "Health"})
slider(aimPage, "Aim height offset", "Vertical offset in studs", "AimVerticalOffset", -5, 5, 0.1, "%.1f studs")
section(aimPage, "Aim tuning", "Response and distance")
slider(aimPage, "FOV radius", "Screen pixels from centre", "AimRadius", 30, 600, 5, "%.0f px")
slider(aimPage, "Response", "Lower is smoother; 1 is instant", "Smoothness", 0.01, 1, 0.01, "%.2f")
slider(aimPage, "Max distance", "From camera, in studs", "MaxDistance", 25, 3000, 25, "%.0f studs")
slider(aimPage, "Prediction", "Velocity offset in seconds", "Prediction", 0, 0.5, 0.01, "%.2f s")
-- ESP controls are independent from aim filters.
section(espPage, "Player ESP", "Filters and performance")
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
section(espPage, "Filters", "Choose targets")
toggle(espPage, "ESP", "Independent from aim filters", function() return settings.ESP end, toggleESP)
toggle(espPage, "Allies", "Show your own team", function() return settings.ESPShowAllies end, function() espFlip("ESPShowAllies") end)
toggle(espPage, "Enemies", "Show other known teams", function() return settings.ESPShowEnemies end, function() espFlip("ESPShowEnemies") end)
toggle(espPage, "Neutral / unknown", "Includes missing team info", function() return settings.ESPShowNeutral end, function() espFlip("ESPShowNeutral") end)
toggle(espPage, "Alive only", "Hide dead characters", function() return settings.ESPAliveOnly end, function() espFlip("ESPAliveOnly") end)
toggle(espPage, "Visible only", "Ray visibility check for all ESP", function() return settings.ESPVisibleOnly end, function() espFlip("ESPVisibleOnly") end)
section(espPage, "Performance", "Update frequency")
slider(espPage, "ESP distance", "Maximum distance from camera", "ESPMaxDistance", 25, 3000, 25, "%.0f studs")
slider(espPage, "Scan interval", "Filters, labels, model bounds", "ESPRefresh", 0.05, 1, 0.05, "%.2f s")
slider(espPage, "2D refresh cap", "Lower reduces overlay workload", "ESPFrameRate", 15, 120, 15, "%.0f FPS")
section(espStylePage, "ESP appearance", "Choose how players are displayed")
choice(espStylePage, "Highlight style", "Character outline / fill", "ESPHighlight", {"Both", "Outline", "Fill", "Off"})
choice(espStylePage, "Highlight depth", "Applies only to highlight", "ESPDepth", {"Always", "Occluded"})
choice(espStylePage, "Outline color", "Highlight outline color", "ESPOutlineColor", {"White", "Same", "Black"})
slider(espStylePage, "Fill transparency", "0 opaque → 1 invisible", "ESPFillTransparency", 0, 1, 0.05, "%.2f")
slider(espStylePage, "Outline transparency", "0 opaque → 1 invisible", "ESPOutlineTransparency", 0, 1, 0.05, "%.2f")
section(espStylePage, "Colors", "ESP colors")
choice(espStylePage, "Color mode", "Relation / team / health / rainbow", "ESPColorMode", {"Relation", "Team", "Health", "Rainbow"})
slider(espStylePage, "Ally hue", "Relation color: hue", "ESPAllyHue", 0, 360, 5, "%.0f°")
slider(espStylePage, "Enemy hue", "Relation color: hue", "ESPEnemyHue", 0, 360, 5, "%.0f°")
slider(espStylePage, "Neutral hue", "Relation color: hue", "ESPNeutralHue", 0, 360, 5, "%.0f°")
section(espStylePage, "2D overlay", "Boxes, tracers and labels")
choice(espStylePage, "Box style", "2D bounding box", "ESPBoxStyle", {"Off", "Full", "Corners"})
slider(espStylePage, "Line thickness", "Box and tracer pixels", "ESPBoxThickness", 1, 6, 1, "%.0f px")
slider(espStylePage, "Corner length", "Fraction of box sides", "ESPCornerSize", 0.1, 0.5, 0.05, "%.2f")
choice(espStylePage, "Tracers", "Screen edge to character", "ESPTracer", {"Off", "Bottom", "Center", "Top"})
section(espStylePage, "Labels", "Text and health")
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

section(visualPage, "Test tools", "Client-side experiments")
toggle(visualPage, "Speed test", "Client movement experiment", Movement.isSpeed, toggleSpeed)
choice(visualPage, "Speed mode", "WalkSpeed / CFrame / Velocity", "MovementMode", {"WalkSpeed", "CFrame", "Velocity"})
slider(visualPage, "Speed amount", "CFrame adds; others set", "MovementSpeed", 0, 150, 1, "%.0f studs/s")
section(visualPage, "Jump", "Air jump tests")
toggle(visualPage, "Air jump", "Press jump while in air", Movement.isJump, toggleAirJump)
choice(visualPage, "Air jump mode", "State or vertical velocity", "AirJumpMode", {"State", "Velocity"})
slider(visualPage, "Jump velocity", "Only in Velocity mode", "AirJumpVelocity", 10, 150, 5, "%.0f studs/s")
section(visualPage, "Experiments", "Authorized tests only")
toggle(visualPage, "Noclip", "Local collision experiment", Experiments.isNoclip, toggleNoclip)
toggle(visualPage, "Watcher test", "Needs allowlisted script names", Experiments.isWatcher, toggleWatchers)
toggle(visualPage, "Speed read test", "Configured test PlaceId only", Bypass.isSpeedSpoof, toggleSpoof)
slider(visualPage, "Reported WalkSpeed", "Client read test value", "BypassSpoofSpeed", 0, 100, 1, "%.0f")
toggle(visualPage, "Signal drop test", "Exact test event and flag only", Bypass.isSignal, toggleSignal)
section(extrasPage, "Extra features", "Optional tools and visual settings")
toggle(extrasPage, "Auto jump", "Repeated grounded jumps", Mobility.isEnabled, toggleAutoJump)
toggle(extrasPage, "Jump moving only", "Do not jump while stationary", function() return settings.AutoJumpMovingOnly end, function() settings.AutoJumpMovingOnly = not settings.AutoJumpMovingOnly end)
slider(extrasPage, "Auto jump interval", "Minimum time between jumps", "AutoJumpInterval", 0.1, 1, 0.05, "%.2f s")
section(extrasPage, "Trigger", "Activation and targeting")
toggle(extrasPage, "Trigger bot", "Auto-click over a player", Trigger.isEnabled, toggleTrigger)
choice(extrasPage, "Trigger activation", "Aim trigger or always", "TriggerActivation", {"Aim", "Always"})
toggle(extrasPage, "Trigger team check", "Exclude same Roblox Team", function() return settings.TriggerTeamCheck end, function() settings.TriggerTeamCheck = not settings.TriggerTeamCheck end)
slider(extrasPage, "Trigger delay", "Time on target before clicking", "TriggerDelay", 0, 1, 0.05, "%.2f s")
slider(extrasPage, "Click interval", "Minimum time between clicks", "TriggerInterval", 0.05, 1, 0.05, "%.2f s")
slider(extrasPage, "Trigger distance", "Maximum target distance", "TriggerDistance", 25, 3000, 25, "%.0f studs")
section(extrasPage, "Crosshair settings", "Appearance")
toggle(extrasPage, "Crosshair", "Screen-centred overlay", function() return settings.CrosshairEnabled end, toggleCrosshair)
choice(extrasPage, "Crosshair shape", "Cross, dot, or both", "CrosshairShape", {"Cross", "Dot", "Cross+Dot"})
slider(extrasPage, "Crosshair length", "Arm length", "CrosshairLength", 3, 40, 1, "%.0f px")
slider(extrasPage, "Crosshair gap", "Centre spacing", "CrosshairGap", 0, 30, 1, "%.0f px")
slider(extrasPage, "Crosshair thickness", "Arm thickness", "CrosshairThickness", 1, 8, 1, "%.0f px")
slider(extrasPage, "Crosshair hue", "Color hue", "CrosshairHue", 0, 360, 5, "%.0f°")
slider(extrasPage, "Crosshair transparency", "0 opaque, 1 invisible", "CrosshairTransparency", 0, 1, 0.05, "%.2f")
toggle(extrasPage, "Crosshair spin", "Rotate overlay", function() return settings.CrosshairSpin end, function() settings.CrosshairSpin = not settings.CrosshairSpin end)
slider(extrasPage, "Spin speed", "Degrees per second", "CrosshairSpinSpeed", 0, 360, 10, "%.0f°/s")
section(extrasPage, "Lighting and camera", "Local overrides")
toggle(extrasPage, "Fullbright", "Local lighting only", function() return settings.FullbrightEnabled end, toggleBright)
slider(extrasPage, "Brightness", "Local lighting override", "FullbrightLevel", 0, 10, 0.5, "%.1f")
toggle(extrasPage, "No fog", "Local FogEnd override", function() return settings.NoFogEnabled end, toggleFog)
toggle(extrasPage, "Camera FOV", "Local field-of-view override", function() return settings.CameraFOVEnabled end, toggleCameraFov)
slider(extrasPage, "Camera FOV amount", "May conflict with weapon zoom", "CameraFOVAmount", 30, 120, 1, "%.0f°")
section(bindPage, "Key bindings", "Select a row, then press a key; Esc clears")
bindRow("Aim trigger", "Activation key (same as AIM page)", "Trigger")
bindRow("Toggle auto jump", "No key until assigned", "AutoJump")
bindRow("Toggle trigger bot", "No key until assigned", "TriggerBot")
bindRow("Toggle crosshair", "No key until assigned", "Crosshair")
bindRow("Toggle fullbright", "No key until assigned", "Bright")
bindRow("Toggle no fog", "No key until assigned", "Fog")
bindRow("Toggle camera FOV", "No key until assigned", "CameraFov")
section(bindPage, "Other bindings", "Assign optional keys")
bindRow("Toggle aimbot", "Master ON/OFF, not activation key", "Aimbot")
bindRow("Toggle ESP", "No key until assigned", "ESP")
bindRow("Toggle speed", "No key until assigned", "Speed")
bindRow("Toggle air jump", "No key until assigned", "AirJump")
bindRow("Toggle noclip", "No key until assigned", "Noclip")
bindRow("Toggle speed read test", "No key until assigned", "Spoof")
bindRow("Toggle signal test", "No key until assigned", "Signal")
bindRow("Toggle watcher", "No key until assigned", "Watcher")
bindRow("Toggle silent aim", "No key until assigned", "Silent")
bindRow("Toggle wall check", "No key until assigned", "Wall")
local info = card(bindPage, "Menu: Right Shift", "Reserved so the menu can always reopen")
section(configPage, "Profiles", "Save and load local settings + key bindings")
local configNameCard = card(configPage, "Profile name", "Letters, numbers, _ or -", 68)
local configName = make("TextBox", configNameCard, {Name="ConfigName", Text="default", PlaceholderText="Profile name",
    ClearTextOnFocus=false, TextSize=13, Font=Enum.Font.GothamSemibold, TextColor3=C.text,
    BackgroundColor3=C.surface, BorderSizePixel=0, Position=UDim2.new(1,-160,0.5,-17), Size=UDim2.fromOffset(148,34)})
round(configName,8)
local bindingKeys={"Trigger"}
for key in pairs(actions) do bindingKeys[#bindingKeys+1]=key end
table.sort(bindingKeys)
section(configPage, "Saved profiles", "Files in workspace")
local listCard=card(configPage, "Saved profiles", "Refresh to see local files", 88)
local listText=text(listCard, "Not loaded", 11, UDim2.fromOffset(14,49), UDim2.new(1,-28,0,28), C.accent)
listText.TextWrapped=true
local function refreshConfigList()
    local names,reason=Config.list()
    listText.Text=names and (#names>0 and table.concat(names, "  •  ") or "No saved profiles") or reason
end
local function configAction(name, description, label, action)
    local frame=card(configPage,name,description)
    local b=button(frame,label);b.Size=UDim2.fromOffset(110,34);b.Position=UDim2.new(1,-122,0.5,-17)
    connections[#connections+1]=b.Activated:Connect(action)
end
configAction("Save profile", "Overwrites the same name", "SAVE", function()
    local ok,err=pcall(Config.save,configName.Text,binds,bindingKeys)
    setStatus(ok and ("Saved profile: " .. configName.Text) or ("Save failed: " .. tostring(err)))
    if ok then refreshConfigList() end
end)
configAction("Load profile", "Applies settings and binds", "LOAD", function()
    local oldMode=settings.MovementMode
    local ok,err=pcall(Config.load,configName.Text,binds,bindingKeys)
    if ok then
        if oldMode~=settings.MovementMode then Movement.modeChanged() end
        Bypass.updateSpoofValue(); aimActive=false; Aim.reset(); ESP.update(); refreshUI()
    end
    setStatus(ok and ("Loaded profile: " .. configName.Text) or ("Load failed: " .. tostring(err)))
end)
configAction("Refresh profiles", "Requires listfiles support", "REFRESH", refreshConfigList)
refreshConfigList()

refreshUI = function()
    for _, update in ipairs(updaters) do update() end
    footer.Text = statusText
end
pageFrames.Aim.Visible = true; navButtons.Aim.BackgroundColor3 = C.purple
Cursor.setOpen(true)
refreshUI()
local function showMenu(visible)
    panel.Visible = visible
    Cursor.setOpen(visible)
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
            binds[capture] = code; capture = nil; setStatus("Binding assigned. Close menu to use it. Conflicting binding cleared.")
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
    windowFocused = false; aimActive = false; Aim.reset(); dragging = false
end)
connections[#connections + 1] = UserInputService.WindowFocused:Connect(function() windowFocused = true end)
connections[#connections + 1] = localPlayer.CharacterAdded:Connect(function()
    Experiments.respawn(); Movement.respawn(); Bypass.respawn(); Trigger.respawn(); Mobility.respawn(); aimActive = false; Aim.reset()
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
    isWindowFocused = function() return windowFocused end,
    updateFOV = updateFOV,
    updateTeamChecker = updateTeamChecker,
    cleanup = function() gui:Destroy() end,
}
end
