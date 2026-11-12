-- Independently implemented movement experiments. Test only with permission.
return function(ctx)
local player, input, settings = ctx.localPlayer, ctx.UserInputService, ctx.settings
local speedEnabled, jumpEnabled = false, false
local modifiedHumanoid, originalSpeed, lastSet = nil, nil, nil
local lastJump = -math.huge

local function restoreSpeed()
    if modifiedHumanoid then
        -- Avoid overwriting an intervening game change when the value no longer matches ours.
        pcall(function()
            if modifiedHumanoid.Parent and modifiedHumanoid.WalkSpeed == lastSet then
                modifiedHumanoid.WalkSpeed = originalSpeed
            end
        end)
    end
    modifiedHumanoid, originalSpeed, lastSet = nil, nil, nil
end
local function characterParts()
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return end
    return humanoid, root
end
local function step(dt)
    if not ctx.running or not speedEnabled then return end
    local humanoid, root = characterParts()
    if not humanoid then restoreSpeed(); return end
    if modifiedHumanoid and (modifiedHumanoid ~= humanoid or settings.MovementMode ~= "WalkSpeed") then
        restoreSpeed()
    end
    if settings.MovementMode == "WalkSpeed" then
        if not modifiedHumanoid then modifiedHumanoid, originalSpeed = humanoid, humanoid.WalkSpeed end
        humanoid.WalkSpeed = settings.MovementSpeed
        lastSet = settings.MovementSpeed
    elseif settings.MovementMode == "CFrame" then
        -- Additional horizontal displacement per second, on top of normal movement.
        root.CFrame = root.CFrame + humanoid.MoveDirection * (settings.MovementSpeed * math.clamp(dt, 0, 0.1))
    elseif settings.MovementMode == "Velocity" then
        -- Set horizontal velocity only when movement is requested; preserve vertical motion.
        local direction, velocity = humanoid.MoveDirection, root.AssemblyLinearVelocity
        if direction.Magnitude > 0.01 then
            root.AssemblyLinearVelocity = Vector3.new(direction.X * settings.MovementSpeed, velocity.Y, direction.Z * settings.MovementSpeed)
        end
    end
end
local function toggleSpeed()
    speedEnabled = not speedEnabled
    if not speedEnabled then restoreSpeed() end
    ctx.setStatus("Speed experiment " .. (speedEnabled and "enabled" or "disabled"))
end
local function toggleJump()
    jumpEnabled = not jumpEnabled
    lastJump = -math.huge
    ctx.setStatus("Air jump experiment " .. (jumpEnabled and "enabled" or "disabled"))
end
local function onJump()
    if not ctx.running or not jumpEnabled or (ctx.UI and ctx.UI.isMenuVisible()) or input:GetFocusedTextBox() then return end
    local now = os.clock()
    if now - lastJump < 0.15 then return end
    local humanoid, root = characterParts()
    if not humanoid then return end
    lastJump = now
    if settings.AirJumpMode == "State" then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    else
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, settings.AirJumpVelocity, velocity.Z)
    end
end
ctx.connections[#ctx.connections + 1] = input.JumpRequest:Connect(onJump)
local function reset()
    speedEnabled, jumpEnabled = false, false
    lastJump = -math.huge
    restoreSpeed()
end
return {
    step = step, toggleSpeed = toggleSpeed, toggleJump = toggleJump,
    isSpeed = function() return speedEnabled end, isJump = function() return jumpEnabled end,
    modeChanged = restoreSpeed,
    respawn = function() reset(); ctx.setStatus("Movement experiments reset on respawn.") end,
    cleanup = reset,
}
end
