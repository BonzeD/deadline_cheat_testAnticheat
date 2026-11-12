-- Team-aware ESP. No aimbot state or UI dependencies.
return function(ctx)
local Players, localPlayer, settings = ctx.Players, ctx.localPlayer, ctx.settings
-- ESP is deliberately independent from the aim TeamCheck. Neutral / unknown is its own group.
local espEntries = {}
local espLayer = Instance.new("ScreenGui")
espLayer.Name = "DeadlineESPOverlay"
espLayer.ResetOnSpawn = false
espLayer.IgnoreGuiInset = true
espLayer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
espLayer.DisplayOrder = 0
espLayer.Parent = localPlayer:WaitForChild("PlayerGui")
ctx.espLayer = espLayer
local function teamOf(player)
    if player.Neutral or player.Team == nil then return nil end
    return player.Team
end
local function relationOf(player)
    local own, other = teamOf(localPlayer), teamOf(player)
    if not own or not other then return "Neutral" end
    return own == other and "Ally" or "Enemy"
end
local function currentTeamName(player)
    local team = teamOf(player)
    return team and team.Name or "Neutral / no team"
end
local function makeESP(class, parent, props)
    local object = Instance.new(class)
    for k, v in pairs(props or {}) do object[k] = v end
    object.Parent = parent
    return object
end
local function removeESP(player)
    local entry = espEntries[player]
    if not entry then return end
    if entry.highlight then entry.highlight:Destroy() end
    entry.overlay:Destroy()
    entry.tracer:Destroy()
    espEntries[player] = nil
end
local function espColor(player, relation, humanoid)
    local mode = settings.ESPColorMode
    if mode == "Team" and teamOf(player) then return player.TeamColor.Color end
    if mode == "Health" then
        local ratio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
        return Color3.fromRGB(math.floor(255 * (1-ratio)), math.floor(230 * ratio), 80)
    end
    if mode == "Rainbow" then return Color3.fromHSV((os.clock() / 5) % 1, 0.8, 1) end
    local hue = relation == "Ally" and settings.ESPAllyHue or relation == "Enemy" and settings.ESPEnemyHue or settings.ESPNeutralHue
    return Color3.fromHSV((hue % 360) / 360, 0.8, 1)
end
local function makeEntry(player, character)
    local overlay = makeESP("Frame", espLayer, {Name = "ESP_" .. player.UserId, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false})
    local e = {character = character, overlay = overlay, lines = {}}
    for i = 1, 8 do
        e.lines[i] = makeESP("Frame", overlay, {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0})
    end
    e.topText = makeESP("TextLabel", overlay, {Name = "Top", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, -125, 0, -30), Size = UDim2.fromOffset(250, 28), Text = "", Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = Color3.fromRGB(255,255,255), TextStrokeTransparency = 0.25})
    e.bottomText = makeESP("TextLabel", overlay, {Name = "Bottom", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5, -125, 1, 2), Size = UDim2.fromOffset(250, 28), Text = "", Font = Enum.Font.Gotham,
        TextSize = 12, TextColor3 = Color3.fromRGB(255,255,255), TextStrokeTransparency = 0.25})
    e.healthBack = makeESP("Frame", overlay, {BackgroundColor3 = Color3.fromRGB(12,14,20), BorderSizePixel = 0})
    e.healthFill = makeESP("Frame", e.healthBack, {AnchorPoint = Vector2.new(0,1), Position = UDim2.fromScale(0,1), BorderSizePixel = 0})
    e.tracer = makeESP("Frame", espLayer, {Name = "Trace_" .. player.UserId, AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Visible = false})
    local highlight = makeESP("Highlight", character, {Name = "TestClientESP", Adornee = character})
    e.highlight = highlight
    espEntries[player] = e
    return e
end
local function espClear()
    local remove = {}
    for player in pairs(espEntries) do table.insert(remove, player) end
    for _, player in ipairs(remove) do removeESP(player) end
