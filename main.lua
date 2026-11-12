-- Test client: ESP and camera aimbot
-- Test only in places you own or are authorized to test.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or _G

if type(env.TestClientCleanup) == "function" then
    pcall(env.TestClientCleanup)
end

local settings = {
    ESP = true,
    Aimbot = true,
    TeamCheck = true,
    AimRadius = 180,
    Smoothness = 0.25,
}

local running = true
local highlights = {}
local connections = {}

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
    local bestHead = nil
    local bestDistance = settings.AimRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if isTarget(player) then
            local head = player.Character:FindFirstChild("Head")
            local point, visible = camera:WorldToViewportPoint(head.Position)
            if visible and point.Z > 0 then
                local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    bestHead = head
                end
            end
        end
    end
    return bestHead
end

connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        settings.ESP = not settings.ESP
        updateESP()
        print("ESP:", settings.ESP)
    elseif input.KeyCode == Enum.KeyCode.F7 then
        settings.Aimbot = not settings.Aimbot
        print("Aimbot:", settings.Aimbot)
    end
end)

RunService:BindToRenderStep("TestClientAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if not running or not settings.Aimbot then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local head = findTarget(camera)
    if head then
        local current = camera.CFrame
        local target = CFrame.lookAt(current.Position, head.Position)
        camera.CFrame = current:Lerp(target, settings.Smoothness)
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
    RunService:UnbindFromRenderStep("TestClientAimbot")
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, highlight in pairs(highlights) do highlight:Destroy() end
    env.TestClientCleanup = nil
    print("Test client stopped")
end

print("Loaded: F6 = ESP, F7 = aimbot, hold right mouse to aim")
print("Stop: getgenv().TestClientCleanup()")
