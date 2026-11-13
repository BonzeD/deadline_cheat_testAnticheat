-- Deadline Research Client: local module loader, for authorized testing only.
-- Local files by default; the HTTP bootstrap passes a module base URL.
local moduleBase = ...
if moduleBase ~= nil and type(moduleBase) ~= "string" then error("Invalid module base") end
local env = getgenv and getgenv() or _G
local root = env.DeadlineRoot or "DeadlineTest"
if type(root) ~= "string" or root == "" then error("DeadlineRoot must be a non-empty folder name") end
if not moduleBase and type(readfile) ~= "function" then error("Deadline local loader needs readfile; see README.md") end
if type(loadstring) ~= "function" then error("Deadline loader needs loadstring") end

local function loadModule(path)
    local fullPath = moduleBase and (moduleBase .. path) or (root .. "/" .. path)
    local ok, source
    if moduleBase then
        ok, source = pcall(function() return game:HttpGet(fullPath) end)
    else
        ok, source = pcall(readfile, fullPath)
    end
    if not ok or type(source) ~= "string" or source == "" then error("Cannot read " .. fullPath .. "; check connection or local installation") end
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
local movementSettings = loadModule("src/movement/settings.lua")
local bypassSettings = loadModule("src/bypass/settings.lua")
local triggerSettings = loadModule("src/trigger/settings.lua")
local visualSettings = loadModule("src/visuals/settings.lua")
local mobilitySettings = loadModule("src/mobility/settings.lua")
local makeAim = loadModule("src/aim/init.lua")
local makeESP = loadModule("src/esp/init.lua")
local makeSkeleton = loadModule("src/esp/skeleton.lua")
local makeExperiments = loadModule("src/experiments/init.lua")
local makeMovement = loadModule("src/movement/init.lua")
local makeBypass = loadModule("src/bypass/init.lua")
local makeTrigger = loadModule("src/trigger/init.lua")
local makeVisuals = loadModule("src/visuals/init.lua")
local makeMobility = loadModule("src/mobility/init.lua")
local makeUI = loadModule("src/ui/menu.lua")
local translate = loadModule("src/ui/i18n.lua")
local makeCursor = loadModule("src/ui/cursor.lua")
local makeConfig = loadModule("src/config/init.lua")
local makeBindings = loadModule("src/ui/bindings.lua")
local settings = {Language = "English"}
for _, defaults in ipairs({aimSettings, espSettings, experimentSettings, movementSettings, bypassSettings, triggerSettings, visualSettings, mobilitySettings}) do
    assert(type(defaults) == "table", "Invalid settings module")
    for key, value in pairs(defaults) do
        assert(settings[key] == nil, "Duplicate setting: " .. tostring(key))
        settings[key] = value
    end
end
assert(type(makeAim) == "function" and type(makeESP) == "function" and type(makeExperiments) == "function" and type(makeMovement) == "function" and type(makeBypass) == "function" and type(makeTrigger) == "function" and type(makeVisuals) == "function" and type(makeMobility) == "function" and type(makeUI) == "function" and type(makeCursor) == "function" and type(makeConfig) == "function" and type(makeBindings) == "function", "Invalid module")
if type(env.TestClientCleanup) == "function" then pcall(env.TestClientCleanup) end
local ctx = {env = env, settings = settings, connections = {}, running = true, makeBindings = makeBindings, makeSkeleton = makeSkeleton, translate = translate, setStatus = function() end}
ctx.Players = game:GetService("Players")
ctx.RunService = game:GetService("RunService")
ctx.UserInputService = game:GetService("UserInputService")
ctx.localPlayer = ctx.Players.LocalPlayer
local function cleanup()
    ctx.running = false
    pcall(function() ctx.RunService:UnbindFromRenderStep("TestClientAimbot") end)
    for _, connection in ipairs(ctx.connections) do pcall(function() connection:Disconnect() end) end
    if ctx.Bindings then pcall(ctx.Bindings.releaseAll) end
    if ctx.Aim then pcall(ctx.Aim.cleanup) end
    if ctx.Experiments then pcall(ctx.Experiments.cleanup) end
    if ctx.Movement then pcall(ctx.Movement.cleanup) end
    if ctx.Bypass then pcall(ctx.Bypass.cleanup) end
    if ctx.Trigger then pcall(ctx.Trigger.cleanup) end
    if ctx.Visuals then pcall(ctx.Visuals.cleanup) end
    if ctx.Mobility then pcall(ctx.Mobility.cleanup) end
    if ctx.ESP then pcall(ctx.ESP.cleanup) elseif ctx.espLayer then pcall(function() ctx.espLayer:Destroy() end) end
    if ctx.Cursor then pcall(ctx.Cursor.cleanup) end
    if ctx.UI then pcall(ctx.UI.cleanup) elseif ctx.gui then pcall(function() ctx.gui:Destroy() end) end
    if env.TestClientCleanup == cleanup then env.TestClientCleanup = nil end
end
env.TestClientCleanup = cleanup
local ok, message = pcall(function()
    ctx.Aim = makeAim(ctx)
    ctx.Experiments = makeExperiments(ctx)
    ctx.Movement = makeMovement(ctx)
    ctx.Bypass = makeBypass(ctx)
    ctx.Trigger = makeTrigger(ctx)
    ctx.Visuals = makeVisuals(ctx)
    ctx.Mobility = makeMobility(ctx)
    ctx.ESP = makeESP(ctx)
    ctx.Cursor = makeCursor(ctx)
    ctx.Config = makeConfig(ctx, root)
    ctx.UI = makeUI(ctx)
    ctx.connections[#ctx.connections + 1] = ctx.RunService.Stepped:Connect(ctx.Experiments.step)
    ctx.connections[#ctx.connections + 1] = ctx.RunService.Heartbeat:Connect(ctx.Movement.step)
    ctx.connections[#ctx.connections + 1] = ctx.RunService.Heartbeat:Connect(function() ctx.Mobility.step(os.clock()) end)
    ctx.RunService:BindToRenderStep("TestClientAimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
        ctx.Cursor.step()
        ctx.UI.updateHeld()
        ctx.Visuals.step(dt, workspace.CurrentCamera)
        ctx.UI.updateFOV(workspace.CurrentCamera)
        ctx.Aim.step(dt, ctx.UI.isAimActive(), ctx.UI.isMenuVisible(), ctx.UserInputService:GetFocusedTextBox() ~= nil)
        ctx.ESP.render(workspace.CurrentCamera, dt)
        ctx.Trigger.step(os.clock(), ctx.UI.isMenuVisible(), ctx.UserInputService:GetFocusedTextBox() ~= nil, ctx.UI.isAimActive(), ctx.UI.isWindowFocused())
    end)
    task.spawn(function()
        local espFailed, uiFailed = false, false
        while ctx.running do
            local espOk, espErr = pcall(ctx.ESP.update)
            if not espOk and not espFailed then warn("Deadline ESP scan: " .. tostring(espErr)) end
            espFailed = not espOk
            local uiOk, uiErr = pcall(ctx.UI.updateTeamChecker)
            if not uiOk and not uiFailed then warn("Deadline team checker: " .. tostring(uiErr)) end
            uiFailed = not uiOk
            task.wait(ctx.settings.ESPRefresh)
        end
    end)
end)
if not ok then cleanup(); error("Deadline initialization failed: " .. tostring(message)) end
print("Loaded: Right Shift menu | configure feature binds in BINDS | default aim trigger: RMB")
print("Stop: getgenv().TestClientCleanup()")
return ctx