end
-- Project all bounding box corners. Reject boxes crossing the camera plane (rather than drawing bogus lines).
local function projectedBounds(camera, character)
    local ok, cf, size = pcall(function() return character:GetBoundingBox() end)
    if not ok or not cf or not size then return nil end
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, x in ipairs({-1, 1}) do
        for _, y in ipairs({-1, 1}) do
            for _, z in ipairs({-1, 1}) do
                local point = camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(size.X*x/2,size.Y*y/2,size.Z*z/2)))
                if point.Z <= 0 then return nil end
                minX, minY = math.min(minX,point.X), math.min(minY,point.Y)
                maxX, maxY = math.max(maxX,point.X), math.max(maxY,point.Y)
            end
        end
    end
    local viewport = camera.ViewportSize
    if maxX < 0 or maxY < 0 or minX > viewport.X or minY > viewport.Y then return nil end
    -- Clamp pathological boxes near the camera while keeping partially visible targets usable.
    minX, minY = math.max(-viewport.X,minX), math.max(-viewport.Y,minY)
    maxX, maxY = math.min(viewport.X*2,maxX), math.min(viewport.Y*2,maxY)
    return minX, minY, math.max(2,maxX-minX), math.max(2,maxY-minY)
end
local function updateBox(e, width, height, color)
    local style, t = settings.ESPBoxStyle, settings.ESPBoxThickness
    local horizontal = style == "Corners" and width * settings.ESPCornerSize or width
    local vertical = style == "Corners" and height * settings.ESPCornerSize or height
    local line = e.lines
    for _, item in ipairs(line) do item.Visible = style ~= "Off"; item.BackgroundColor3 = color; item.BackgroundTransparency = settings.ESPOverlayTransparency end
    -- Four pairs of corner strokes; in Full mode they overlap to create four edges.
    local spec = {
        {0,0,horizontal,t}, {0,0,t,vertical}, {width-horizontal,0,horizontal,t}, {width-t,0,t,vertical},
        {0,height-t,horizontal,t}, {0,height-vertical,t,vertical},
        {width-horizontal,height-t,horizontal,t}, {width-t,height-vertical,t,vertical},
    }
    for i, coords in ipairs(spec) do
        line[i].Position = UDim2.fromOffset(coords[1],coords[2])
        line[i].Size = UDim2.fromOffset(coords[3],coords[4])
    end
