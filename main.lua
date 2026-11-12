-- Deadline Research Client: local module loader, for authorized testing only.
-- Install the folder as DeadlineTest in the executor workspace; see README.md.
local env = getgenv and getgenv() or _G
local root = env.DeadlineRoot or "DeadlineTest"
if type(root) ~= "string" or root == "" then error("DeadlineRoot must be a non-empty folder name") end
if type(readfile) ~= "function" then error("Deadline loader needs readfile; see README.md") end
if type(loadstring) ~= "function" then error("Deadline loader needs loadstring") end

local function loadModule(path)
    local fullPath = root .. "/" .. path
    local ok, source = pcall(readfile, fullPath)
    if not ok or type(source) ~= "string" then error("Cannot read " .. fullPath .. "; install the full folder in the executor workspace") end
    local chunk, compileError = loadstring(source, "@" .. fullPath)
    if not chunk then error("Cannot compile " .. fullPath .. ": " .. tostring(compileError)) end
    local loaded, result = pcall(chunk)
    if not loaded then error("Cannot load " .. fullPath .. ": " .. tostring(result)) end
    return result
end
-- Load and compile all modules before affecting an already running client.
local aimSettings = loadModule("src/aim/settings.lua")
local espSettings = loadModule("src/esp/settings.lua")
local experimentSettings = loadModule("src/experiments/settings.lua")
local makeAim = loadModule("src/aim/init.lua")
local makeESP = loadModule("src/esp/init.lua")
local makeExperiments = loadModule("src/experiments/init.lua")
local makeUI = loadModule("src/ui/menu.lua")
local settings = {}
for _, defaults in ipairs({aimSettings, espSettings, experimentSettings}) do
    assert(type(defaults) == "table", "Invalid settings module")
    for key, value in pairs(defaults) do
        assert(settings[key] == nil, "Duplicate setting: " .. tostring(key))
        settings[key] = value
    end
end
assert(type(makeAim) == "function" and type(makeESP) == "function" and type(makeExperiments) == "function" and type(makeUI) == "function", "Invalid module")
if type(env.TestClientCleanup) == "function" then pcall(env.TestClientCleanup) end
local ctx = {env = env, settings = settings, connections = {}, running = true, setStatus = function() end}
ctx.Players = game:GetService("Players")
ctx.RunService = game:GetService("RunService")
ctx.UserInputService = game:GetService("UserInputService")
ctx.localPlayer = ctx.Players.LocalPlayer
local function cleanup()
    ctx.running = false
    pcall(function() ctx.RunService:UnbindFromRenderStep("TestClientAimbot") end)
    for _, connection in ipairs(ctx.connections) do pcall(function() connection:Disconnect() end) end
    if ctx.Aim then pcall(ctx.Aim.cleanup) end
    if ctx.Experiments then pcall(ctx.Experiments.cleanup) end
    if ctx.ESP then pcall(ctx.ESP.cleanup) elseif ctx.espLayer then pcall(function() ctx.espLayer:Destroy() end) end
    if ctx.UI then pcall(ctx.UI.cleanup) elseif ctx.gui then pcall(function() ctx.gui:Destroy() end) end
    if env.TestClientCleanup == cleanup then env.TestClientCleanup = nil end
end
env.TestClientCleanup = cleanup
local ok, message = pcall(function()
    ctx.Aim = makeAim(ctx)
    ctx.Experiments = makeExperiments(ctx)
    ctx.ESP = makeESP(ctx)
    ctx.UI = makeUI(ctx)
    ctx.connections[#ctx.connections + 1] = ctx.RunService.Stepped:Connect(ctx.Experiments.step)
    ctx.RunService:BindToRenderStep("TestClientAimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
        ctx.UI.updateFOV(workspace.CurrentCamera)
        ctx.Aim.step(dt, ctx.UI.isAimActive(), ctx.UI.isMenuVisible(), ctx.UserInputService:GetFocusedTextBox() ~= nil)
    end)
    task.spawn(function()
        while ctx.running do
            ctx.ESP.update()
            ctx.UI.updateTeamChecker()
            task.wait(ctx.settings.ESPRefresh)
        end
    end)
end)
if not ok then cleanup(); error("Deadline initialization failed: " .. tostring(message)) end
print("Loaded: Right Shift menu | configure feature binds in BINDS | default aim trigger: RMB")
print("Stop: getgenv().TestClientCleanup()")
return ctx
