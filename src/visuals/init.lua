-- Visual-only local overlay and reversible camera/lighting changes.
return function(ctx)
local s, player = ctx.settings, ctx.localPlayer
local lighting = game:GetService("Lighting")
local gui = Instance.new("ScreenGui")
gui.Name="DeadlineCrosshair"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=5
gui.Parent=player:WaitForChild("PlayerGui")
local cross = Instance.new("Frame")
cross.Name="Crosshair"; cross.BackgroundTransparency=1; cross.BorderSizePixel=0
cross.AnchorPoint=Vector2.new(0.5,0.5); cross.Position=UDim2.fromScale(0.5,0.5)
cross.Size=UDim2.fromOffset(1,1); cross.Visible=false; cross.Parent=gui
local lines = {}
for i=1,5 do
    local part=Instance.new("Frame");part.Name="Line"..i;part.BorderSizePixel=0;part.AnchorPoint=Vector2.new(0.5,0.5)
    part.Parent=cross; lines[i]=part
end
local properties={}
local function restore(key)
    local record=properties[key]
    if not record then return end
    pcall(function() if record.object[record.property] == record.last then record.object[record.property] = record.original end end)
    properties[key]=nil
end
local function apply(key, object, property, value)
    local record=properties[key]
    if record and record.object ~= object then restore(key); record=nil end
    if not record then
        record={object=object,property=property,original=object[property]};properties[key]=record
    elseif object[property] ~= record.last then
        record.original=object[property] -- preserve intervening game updates when possible
    end
    object[property]=value;record.last=value
end
local angle=0
local function step(dt, camera)
    local n,g,t=s.CrosshairLength,s.CrosshairGap,s.CrosshairThickness
    cross.Visible=s.CrosshairEnabled
    if s.CrosshairEnabled then
        local color=Color3.fromHSV((s.CrosshairHue%360)/360,0.85,1)
        angle=s.CrosshairSpin and (angle+math.clamp(dt,0,0.1)*s.CrosshairSpinSpeed)%360 or 0
        cross.Rotation=0
        local radians=math.rad(angle); local cosine,sine=math.cos(radians),math.sin(radians)
        local coords={{-(g+n/2),0,n,t},{g+n/2,0,n,t},{0,-(g+n/2),t,n},{0,g+n/2,t,n},{0,0,t*2,t*2}}
        for i,p in ipairs(lines) do
            local a=coords[i]; p.Position=UDim2.fromOffset(a[1]*cosine-a[2]*sine,a[1]*sine+a[2]*cosine)
            p.Size=UDim2.fromOffset(a[3],a[4]);p.Rotation=angle
            p.Visible=(i<5 and s.CrosshairShape~="Dot") or (i==5 and s.CrosshairShape~="Cross")
            p.BackgroundColor3=color;p.BackgroundTransparency=s.CrosshairTransparency
        end
    end
    if s.FullbrightEnabled then
        apply("Ambient",lighting,"Ambient",Color3.fromRGB(180,180,180))
        apply("OutdoorAmbient",lighting,"OutdoorAmbient",Color3.fromRGB(180,180,180))
        apply("Brightness",lighting,"Brightness",s.FullbrightLevel)
    else restore("Ambient");restore("OutdoorAmbient");restore("Brightness") end
    if s.NoFogEnabled then apply("FogEnd",lighting,"FogEnd",1000000) else restore("FogEnd") end
    if s.CameraFOVEnabled and camera then apply("FOV",camera,"FieldOfView",s.CameraFOVAmount) else restore("FOV") end
end
local function toggle(key,label)
    s[key]=not s[key];ctx.setStatus(label .. (s[key] and " on" or " off"))
end
local function cleanup()
    for _, key in ipairs({"Ambient","OutdoorAmbient","Brightness","FogEnd","FOV"}) do restore(key) end
    s.CrosshairEnabled=false;s.FullbrightEnabled=false;s.NoFogEnabled=false;s.CameraFOVEnabled=false
    gui:Destroy()
end
return {step=step, cleanup=cleanup, toggle=function(key,label) toggle(key,label) end}
end