end
local function updateESP()
    local active = {}
    local camera = workspace.CurrentCamera
    if settings.ESP and camera and espLayer then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local anchor = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character.PrimaryPart)
                local relation = relationOf(player)
                local allowed = (relation == "Ally" and settings.ESPShowAllies) or (relation == "Enemy" and settings.ESPShowEnemies) or (relation == "Neutral" and settings.ESPShowNeutral)
                if allowed and humanoid and anchor and anchor:IsA("BasePart") and (not settings.ESPAliveOnly or humanoid.Health > 0) then
                    local distance = (anchor.Position - camera.CFrame.Position).Magnitude
                    local visible = true
                    if settings.ESPVisibleOnly then
                        local ignored = {character}
                        if localPlayer.Character then table.insert(ignored, localPlayer.Character) end
                        local ok, obstacles = pcall(function() return camera:GetPartsObscuringTarget({anchor.Position}, ignored) end)
                        visible = ok and #obstacles == 0
                    end
                    if distance <= settings.ESPMaxDistance and visible then
                        local e = espEntries[player]
                        if e and e.character ~= character then removeESP(player); e = nil end
                        e = e or makeEntry(player, character)
                        active[player] = true
                        local color = espColor(player, relation, humanoid)
                        local hl = e.highlight
                        hl.Enabled = settings.ESPHighlight ~= "Off"
                        hl.FillColor = color
                        hl.OutlineColor = settings.ESPOutlineColor == "White" and Color3.fromRGB(255,255,255) or settings.ESPOutlineColor == "Black" and Color3.fromRGB(0,0,0) or color
                        hl.FillTransparency = settings.ESPHighlight == "Outline" and 1 or settings.ESPFillTransparency
                        hl.OutlineTransparency = settings.ESPHighlight == "Fill" and 1 or settings.ESPOutlineTransparency
                        hl.DepthMode = settings.ESPDepth == "Occluded" and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                        local x,y,w,h = projectedBounds(camera, character)
                        e.overlay.Visible = x ~= nil
                        e.tracer.Visible = x ~= nil and settings.ESPTracer ~= "Off"
                        if x then
                            e.overlay.Position = UDim2.fromOffset(x,y)
                            e.overlay.Size = UDim2.fromOffset(w,h)
                            updateBox(e,w,h,color)
                            local top, bottom = {}, {}
                            if settings.ESPNames then table.insert(top, settings.ESPNameMode == "Username" and player.Name or player.DisplayName) end
                            if settings.ESPTeams then table.insert(top, "[" .. currentTeamName(player) .. "]") end
                            if settings.ESPDistance then table.insert(bottom, tostring(math.floor(distance + 0.5)) .. " studs") end
                            if settings.ESPHealth then table.insert(bottom, tostring(math.max(0, math.floor(humanoid.Health + 0.5))) .. " HP") end
                            if settings.ESPTool then
                                local tool = character:FindFirstChildOfClass("Tool")
                                if tool then table.insert(bottom, tool.Name) end
                            end
                            e.topText.Text, e.bottomText.Text = table.concat(top, "  "), table.concat(bottom, "  |  ")
                            e.topText.TextSize, e.bottomText.TextSize = settings.ESPTextSize, settings.ESPTextSize
                            e.topText.TextColor3, e.bottomText.TextColor3 = color, color
                            e.topText.TextTransparency, e.bottomText.TextTransparency = settings.ESPOverlayTransparency, settings.ESPOverlayTransparency
                            e.topText.TextStrokeTransparency, e.bottomText.TextStrokeTransparency = math.max(0.25,settings.ESPOverlayTransparency), math.max(0.25,settings.ESPOverlayTransparency)
                            e.healthBack.Visible = settings.ESPHealthBar
                            local barX = settings.ESPHealthPosition == "Right" and w + 4 or -settings.ESPHealthWidth - 4
                            e.healthBack.Position, e.healthBack.Size = UDim2.fromOffset(barX,0), UDim2.fromOffset(settings.ESPHealthWidth,h)
                            local ratio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth,0,1) or 0
                            e.healthFill.Size = UDim2.fromScale(1,ratio)
                            e.healthFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-ratio)),math.floor(230*ratio),80)
                            if e.tracer.Visible then
                                local v = camera.ViewportSize
                                local startX, startY = v.X/2, settings.ESPTracer == "Top" and 0 or settings.ESPTracer == "Center" and v.Y/2 or v.Y
                                local endX, endY = x+w/2, y+h
                                local dx,dy = endX-startX,endY-startY
                                e.tracer.Position = UDim2.fromOffset((startX+endX)/2,(startY+endY)/2)
                                e.tracer.Size = UDim2.fromOffset(math.sqrt(dx*dx+dy*dy), settings.ESPBoxThickness)
                                e.tracer.Rotation = math.deg(math.atan2(dy,dx))
                                e.tracer.BackgroundColor3 = color
                                e.tracer.BackgroundTransparency = settings.ESPOverlayTransparency
                            end
                        end
                    end
                end
            end
        end
    end
    local stale = {}
    for player in pairs(espEntries) do if not active[player] then table.insert(stale,player) end end
    for _, player in ipairs(stale) do removeESP(player) end
end

return {
    update = updateESP, clear = espClear,
    relationOf = relationOf, currentTeamName = currentTeamName,
    cleanup = function() espClear(); espLayer:Destroy() end,
}
end
